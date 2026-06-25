import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:island_diary/core/state/user_state.dart';

class CameraImageProcessor {
  /// 加载图片字节数据为 ui.Image
  static Future<ui.Image> _loadUiImage(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  /// 创建像素化小图（用于像素马赛克效果）
  static Future<ui.Image> _createPixelatedImage(ui.Image src, double srcX, double srcY, double srcW, double srcH, double scale) async {
    final recorder = ui.PictureRecorder();
    final double smallW = (srcW * scale).clamp(1.0, srcW);
    final double smallH = (srcH * scale).clamp(1.0, srcH);
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, smallW, smallH));
    
    canvas.drawImageRect(
      src,
      Rect.fromLTWH(srcX, srcY, srcW, srcH),
      Rect.fromLTWH(0, 0, smallW, smallH),
      Paint(),
    );
    final picture = recorder.endRecording();
    return await picture.toImage(smallW.toInt(), smallH.toInt());
  }

  /// 处理单张拍摄的照片：进行画幅裁剪、添加水印、色温滤镜、马赛克、色彩矩阵调节
  /// [imagePath] 原始图片路径
  /// [ratio] 目标比例 ('1:1', '4:3', '16:9')
  /// [watermarkStyle] 水印样式 ('none', 'film', 'simple_date', 'device_inner', 'polaroid')
  static Future<String> processSingleImage({
    required String imagePath,
    required String ratio,
    required String watermarkStyle,
    String filterName = 'auto',
    String mosaicMode = 'none',
    List<double>? colorMatrix,
    double strokeWidth = 0.0,
    Color strokeColor = Colors.white,
    String strokeStyle = 'solid',
  }) async {
    final file = io.File(imagePath);
    if (!await file.exists()) {
      throw Exception('照片文件不存在');
    }

    final bytes = await file.readAsBytes();
    final uiImage = await _loadUiImage(bytes);

    final int srcW = uiImage.width;
    final int srcH = uiImage.height;

    // 1. 计算裁剪尺寸与坐标
    double targetRatio = 1.0;
    if (ratio == '4:3') {
      targetRatio = 4 / 3;
    } else if (ratio == '16:9') {
      targetRatio = 16 / 9;
    }

    double dstW = srcW.toDouble();
    double dstH = srcH.toDouble();
    double offsetX = 0.0;
    double offsetY = 0.0;

    // 因为通常拍照是竖屏，宽 < 高，所以按竖屏比例计算，但也要兼顾横屏
    if (srcW < srcH) {
      // 竖屏拍照：目标比例应该倒数，例如 1:1, 3:4, 9:16
      double verticalRatio = 1 / targetRatio;
      if (srcW / srcH > verticalRatio) {
        // 宽度相对过剩，以高度为基准裁剪宽度
        dstW = srcH * verticalRatio;
        offsetX = (srcW - dstW) / 2;
      } else {
        // 高度相对过剩，以宽度为基准裁剪高度
        dstH = srcW / verticalRatio;
        offsetY = (srcH - dstH) / 2;
      }
    } else {
      // 横屏拍照
      if (srcW / srcH > targetRatio) {
        dstW = srcH * targetRatio;
        offsetX = (srcW - dstW) / 2;
      } else {
        dstH = srcW / targetRatio;
        offsetY = (srcH - dstH) / 2;
      }
    }

    // 计算拍立得留白或画框边框高度
    final bool isPolaroid = watermarkStyle == 'polaroid';
    final bool isBlurBorder = watermarkStyle == 'blur_border';
    final double extraHeight = isPolaroid
        ? dstH * 0.12
        : (isBlurBorder ? dstH * 0.15 : 0.0);

    // 2. 使用 PictureRecorder 进行图形渲染
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, dstW, dstH + extraHeight));

    final srcRect = Rect.fromLTWH(offsetX, offsetY, dstW, dstH);
    final dstRect = Rect.fromLTWH(0, 0, dstW, dstH);

    double margin = dstW * 0.06;
    double scale = (dstW - margin * 2) / dstW;
    final fgRect = isBlurBorder
        ? Rect.fromLTWH(margin, margin, dstW - margin * 2, dstH * scale)
        : dstRect;

    if (isPolaroid) {
      // 绘制白色拍立得背景相纸色
      final paintBg = Paint()..color = const Color(0xFFFDFBF7);
      canvas.drawRect(Rect.fromLTWH(0, 0, dstW, dstH + extraHeight), paintBg);
    } else if (isBlurBorder) {
      // 绘制原图高斯模糊背景
      final paintBlurBg = Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0)
        ..filterQuality = ui.FilterQuality.high;
      canvas.drawImageRect(uiImage, srcRect, Rect.fromLTWH(0, 0, dstW, dstH + extraHeight), paintBlurBg);
      // 稍微暗化背景以突出前景
      canvas.drawRect(
        Rect.fromLTWH(0, 0, dstW, dstH + extraHeight),
        Paint()..color = Colors.black.withValues(alpha: 0.15),
      );
    }

    final paintImg = Paint();
    if (colorMatrix != null) {
      paintImg.colorFilter = ui.ColorFilter.matrix(colorMatrix);
    }

    // 绘制被裁剪的图片部分，支持马赛克效果与色彩矩阵
    if (mosaicMode == 'pixel') {
      final smallImage = await _createPixelatedImage(uiImage, offsetX, offsetY, dstW, dstH, 0.025);
      canvas.drawImageRect(
        smallImage,
        Rect.fromLTWH(0, 0, smallImage.width.toDouble(), smallImage.height.toDouble()),
        fgRect,
        paintImg..filterQuality = ui.FilterQuality.none,
      );
      smallImage.dispose();
    } else if (mosaicMode == 'blur') {
      paintImg.imageFilter = ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0);
      canvas.drawImageRect(uiImage, srcRect, fgRect, paintImg);
    } else {
      if (strokeWidth > 0) {
        if (strokeStyle == 'solid') {
          final strokePaint = Paint()
            ..colorFilter = ui.ColorFilter.mode(strokeColor, BlendMode.srcIn);

          final double step = strokeWidth;
          final offsets = [
            Offset(-step, 0),
            Offset(step, 0),
            Offset(0, -step),
            Offset(0, step),
            Offset(-step, -step),
            Offset(-step, step),
            Offset(step, -step),
            Offset(step, step),
          ];

          for (final offset in offsets) {
            canvas.save();
            canvas.translate(offset.dx, offset.dy);
            canvas.drawImageRect(uiImage, srcRect, fgRect, strokePaint);
            canvas.restore();
          }
        } else if (strokeStyle == 'glow') {
          canvas.saveLayer(fgRect, Paint());
          final glowPaint = Paint()
            ..colorFilter = ui.ColorFilter.mode(strokeColor, BlendMode.srcIn)
            ..imageFilter = ui.ImageFilter.blur(sigmaX: strokeWidth, sigmaY: strokeWidth);
          canvas.drawImageRect(uiImage, srcRect, fgRect, glowPaint);
          canvas.restore();
        } else if (strokeStyle == 'stars') {
          canvas.saveLayer(fgRect, Paint());

          // 1. 绘制描边底作为遮罩
          final maskPaint = Paint()
            ..colorFilter = ui.ColorFilter.mode(strokeColor, BlendMode.srcIn);
          
          final double step = strokeWidth;
          final offsets = [
            Offset(-step, 0),
            Offset(step, 0),
            Offset(0, -step),
            Offset(0, step),
            Offset(-step, -step),
            Offset(-step, step),
            Offset(step, -step),
            Offset(step, step),
          ];

          for (final offset in offsets) {
            canvas.save();
            canvas.translate(offset.dx, offset.dy);
            canvas.drawImageRect(uiImage, srcRect, fgRect, maskPaint);
            canvas.restore();
          }

          // 2. 剪切：仅在遮罩不透明的区域绘制小星星
          final starPaint = Paint()
            ..color = Colors.white
            ..blendMode = BlendMode.srcIn;

          // 3. 绘制确定性伪随机星星（网格法）
          const double gridStep = 18.0;
          final int cols = (fgRect.width / gridStep).ceil();
          final int rows = (fgRect.height / gridStep).ceil();

          for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
              final double x = fgRect.left + c * gridStep;
              final double y = fgRect.top + r * gridStep;
              
              final double hash = (math.sin(x * 12.9898 + y * 78.233) * 43758.5453).abs() % 1.0;
              if (hash < 0.22) {
                final double dx = (hash * 100) % gridStep;
                final double dy = ((hash * 1000) % gridStep);
                
                final double px = x + dx;
                final double py = y + dy;

                final double scaleFactor = fgRect.width / 360.0;
                final double starSize = (4.0 + (hash * 4.0)) * scaleFactor.clamp(1.0, 5.0);
                
                canvas.save();
                canvas.translate(px, py);
                canvas.rotate(hash * 2.0 * math.pi);
                
                final Path path = Path();
                final double rx = starSize / 2;
                final double ry = starSize / 2;
                path.moveTo(0, -ry);
                path.quadraticBezierTo(0, 0, rx, 0);
                path.quadraticBezierTo(0, 0, 0, ry);
                path.quadraticBezierTo(0, 0, -rx, 0);
                path.quadraticBezierTo(0, 0, 0, -ry);
                path.close();
                
                canvas.drawPath(path, starPaint);
                canvas.restore();
              }
            }
          }

          canvas.restore();
        }
      }
      canvas.drawImageRect(uiImage, srcRect, fgRect, paintImg);
    }

    // 绘制色温滤镜
    _applyFilter(canvas, fgRect, filterName);

    // 3. 绘制精致多样式水印
    _drawStyledWatermark(canvas, dstW, dstH, watermarkStyle, extraHeight);

    // 4. 输出并保存文件
    final picture = recorder.endRecording();
    final processedImage = await picture.toImage(dstW.toInt(), (dstH + extraHeight).toInt());
    final byteData = await processedImage.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('图片处理转换失败');
    }

    final processedBytes = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final String newPath = '${tempDir.path}/diary_cam_${DateTime.now().millisecondsSinceEpoch}.png';
    await io.File(newPath).writeAsBytes(processedBytes);

    // 释放资源
    uiImage.dispose();
    processedImage.dispose();

    return newPath;
  }

  /// 绘制多种风格的水印
  static void _drawStyledWatermark(
    Canvas canvas,
    double width,
    double height,
    String style,
    double extraHeight,
  ) {
    if (style == 'none') return;

    final now = DateTime.now();
    final String year = now.year.toString();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');

    if (style == 'film') {
      // 1. 复古胶片发光橙红水印 (原来的)
      final String yearShort = year.substring(2);
      final String text = "$yearShort $month $day  $hour:$minute";
      final double fontSize = (width * 0.038).clamp(16.0, 42.0);

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: fontSize,
            color: const Color(0xFFFF6E40),
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            shadows: [
              Shadow(
                color: const Color(0xFFFF3D00).withValues(alpha: 0.5),
                blurRadius: 4,
                offset: Offset.zero,
              ),
              Shadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double posX = width - textPainter.width - fontSize * 1.5;
      final double posY = height - textPainter.height - fontSize * 1.5;
      textPainter.paint(canvas, Offset(posX, posY));

    } else if (style == 'simple_date') {
      // 2. 极简日期：左下角纯白简约细字
      final String text = "$year-$month-$day $hour:$minute";
      final double fontSize = (width * 0.032).clamp(12.0, 32.0);

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: fontSize,
            color: Colors.white.withValues(alpha: 0.85),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double posX = fontSize * 1.5;
      final double posY = height - textPainter.height - fontSize * 1.5;
      textPainter.paint(canvas, Offset(posX, posY));

    } else if (style == 'device_inner') {
      // 3. 相机内嵌机型 (直接叠在图片下方，白色精致排版)
      final double fontSizeMain = (width * 0.035).clamp(14.0, 36.0);
      final double fontSizeSub = (width * 0.024).clamp(10.0, 24.0);

      final String userName = UserState().userName.value.isEmpty ? "我" : UserState().userName.value;
      final String mainText = "岛屿日记 x $userName";
      final String subText = "50mm F/1.8  1/125s  ISO 100  •  $year/$month/$day $hour:$minute";

      final mainPainter = TextPainter(
        text: TextSpan(
          text: mainText,
          style: TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: fontSizeMain,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.45), offset: const Offset(1, 1), blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final subPainter = TextPainter(
        text: TextSpan(
          text: subText,
          style: TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: fontSizeSub,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 1.0,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.45), offset: const Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double startX = fontSizeMain * 1.2;
      final double posY2 = height - subPainter.height - fontSizeMain * 1.2;
      final double posY1 = posY2 - mainPainter.height - 4;

      mainPainter.paint(canvas, Offset(startX, posY1));
      subPainter.paint(canvas, Offset(startX, posY2));

    } else if (style == 'polaroid') {
      // 4. 拍立得留白边框水印 (利用新增的 extraHeight 绘制底边)
      if (extraHeight <= 0) return;

      final double posY = height; // 白边起点
      final double textCenterY = posY + extraHeight / 2;

      // 拍立得左侧：品牌 / 设备信息 (使用优雅的手写风)
      final brandPainter = TextPainter(
        text: const TextSpan(
          text: "Island Diary ╳ Instant",
          style: TextStyle(
            fontFamily: 'WanWeiWei',
            fontSize: 26.0,
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // 拍立得右侧：参数与时间 (小细字排版)
      final String paramText = "50mm F/2.0 1/250s ISO100  |  $year.$month.$day";
      final paramPainter = TextPainter(
        text: TextSpan(
          text: paramText,
          style: const TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: 15.0,
            color: Color(0xFFA68565),
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double brandX = 24.0;
      final double brandY = textCenterY - brandPainter.height / 2;
      brandPainter.paint(canvas, Offset(brandX, brandY));

      final double paramX = width - paramPainter.width - 24.0;
      final double paramY = textCenterY - paramPainter.height / 2;
      paramPainter.paint(canvas, Offset(paramX, paramY));
    } else if (style == 'blur_border') {
      // 5. 模糊相框中心下方的居中参数水印
      final double margin = width * 0.06;
      final double scale = (width - margin * 2) / width;
      final double fgHeight = height * scale;
      final double bottomAreaTop = margin + fgHeight;
      final double bottomAreaHeight = (height + extraHeight) - bottomAreaTop;
      final double centerY = bottomAreaTop + bottomAreaHeight / 2;

      final double fontSizeMain = (width * 0.038).clamp(16.0, 42.0);
      final double fontSizeSub = (width * 0.026).clamp(12.0, 28.0);

      final String userName = UserState().userName.value.isEmpty ? "我" : UserState().userName.value;
      final String mainText = "岛屿日记 x $userName";
      final String subText = "50mm F/1.8  1/125s  ISO 100  •  $year/$month/$day $hour:$minute";

      final mainPainter = TextPainter(
        text: TextSpan(
          text: mainText,
          style: TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: fontSizeMain,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.5), offset: const Offset(1, 1), blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final subPainter = TextPainter(
        text: TextSpan(
          text: subText,
          style: TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: fontSizeSub,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 1.2,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double mainX = (width - mainPainter.width) / 2;
      final double subX = (width - subPainter.width) / 2;

      final double totalTextHeight = mainPainter.height + subPainter.height + 6;
      final double startY = centerY - totalTextHeight / 2;

      mainPainter.paint(canvas, Offset(mainX, startY));
      subPainter.paint(canvas, Offset(subX, startY + mainPainter.height + 6));
    }
  }

  /// 处理多连拍拼接（手账排版/四格拼图/双格拼图）
  /// [imagePaths] 照片路径列表
  /// [watermarkStyle] 水印样式
  static Future<String> processCollage({
    required List<String> imagePaths,
    required String watermarkStyle,
    String filterName = 'auto',
    String mosaicMode = 'none',
    List<double>? colorMatrix,
  }) async {
    if (imagePaths.isEmpty) {
      throw Exception('照片列表不能为空');
    }

    final List<ui.Image> loadedImages = [];
    for (var path in imagePaths) {
      final file = io.File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        loadedImages.add(await _loadUiImage(bytes));
      }
    }

    if (loadedImages.isEmpty) {
      throw Exception('未加载到有效的照片文件');
    }

    // 设定拼图画板的基础尺寸 (例如宽度固定为 1200，高度自适应)
    const double canvasW = 1200.0;
    double canvasH = 1200.0;

    // 白边间距设计 (Polaroid 经典相纸白边)
    const double outerPadding = 50.0;
    const double innerGap = 30.0;
    double bottomSpacing = watermarkStyle != 'none' ? 160.0 : 50.0; // 如果无水印，则压缩底部空白

    final recorder = ui.PictureRecorder();
    Canvas? canvas;

    if (loadedImages.length == 2) {
      // 双格垂直拼图
      // 每个图高度比例设为 4:3
      final double itemW = canvasW - outerPadding * 2;
      final double itemH = itemW * (3 / 4);
      canvasH = outerPadding * 2 + itemH * 2 + innerGap + bottomSpacing;
      
      canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasW, canvasH));
      
      // 绘制白色大背景
      final paintBg = Paint()..color = const Color(0xFFFDFBF7);
      canvas.drawRect(Rect.fromLTWH(0, 0, canvasW, canvasH), paintBg);

      for (int i = 0; i < 2; i++) {
        final img = loadedImages[i];
        final double top = outerPadding + i * (itemH + innerGap);
        await _drawCroppedItem(canvas, img, Rect.fromLTWH(outerPadding, top, itemW, itemH), filterName, mosaicMode, colorMatrix);
      }

    } else {
      // 四格拼图 (2x2)
      final double itemW = (canvasW - outerPadding * 2 - innerGap) / 2;
      final double itemH = itemW; // 四格拼图每个采用 1:1 正方形
      canvasH = outerPadding * 2 + itemH * 2 + innerGap + bottomSpacing;

      canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasW, canvasH));

      // 绘制白色大背景
      final paintBg = Paint()..color = const Color(0xFFFDFBF7);
      canvas.drawRect(Rect.fromLTWH(0, 0, canvasW, canvasH), paintBg);

      for (int i = 0; i < loadedImages.length.clamp(1, 4); i++) {
        final img = loadedImages[i];
        final int row = i ~/ 2;
        final int col = i % 2;
        final double left = outerPadding + col * (itemW + innerGap);
        final double top = outerPadding + row * (itemH + innerGap);
        await _drawCroppedItem(canvas, img, Rect.fromLTWH(left, top, itemW, itemH), filterName, mosaicMode, colorMatrix);
      }
    }

    if (watermarkStyle != 'none') {
      // 绘制手账风格装饰线与时间标签
      final paintLine = Paint()
        ..color = const Color(0xFFD4A373).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      // 底部横线
      canvas.drawLine(
        Offset(outerPadding, canvasH - bottomSpacing + 20),
        Offset(canvasW - outerPadding, canvasH - bottomSpacing + 20),
        paintLine,
      );

      // 绘制底部拍立得式手写时间文字
      final now = DateTime.now();
      final String formattedDate = watermarkStyle == 'polaroid'
          ? '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}'
          : '${now.year}年${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日';
      final String dateText = '📅 $formattedDate  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      String subText = '⭐ 慢下来的时光 / 岛屿日记记录';
      if (watermarkStyle == 'device_inner') {
        subText = 'ISLAND DIARY ╳ CAMERA';
      } else if (watermarkStyle == 'polaroid') {
        subText = 'Island Diary ╳ Instant';
      }

      final timePainter = TextPainter(
        text: TextSpan(
          text: dateText,
          style: const TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: 34.0,
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final subPainter = TextPainter(
        text: TextSpan(
          text: subText,
          style: const TextStyle(
            fontFamily: 'WanWeiWei', // 手写字体
            fontSize: 36.0,
            color: Color(0xFFA68565),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      timePainter.paint(canvas, Offset(outerPadding + 10, canvasH - bottomSpacing + 45));
      subPainter.paint(canvas, Offset(canvasW - subPainter.width - outerPadding - 10, canvasH - bottomSpacing + 45));
    }

    // 输出并保存文件
    final picture = recorder.endRecording();
    final processedImage = await picture.toImage(canvasW.toInt(), canvasH.toInt());
    final byteData = await processedImage.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('拼图处理转换失败');
    }

    // 释放加载的所有原始图片
    for (var img in loadedImages) {
      img.dispose();
    }
    processedImage.dispose();

    final processedBytes = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final String newPath = '${tempDir.path}/diary_collage_${DateTime.now().millisecondsSinceEpoch}.png';
    await io.File(newPath).writeAsBytes(processedBytes);

    return newPath;
  }

  /// 内部辅助：将一张原图等比例裁剪并填充到拼图对应的矩形格子中并应用滤镜与马赛克
  static Future<void> _drawCroppedItem(
    Canvas canvas,
    ui.Image img,
    Rect rect,
    String filterName,
    String mosaicMode,
    List<double>? colorMatrix,
  ) async {
    final double dstW = rect.width;
    final double dstH = rect.height;
    final double srcW = img.width.toDouble();
    final double srcH = img.height.toDouble();

    double cropW = srcW;
    double cropH = srcH;
    double offsetX = 0.0;
    double offsetY = 0.0;

    final double dstRatio = dstW / dstH;
    final double srcRatio = srcW / srcH;

    if (srcRatio > dstRatio) {
      cropW = srcH * dstRatio;
      offsetX = (srcW - cropW) / 2;
    } else {
      cropH = srcW / dstRatio;
      offsetY = (srcH - cropH) / 2;
    }

    final srcRect = Rect.fromLTWH(offsetX, offsetY, cropW, cropH);

    // 绘制被裁剪的图片部分
    if (mosaicMode == 'pixel') {
      final smallImage = await _createPixelatedImage(img, offsetX, offsetY, cropW, cropH, 0.025);
      final paint = Paint()..filterQuality = ui.FilterQuality.none;
      if (colorMatrix != null) {
        paint.colorFilter = ui.ColorFilter.matrix(colorMatrix);
      }
      canvas.drawImageRect(
        smallImage,
        Rect.fromLTWH(0, 0, smallImage.width.toDouble(), smallImage.height.toDouble()),
        rect,
        paint,
      );
      smallImage.dispose();
    } else if (mosaicMode == 'blur') {
      final paintBlur = Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0);
      if (colorMatrix != null) {
        paintBlur.colorFilter = ui.ColorFilter.matrix(colorMatrix);
      }
      canvas.drawImageRect(img, srcRect, rect, paintBlur);
    } else {
      final paint = Paint()..filterQuality = ui.FilterQuality.high;
      if (colorMatrix != null) {
        paint.colorFilter = ui.ColorFilter.matrix(colorMatrix);
      }
      canvas.drawImageRect(
        img,
        srcRect,
        rect,
        paint,
      );
    }

    // 针对每个图单独应用色温滤镜，保证拍立得的白边不被染色
    _applyFilter(canvas, rect, filterName);
  }

  /// 绘制滤镜
  static void _applyFilter(Canvas canvas, Rect rect, String filterName) {
    if (filterName == 'warm') {
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFFFF9800).withValues(alpha: 0.08)
          ..blendMode = ui.BlendMode.softLight
          ..style = PaintingStyle.fill,
      );
    } else if (filterName == 'cool') {
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFF2196F3).withValues(alpha: 0.08)
          ..blendMode = ui.BlendMode.softLight
          ..style = PaintingStyle.fill,
      );
    } else if (filterName == 'retro') {
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFF795548).withValues(alpha: 0.12)
          ..blendMode = ui.BlendMode.softLight
          ..style = PaintingStyle.fill,
      );
    }
  }
}


