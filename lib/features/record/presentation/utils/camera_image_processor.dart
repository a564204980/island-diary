import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:island_diary/core/state/user_state.dart';

class ContourPoint {
  final double x;
  final double y;
  final double nx; // 法线 x
  final double ny; // 法线 y
  ContourPoint({
    required this.x,
    required this.y,
    required this.nx,
    required this.ny,
  });
}

class CameraImageProcessor {
  static ui.ColorFilter _createThresholdFilter(Color color, {double threshold = 0.16}) {
    // 阈值说明：
    //   高斯模糊后，原图边缘外 1σ 处的 alpha ≈ Q(1) ≈ 0.16。
    //   threshold = 0.5 只在原始边缘处截断，等于什么都没扩展。
    //   threshold = 0.16 使截断位置恰好在 1σ（= sigma = 目标扩展距离）处。
    final double r = color.r;
    final double g = color.g;
    final double b = color.b;
    const double s = 100.0;
    final double t = -100.0 * threshold;
    return ui.ColorFilter.matrix([
      0, 0, 0, 0, r,
      0, 0, 0, 0, g,
      0, 0, 0, 0, b,
      0, 0, 0, s, t,
    ]);
  }

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
    double strokeDistance = 6.0,
    Rect? normalizedCropRect,
  }) async {
    final file = io.File(imagePath);
    if (!await file.exists()) {
      throw Exception('照片文件不存在');
    }

    final bytes = await file.readAsBytes();
    final uiImage = await _loadUiImage(bytes);

    final int srcW = uiImage.width;
    final int srcH = uiImage.height;

    double dstW = srcW.toDouble();
    double dstH = srcH.toDouble();
    double offsetX = 0.0;
    double offsetY = 0.0;

    if (normalizedCropRect != null) {
      offsetX = normalizedCropRect.left * srcW;
      offsetY = normalizedCropRect.top * srcH;
      dstW = normalizedCropRect.width * srcW;
      dstH = normalizedCropRect.height * srcH;
    } else {
      // 1. 计算裁剪尺寸与坐标
      double targetRatio = 1.0;
      if (ratio == '4:3') {
        targetRatio = 4 / 3;
      } else if (ratio == '16:9') {
        targetRatio = 16 / 9;
      } else if (ratio == '3:4') {
        targetRatio = 3 / 4;
      } else if (ratio == '9:16') {
        targetRatio = 9 / 16;
      }

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
        final double scaleFactor = fgRect.width / 360.0;
        final double scaledStrokeWidth = strokeWidth * scaleFactor;
        final double scaledStrokeDistance = strokeDistance * scaleFactor;

        if (strokeStyle == 'solid') {
          canvas.saveLayer(fgRect, Paint());

          // 正确顺序：外层 colorFilter（阈值化），内层 imageFilter（模糊）
          final double outerSigma = math.max(0.5, scaledStrokeWidth + scaledStrokeDistance);
          canvas.saveLayer(fgRect, Paint()..colorFilter = _createThresholdFilter(strokeColor));
          canvas.saveLayer(fgRect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: outerSigma, sigmaY: outerSigma));
          canvas.drawImageRect(uiImage, srcRect, fgRect, Paint());
          canvas.restore(); // 应用模糊
          canvas.restore(); // 应用阈值化

          if (scaledStrokeDistance > 0) {
            final double innerSigma = math.max(0.5, scaledStrokeDistance);
            canvas.saveLayer(fgRect, Paint()
              ..colorFilter = _createThresholdFilter(Colors.white)
              ..blendMode = BlendMode.dstOut);
            canvas.saveLayer(fgRect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: innerSigma, sigmaY: innerSigma));
            canvas.drawImageRect(uiImage, srcRect, fgRect, Paint());
            canvas.restore();
            canvas.restore();
          }
          canvas.restore();
        } else if (strokeStyle == 'glow') {
          canvas.saveLayer(fgRect, Paint());

          // 正确顺序：外层 colorFilter（颜色），内层 imageFilter（模糊）
          final double totalSigma = math.max(0.5, scaledStrokeWidth + scaledStrokeDistance);
          canvas.saveLayer(fgRect, Paint()..colorFilter = ui.ColorFilter.mode(strokeColor, BlendMode.srcIn));
          canvas.saveLayer(fgRect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: totalSigma, sigmaY: totalSigma));
          canvas.drawImageRect(uiImage, srcRect, fgRect, Paint());
          canvas.restore();
          canvas.restore();

          if (scaledStrokeDistance > 0) {
            final double innerSigma = math.max(0.5, scaledStrokeDistance);
            canvas.saveLayer(fgRect, Paint()
              ..colorFilter = _createThresholdFilter(Colors.white)
              ..blendMode = BlendMode.dstOut);
            canvas.saveLayer(fgRect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: innerSigma, sigmaY: innerSigma));
            canvas.drawImageRect(uiImage, srcRect, fgRect, Paint());
            canvas.restore();
            canvas.restore();
          }
          canvas.restore();
        } else if (strokeStyle == 'stars') {
          // 1. 提取原图的边缘轮廓点 (返回 ContourPoint)
          final List<ContourPoint> rawContourPoints = await extractContourPoints(uiImage);
          
          // 2. 计算缩放因子 (用于外推距离、间距和星星大小等比放大)
          final double scaleFactor = fgRect.width / 360.0;

          // 3. 将轮廓点沿法线方向外推，并映射到画布的前景 rect 上 (裁切和缩放)
          final List<Offset> mappedPoints = [];
          for (final p in rawContourPoints) {
            final double rx = (p.x - offsetX) / dstW;
            final double ry = (p.y - offsetY) / dstH;
            final double basePX = rx * fgRect.width + fgRect.left;
            final double basePY = ry * fgRect.height + fgRect.top;

            // 沿着法线方向进行外推 (外推像素距离需按 scaleFactor 进行等比放大)
            final double px = basePX + p.nx * (strokeDistance * scaleFactor);
            final double py = basePY + p.ny * (strokeDistance * scaleFactor);

            mappedPoints.add(Offset(px, py));
          }

          // 4. 计算间距和星星大小 (加粗只放大星星，不增加数量)
          final double spacing = 11.0 * scaleFactor;
          final double starSize = (6.0 + strokeWidth * 0.8) * scaleFactor;

          // 4. 进行等距线性过滤
          final List<Offset> starPoints = filterMappedPoints(mappedPoints, spacing);

          // 5. 绘制圆润的五角星
          final starPaint = Paint()..color = strokeColor;
          for (int i = 0; i < starPoints.length; i++) {
            final p = starPoints[i];
            canvas.save();
            final double hash = (math.sin(i * 12.9898) * 43758.5453).abs() % 1.0;
            canvas.translate(p.dx, p.dy);
            canvas.rotate(hash * 2.0 * math.pi);
            drawRoundedFivePointStar(canvas, Offset.zero, starSize / 2, starPaint);
            canvas.restore();
          }
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
          text: "海岛日记 ╳ 拍立得",
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
        ..color = const Color(0xFFD4A373).withValues(alpha: 0.3)
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
        subText = '海岛日记 ╳ 拍立得';
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

  /// 快速提取透明/抠图图片的边缘轮廓点 (每 2 像素采样以兼顾性能与精度，同时计算边缘法向)
  static Future<List<ContourPoint>> extractContourPoints(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return [];
    final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    final int width = image.width;
    final int height = image.height;
    
    final List<ContourPoint> points = [];
    const int step = 2;
    for (int y = step; y < height - step; y += step) {
      for (int x = step; x < width - step; x += step) {
        final int idx = (y * width + x) * 4;
        final int alpha = bytes[idx + 3];
        if (alpha > 30) {
          // 精确检查上下左右相邻 1 像素的 Alpha，确保不漏掉任何过渡边缘
          final int leftAlpha = bytes[(y * width + (x - 1)) * 4 + 3];
          final int rightAlpha = bytes[(y * width + (x + 1)) * 4 + 3];
          final int topAlpha = bytes[((y - 1) * width + x) * 4 + 3];
          final int bottomAlpha = bytes[((y + 1) * width + x) * 4 + 3];
          
          if (leftAlpha < 150 || rightAlpha < 150 || topAlpha < 150 || bottomAlpha < 150) {
            // 计算 3x3 范围的简易 Alpha 梯度作为法线方向
            // 在图像处理中，梯度指向 Alpha 增加的方向（即朝向不透明的前景物体内部）
            // 我们希望描边往外偏移（指向 Alpha 减小的背景区），所以法线取负梯度方向
            final int xLeft = (x - 2).clamp(0, width - 1);
            final int xRight = (x + 2).clamp(0, width - 1);
            final int yTop = (y - 2).clamp(0, height - 1);
            final int yBottom = (y + 2).clamp(0, height - 1);

            final double alphaLeft = bytes[(y * width + xLeft) * 4 + 3].toDouble();
            final double alphaRight = bytes[(y * width + xRight) * 4 + 3].toDouble();
            final double alphaTop = bytes[(yTop * width + x) * 4 + 3].toDouble();
            final double alphaBottom = bytes[(yBottom * width + x) * 4 + 3].toDouble();

            final double gx = alphaRight - alphaLeft;
            final double gy = alphaBottom - alphaTop;

            double nx = 0.0;
            double ny = 0.0;
            final double len = math.sqrt(gx * gx + gy * gy);
            if (len > 0) {
              // 归一化并反转方向以指向前景物体的外部
              nx = -gx / len;
              ny = -gy / len;
            } else {
              // 兜底朝外：基于中心位置猜测外推方向
              final double centerX = width / 2.0;
              final double centerY = height / 2.0;
              final double dx = x - centerX;
              final double dy = y - centerY;
              final double dLen = math.sqrt(dx * dx + dy * dy);
              if (dLen > 0) {
                nx = dx / dLen;
                ny = dy / dLen;
              }
            }

            points.add(ContourPoint(
              x: x.toDouble(),
              y: y.toDouble(),
              nx: nx,
              ny: ny,
            ));
          }
        }
      }
    }
    return points;
  }

  /// 使用网格化算法进行 O(N) 线性过滤，确保点与点之间的距离不小于 spacing
  static List<Offset> filterMappedPoints(List<Offset> mappedPoints, double spacing) {
    if (mappedPoints.isEmpty) return [];
    final List<Offset> result = [];
    final double cellSize = spacing;
    final Map<String, Offset> grid = {};
    
    for (final p in mappedPoints) {
      final int gridX = (p.dx / cellSize).floor();
      final int gridY = (p.dy / cellSize).floor();
      
      bool tooClose = false;
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final key = "${gridX + dx},${gridY + dy}";
          final neighbor = grid[key];
          if (neighbor != null) {
            final distSq = (p.dx - neighbor.dx) * (p.dx - neighbor.dx) +
                           (p.dy - neighbor.dy) * (p.dy - neighbor.dy);
            if (distSq < spacing * spacing) {
              tooClose = true;
              break;
            }
          }
        }
        if (tooClose) break;
      }
      
      if (!tooClose) {
        grid["$gridX,$gridY"] = p;
        result.add(p);
      }
    }
    return result;
  }

  /// 绘制圆润可爱的五角星 (tips 和 valleys 均使用二次贝塞尔圆滑化处理)
  static void drawRoundedFivePointStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final Path path = Path();
    final double R = radius;
    final double r = radius * 0.40; // 0.40 时五角星最圆润敦实
    final double angle = math.pi / 5;
    
    final List<Offset> vertices = [];
    for (int i = 0; i < 10; i++) {
      final double currRadius = i.isEven ? R : r;
      final double theta = i * angle - math.pi / 2;
      final double x = center.dx + currRadius * math.cos(theta);
      final double y = center.dy + currRadius * math.sin(theta);
      vertices.add(Offset(x, y));
    }
    
    final List<Offset> midpoints = [];
    for (int i = 0; i < 10; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % 10];
      midpoints.add(Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2));
    }
    
    path.moveTo(midpoints[0].dx, midpoints[0].dy);
    for (int i = 0; i < 10; i++) {
      final controlPoint = vertices[(i + 1) % 10];
      final endPoint = midpoints[(i + 1) % 10];
      path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}


