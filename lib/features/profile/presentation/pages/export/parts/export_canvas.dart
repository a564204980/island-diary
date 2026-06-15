part of '../../diary_book_export_page.dart';

final Map<String, ui.Shader> _exportShaderCache = {};

extension _ExportCanvasExtension on _DiaryBookExportPageState {
  void setState(VoidCallback fn) => updateState(fn);

  // --- 画布组件构建 ---
  Widget _buildCanvas() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      width: _canvasWidth,
      height: _canvasHeight,
      decoration: BoxDecoration(
        color: _bgSettings.color,
        image: _bgSettings.imagePath != null
            ? DecorationImage(
                image: (_bgSettings.imagePath!.startsWith('http://') ||
                        _bgSettings.imagePath!.startsWith('https://'))
                    ? NetworkImage(_bgSettings.imagePath!) as ImageProvider
                    : FileImage(File(_bgSettings.imagePath!)) as ImageProvider,
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 页边距辅助线（仅在选中状态下展示页边距范围提示）
          Positioned(
            left: _margin.left,
            top: _margin.top,
            right: _margin.right,
            bottom: _margin.bottom,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF5A3E28).withValues(alpha: 0.25),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
            ),
          ),

          // 如果有日记，在顶部绘制百分百还原的日记头部
          if (widget.diaries.isNotEmpty)
            Positioned(
              left: _margin.left,
              top: _margin.top,
              right: _margin.right,
              child: _buildExportDiaryHeader(widget.diaries.first),
            ),

          // 渲染页面内的所有设计元素（非选中的先画，选中的最后画以保证最高的 Z 层级）
          ..._elements.where((e) => e.isVisible && e.id != _selectedElementId).map((e) => _buildCanvasElement(e)),
          if (_selectedElementId != null)
            ..._elements.where((e) => e.isVisible && e.id == _selectedElementId).map((e) => _buildCanvasElement(e)),

          // 选中的元素悬浮快捷菜单
          _buildSuspendedToolbar(),

          // 实时宽高提示气泡
          _buildDimensionBubble(),
        ],
      ),
    );
  }

  // 构建当前选中元素的悬浮操作栏
  Widget _buildSuspendedToolbar() {
    if (_selectedElementId == null || _activeHandle != null) return const SizedBox.shrink();
    final elementIdx = _elements.indexWhere((e) => e.id == _selectedElementId);
    if (elementIdx == -1) return const SizedBox.shrink();
    final element = _elements[elementIdx];
    if (!element.isVisible) return const SizedBox.shrink();

    final Color darkBlue = const Color(0xFF2B2654);

    return Positioned(
      left: element.x,
      top: element.y - 56, // 略微往上移以防遮挡选中框
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. 画笔魔法棒图标
            GestureDetector(
              onTap: element.isLocked
                  ? null
                  : () {
                      if (element.type == 'text') {
                        setState(() {
                          _editingElementId = element.id;
                          _inlineFocusNode.requestFocus();
                        });
                      } else if (element.type == 'image') {
                        _showImageEditDialog(element);
                      }
                    },
              child: Icon(
                Icons.auto_fix_high,
                color: element.isLocked ? Colors.grey[300] : darkBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            
            // 2. 文本按钮（未锁定显示“锁定组件”，已锁定显示“解锁组件”）
            GestureDetector(
              onTap: () {
                setState(() {
                  element.isLocked = !element.isLocked;
                });
              },
              child: Text(
                element.isLocked ? '解锁组件' : '锁定组件',
                style: TextStyle(
                  color: darkBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
            const SizedBox(width: 14),
            
            // 竖向细分割线
            Container(
              width: 1,
              height: 14,
              color: Colors.grey[200],
            ),
            const SizedBox(width: 14),

            if (!element.isLocked) ...[
              // 3. 对话气泡加号（用作快捷备注或提示）
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已为该元素创建了专属图层备注！', style: TextStyle(fontFamily: 'LXGWWenKai')),
                      backgroundColor: Color(0xFF2B2654),
                    ),
                  );
                },
                child: Icon(
                  Icons.add_comment_outlined,
                  color: darkBlue,
                  size: 17,
                ),
              ),
              const SizedBox(width: 14),

              // 4. 双框加号（复制）
              GestureDetector(
                onTap: () {
                  _saveToHistory();
                  final newElement = element.copy();
                  newElement.x += 20;
                  newElement.y += 20;
                  final newId = 'copy_${DateTime.now().millisecondsSinceEpoch}';
                  setState(() {
                    _elements.add(
                      ExportElement(
                        id: newId,
                        type: element.type,
                        x: newElement.x,
                        y: newElement.y,
                        width: element.width,
                        height: element.height,
                        content: element.content,
                        fontSize: element.fontSize,
                        color: element.color,
                        fontFamily: element.fontFamily,
                        fontWeight: element.fontWeight,
                        fontStyle: element.fontStyle,
                        textDecoration: element.textDecoration,
                        textAlign: element.textAlign,
                        letterSpacing: element.letterSpacing,
                        lineHeight: element.lineHeight,
                        opacity: element.opacity,
                        borderRadius: element.borderRadius,
                        cropRatio: element.cropRatio,
                      ),
                    );
                    _selectElement(newId);
                  });
                },
                child: Icon(
                  Icons.library_add_outlined,
                  color: darkBlue,
                  size: 17,
                ),
              ),
              const SizedBox(width: 14),
            ],

            // 5. 垃圾桶（删除）
            GestureDetector(
              onTap: () {
                _saveToHistory();
                setState(() {
                  _elements.removeWhere((e) => e.id == element.id);
                  _selectElement(null);
                });
              },
              child: Icon(
                Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // 6. 更多按钮
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('更多高级设计设置正在开发中！', style: TextStyle(fontFamily: 'LXGWWenKai')),
                    backgroundColor: Color(0xFF2B2654),
                  ),
                );
              },
              child: Icon(
                Icons.more_horiz,
                color: darkBlue,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 渲染单个画布元素与编辑控制点
  Widget _buildCanvasElement(ExportElement element) {
    final isSelected = element.id == _selectedElementId;
    const double handlePadding = 12.0;

    return Positioned(
      left: element.x - handlePadding,
      top: element.y - handlePadding,
      child: Transform.rotate(
        angle: element.rotation,
        child: GestureDetector(
          onTapDown: (_) {
            _selectElement(element.id);
          },
        onDoubleTap: element.isLocked
            ? null
            : () {
                _selectElement(element.id);
                if (element.type == 'text') {
                  setState(() {
                    _editingElementId = element.id;
                    _inlineFocusNode.requestFocus();
                  });
                } else if (element.type == 'image') {
                  _showImageEditDialog(element);
                }
              },
        onPanStart: (element.isLocked || element.id == _editingElementId)
            ? null
            : (details) {
                setState(() {
                  _activeHandle = 'move';
                });
              },
        onPanEnd: (element.isLocked || element.id == _editingElementId)
            ? null
            : (details) {
                setState(() {
                  _activeHandle = null;
                });
              },
        onPanCancel: (element.isLocked || element.id == _editingElementId)
            ? null
            : () {
                setState(() {
                  _activeHandle = null;
                });
              },
        onPanUpdate: (element.isLocked || element.id == _editingElementId)
            ? null
            : (details) {
                setState(() {
                  double newX = element.x + details.delta.dx;
                  double newY = element.y + details.delta.dy;

                  // 针对内容元素 (text, chart) 进行页边距磁吸
                  if (element.type == 'text' || element.type == 'chart') {
                    const double snapThreshold = 8.0;

                    // X 轴磁吸
                    if ((newX - _margin.left).abs() < snapThreshold) {
                      newX = _margin.left;
                    } else if ((newX + element.width - (_canvasWidth - _margin.right)).abs() < snapThreshold) {
                      newX = _canvasWidth - _margin.right - element.width;
                    }

                    // Y 轴磁吸
                    if ((newY - _margin.top).abs() < snapThreshold) {
                      newY = _margin.top;
                    } else if ((newY + element.height - (_canvasHeight - _margin.bottom)).abs() < snapThreshold) {
                      newY = _canvasHeight - _margin.bottom - element.height;
                    }
                  }

                  // 所有元素均受到物理纸张边界限制
                  element.x = newX.clamp(0.0, (_canvasWidth - element.width).clamp(0.0, _canvasWidth));
                  element.y = newY.clamp(0.0, (_canvasHeight - element.height).clamp(0.0, _canvasHeight));
                });
              },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 元素本尊（作为唯一的非 Positioned 子项，用于撑起 Stack 的大小）
            Padding(
              padding: const EdgeInsets.only(left: handlePadding, right: handlePadding, top: handlePadding, bottom: handlePadding + 50.0),
              child: Container(
                width: element.width,
                height: element.type == 'text' ? null : element.height,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: const Color(0xFF8B5CF6), width: 1.5)
                      : null,
                ),
                child: _renderElementContent(element),
              ),
            ),

            // 选中状态下的四个角拉伸手势点、两侧胶囊手柄和悬浮条
            if (isSelected && !element.isLocked) ...[
              // 1. 左上角
              Positioned(
                left: handlePadding - 30,
                top: handlePadding - 30,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    setState(() {
                      _activeHandle = 'topLeft';
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanCancel: () {
                    setState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _saveToHistory();
                      final double newX = (element.x + details.delta.dx).clamp(0.0, element.x + element.width - 30.0);
                      final double dx = newX - element.x;
                      element.x = newX;
                      element.width -= dx;

                      final double newY = (element.y + details.delta.dy).clamp(0.0, element.y + element.height - 10.0);
                      final double dy = newY - element.y;
                      element.y = newY;
                      element.height -= dy;
                    });
                  },
                  child: _buildControlPoint(isActive: _activeHandle == 'topLeft'),
                ),
              ),
              // 2. 右上角
              Positioned(
                right: handlePadding - 30,
                top: handlePadding - 30,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    setState(() {
                      _activeHandle = 'topRight';
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanCancel: () {
                    setState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _saveToHistory();
                      element.width = (element.width + details.delta.dx).clamp(30.0, (_canvasWidth - element.x).clamp(30.0, _canvasWidth));
                      
                      final double newY = (element.y + details.delta.dy).clamp(0.0, element.y + element.height - 10.0);
                      final double dy = newY - element.y;
                      element.y = newY;
                      element.height -= dy;
                    });
                  },
                  child: _buildControlPoint(isActive: _activeHandle == 'topRight'),
                ),
              ),
              // 3. 左下角
              Positioned(
                left: handlePadding - 30,
                bottom: handlePadding + 20,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    setState(() {
                      _activeHandle = 'bottomLeft';
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanCancel: () {
                    setState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _saveToHistory();
                      final double newX = (element.x + details.delta.dx).clamp(0.0, element.x + element.width - 30.0);
                      final double dx = newX - element.x;
                      element.x = newX;
                      element.width -= dx;

                      element.height = (element.height + details.delta.dy).clamp(10.0, (_canvasHeight - element.y).clamp(10.0, _canvasHeight));
                    });
                  },
                  child: _buildControlPoint(isActive: _activeHandle == 'bottomLeft'),
                ),
              ),
              // 4. 右下角
              Positioned(
                right: handlePadding - 30,
                bottom: handlePadding + 20,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    setState(() {
                      _activeHandle = 'bottomRight';
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanCancel: () {
                    setState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _saveToHistory();
                      element.width = (element.width + details.delta.dx).clamp(30.0, (_canvasWidth - element.x).clamp(30.0, _canvasWidth));
                      element.height = (element.height + details.delta.dy).clamp(10.0, (_canvasHeight - element.y).clamp(10.0, _canvasHeight));
                    });
                  },
                  child: _buildControlPoint(isActive: _activeHandle == 'bottomRight'),
                ),
              ),
              // 5. 左侧中点（仅拉伸宽度并联动 x，胶囊形状）
              Positioned(
                left: handlePadding - 30,
                top: handlePadding,
                bottom: handlePadding + 50.0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) {
                      setState(() {
                        _activeHandle = 'leftSide';
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanCancel: () {
                      setState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _saveToHistory();
                        final double newX = (element.x + details.delta.dx).clamp(0.0, element.x + element.width - 30.0);
                        final double dx = newX - element.x;
                        element.x = newX;
                        element.width -= dx;
                      });
                    },
                    child: _buildControlPoint(isCapsule: true, isActive: _activeHandle == 'leftSide'),
                  ),
                ),
              ),
              // 6. 右侧中点（仅拉伸宽度，胶囊形状）
              Positioned(
                right: handlePadding - 30,
                top: handlePadding,
                bottom: handlePadding + 50.0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) {
                      setState(() {
                        _activeHandle = 'rightSide';
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanCancel: () {
                      setState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _saveToHistory();
                        element.width = (element.width + details.delta.dx).clamp(30.0, (_canvasWidth - element.x).clamp(30.0, _canvasWidth));
                      });
                    },
                    child: _buildControlPoint(isCapsule: true, isActive: _activeHandle == 'rightSide'),
                  ),
                ),
              ),
              // 7. 底部旋转手柄（圆形、白底紫边、中间为旋转箭头图标）
              Positioned(
                bottom: 8.0,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        element.rotation += pi / 2;
                      });
                    },
                    onPanStart: (_) {
                      setState(() {
                        _activeHandle = 'rotate';
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanCancel: () {
                      setState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        // 1. 取得旋转弧度逆向投影回本地的水平位移量 ldx
                        final double cosA = cos(-element.rotation);
                        final double sinA = sin(-element.rotation);
                        final double ldx = details.delta.dx * cosA - details.delta.dy * sinA;

                        // 2. 旋转半径
                        final double ry = element.height / 2 + 30.0;

                        // 3. 计算旋转增量并更新
                        final double dAngle = -ldx / ry;
                        element.rotation += dAngle;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.sync_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // 锁定状态的提示
            if (isSelected && element.isLocked)
              Positioned(
                top: -30,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        element.isLocked = false;
                      });
                      _selectElement(element.id); // 解锁后保持选中当前元素，防止事件穿透导致选中底下重合的其他元素
                    },
                    child: const Icon(Icons.lock, color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),);
  }

  Widget _buildControlPoint({bool isCapsule = false, bool isActive = false}) {
    return Container(
      width: 60,
      height: 60,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 活跃（拖拽中）状态下的半透明淡绿蓝色外圈（直径 50dp，有软阴影扩散感）
          if (isActive)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.25), // 柔和半透明淡蓝绿色
                shape: BoxShape.circle,
              ),
            ),
          Container(
            width: isCapsule ? 8 : 14,
            height: isCapsule ? 18 : 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: isCapsule ? BorderRadius.circular(4) : null,
              shape: isCapsule ? BoxShape.rectangle : BoxShape.circle,
              border: Border.all(color: const Color(0xFF8B5CF6), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionBubble() {
    if (_activeHandle == null || _selectedElementId == null) return const SizedBox.shrink();
    final elementIdx = _elements.indexWhere((e) => e.id == _selectedElementId);
    if (elementIdx == -1) return const SizedBox.shrink();
    final element = _elements[elementIdx];
    
    final bool isRotating = _activeHandle == 'rotate';
    String textContent;
    if (isRotating) {
      int degree = (element.rotation * 180 / pi).round() % 360;
      if (degree > 180) degree -= 360;
      textContent = '$degree°';
    } else {
      textContent = '宽度:${element.width.toInt()} 高度:${element.height.toInt()}';
    }

    return Positioned(
      left: element.x,
      width: element.width,
      top: element.y + element.height + 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            textContent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportDiaryHeader(DiaryEntry entry) {
    final dt = entry.dateTime;
    final mood = kMoods[entry.moodIndex.clamp(0, kMoods.length - 1)];
    final inkColor = DiaryUtils.getInkColor(entry.paperStyle, false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 大日期排版
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              dt.day.toString(),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w500,
                color: inkColor,
                fontFamily: 'Georgia',
                height: 1.0,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${dt.year}年${dt.month}月",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: inkColor.withValues(alpha: 0.6),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"][dt.weekday - 1]}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: inkColor.withValues(alpha: 0.8),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // 2. 标签包
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // 心情
            (() {
              final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
              final String moodLabel = parsed.customMood ?? mood.label;
              final String iconPath = parsed.customMood != null
                  ? (entry.moodIndex >= 0 && entry.moodIndex <= 23
                      ? 'assets/icons/custom${entry.moodIndex + 1}.png'
                      : 'assets/images/icons/custom.png')
                  : (mood.iconPath ?? 'assets/icons/happy.png');
              final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xAAFFFDF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5DEC9), width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    hasCustomIcon
                        ? Image.file(File(parsed.customMoodIconPath!), width: 14, height: 14)
                        : Image.asset(iconPath, width: 14, height: 14),
                    const SizedBox(width: 5),
                    Text(
                      moodLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5E6C6D), fontFamily: 'LXGWWenKai'),
                    ),
                  ],
                ),
              );
            })(),
            
            // 标签
            ...ParsedTags.parse(entry.tag, entry.moodIndex).tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xAAFFFDF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5DEC9), width: 0.6),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5E6C6D), fontFamily: 'LXGWWenKai'),
                ),
              );
            }),
            
            // 天气
            if (entry.weather != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xAAFFFDF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5DEC9), width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getExportWeatherIcon(entry.weather),
                      size: 12,
                      color: const Color(0xFF5E6C6D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${entry.weather} ${entry.temp ?? ''}",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5E6C6D), fontFamily: 'LXGWWenKai'),
                    ),
                  ],
                ),
              ),
              
            // 地点
            if (entry.location != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xAAFFFDF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5DEC9), width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF5E6C6D)),
                    const SizedBox(width: 4),
                    Text(
                      entry.location!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5E6C6D), fontFamily: 'LXGWWenKai'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  IconData _getExportWeatherIcon(String? weather) {
    if (weather == null) return Icons.wb_sunny_outlined;
    if (weather.contains("晴")) return Icons.wb_sunny_outlined;
    if (weather.contains("多云")) return Icons.wb_cloudy_outlined;
    if (weather.contains("阴")) return Icons.cloud_outlined;
    if (weather.contains("雨")) return Icons.umbrella_outlined;
    if (weather.contains("雪")) return Icons.ac_unit_outlined;
    if (weather.contains("风")) return Icons.air_outlined;
    if (weather.contains("雾")) return Icons.grain_outlined;
    if (weather.contains("雷")) return Icons.thunderstorm_outlined;
    return Icons.wb_sunny_outlined;
  }

  ui.Shader _getExportUnderlineShader(String style, Color color, double fontSize, double lineHeight) {
    final double rectHeight = fontSize * lineHeight;
    final key = "${style}_${color.toARGB32()}_${fontSize.toStringAsFixed(1)}_${lineHeight.toStringAsFixed(1)}";
    if (_exportShaderCache.containsKey(key)) {
      return _exportShaderCache[key]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;

    // 完美抵消居中排版带来的文本下沉量，并使用 clamp 限制坐标在图片高度内以防溢出消失
    final double y = (fontSize * 1.2 + (lineHeight - 1.0) * fontSize * 0.5).clamp(0.0, rectHeight - 2.5);

    paint.strokeWidth = 1.4;
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(10, y), paint);

    final picture = recorder.endRecording();
    final width = 10;
    final height = rectHeight.clamp(1.0, 1000.0).toInt();
    final img = picture.toImageSync(width, height);
    final shader = ImageShader(
      img,
      TileMode.repeated,
      TileMode.repeated,
      Float64List.fromList([
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
      ]),
    );
    _exportShaderCache[key] = shader;
    return shader;
  }

  InlineSpan _buildRichTextSpan(String text, TextStyle baseStyle) {
    final chunks = EmojiMapping.parseText(text);
    if (chunks.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }
    return TextSpan(
      children: chunks.map((chunk) {
        if (chunk.isEmoji) {
          return WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: Image.asset(
                chunk.emojiPath!,
                width: (baseStyle.fontSize ?? 18.0) * 1.3,
                height: (baseStyle.fontSize ?? 18.0) * 1.3,
                fit: BoxFit.contain,
              ),
            ),
          );
        }
        return TextSpan(text: chunk.text, style: baseStyle);
      }).toList(),
    );
  }

  Widget _renderElementContent(ExportElement element) {
    final isEditing = element.id == _editingElementId;
    switch (element.type) {
      case 'text':
        final double fs = element.fontSize;
        final double lh = element.lineHeight;
        final double rectHeight = fs * lh;

        Paint? backgroundPaint;
        if (element.textDecoration == 'underline') {
          backgroundPaint = Paint()
            ..shader = _getExportUnderlineShader('solid', element.color, element.fontSize, element.lineHeight);
        }

        final textStyle = TextStyle(
          fontSize: element.fontSize,
          color: element.color,
          fontFamily: element.fontFamily == '系统内置' ? 'LXGWWenKai' : element.fontFamily,
          fontWeight: element.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
          fontStyle: element.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
          decoration: element.textDecoration == 'line-through'
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          letterSpacing: element.letterSpacing,
          height: element.lineHeight,
          background: backgroundPaint,
        );
        final align = element.textAlign == 'center'
            ? TextAlign.center
            : element.textAlign == 'right'
                ? TextAlign.right
                : TextAlign.left;
        final strutStyle = StrutStyle(
          fontSize: element.fontSize,
          height: element.lineHeight,
          fontFamily: element.fontFamily == '系统内置' ? 'LXGWWenKai' : element.fontFamily,
          forceStrutHeight: true,
        );

        if (isEditing) {
          return Opacity(
            opacity: element.opacity,
            child: TextField(
              controller: _textEditorController,
              focusNode: _inlineFocusNode,
              autofocus: true,
              maxLines: null,
              textAlign: align,
              style: textStyle,
              strutStyle: strutStyle,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() {
                  element.content = val;
                  _adjustTextElementWidth(element);
                });
              },
              onSubmitted: (_) {
                setState(() {
                  _editingElementId = null;
                });
              },
            ),
          );
        }
        return Opacity(
          opacity: element.opacity,
          child: SizedBox(
            width: element.width,
            child: Text.rich(
              _buildRichTextSpan(element.content, textStyle) as TextSpan,
              textAlign: align,
              strutStyle: strutStyle,
            ),
          ),
        );
      case 'image':
        final isNetwork = element.content.startsWith('http://') || element.content.startsWith('https://');
        final isChart = element.content.contains('chart_') || element.id.contains('chart_');
        final fit = isChart ? BoxFit.contain : BoxFit.cover;
        return ClipRRect(
          borderRadius: BorderRadius.circular(element.borderRadius),
          child: isNetwork
              ? Image.network(
                  element.content,
                  fit: fit,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
                )
              : Image.file(
                  File(element.content),
                  fit: fit,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
        );
      case 'line':
        return Divider(
          color: element.color,
          thickness: element.height,
        );
      case 'shape':
        if (element.content == 'circle') {
          return Container(
            decoration: BoxDecoration(
              color: element.color,
              shape: BoxShape.circle,
            ),
          );
        } else {
          return Container(
            color: element.color,
          );
        }
      case 'chart':
        return _renderChartElement(element);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _renderChartElement(ExportElement element) {
    final String chartType = element.content;
    final allDiaries = UserState().savedDiaries.value;
    Widget chartWidget;
    if (chartType == 'radar') {
      chartWidget = ExportRadarChart(diaries: allDiaries);
    } else if (chartType == 'trend') {
      chartWidget = ExportTrendChart(diaries: allDiaries);
    } else if (chartType == 'weekly') {
      chartWidget = ExportWeeklyChart(diaries: allDiaries);
    } else if (chartType == 'palette') {
      chartWidget = ExportPaletteChart(diaries: allDiaries);
    } else if (chartType == 'mood_flow') {
      chartWidget = ExportMoodFlowChart(diaries: allDiaries);
    } else if (chartType == 'heatmap') {
      chartWidget = ExportHeatmapChart(diaries: allDiaries);
    } else {
      return const SizedBox.shrink();
    }

    final double targetHeight = (chartType == 'radar')
        ? 360
        : (chartType == 'mood_flow' ? 240 : 220);

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 300,
        height: targetHeight,
        child: chartWidget,
      ),
    );
  }

  Widget _buildMiniActionIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  // --- 快速工具栏 ---
  // --- 快速工具栏 ---
  Widget _buildQuickToolbar() {
    final Color activeColor = const Color(0xFF5A3E28);
    final Color disabledColor = const Color(0xFFD0C6BE);

    Widget buildToolIcon({
      required IconData icon,
      required VoidCallback? onPressed,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        textStyle: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'LXGWWenKai'),
        decoration: BoxDecoration(
          color: const Color(0xFF5A3E28).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            icon: Icon(icon),
            onPressed: onPressed,
            color: activeColor,
            disabledColor: disabledColor,
            iconSize: 18,
            splashRadius: 18,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A3E28).withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildToolIcon(
            icon: Icons.undo_rounded,
            onPressed: _undoStack.isNotEmpty ? _undo : null,
            tooltip: '撤销',
          ),
          const SizedBox(width: 8),
          buildToolIcon(
            icon: Icons.redo_rounded,
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            tooltip: '重做',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 1,
            height: 16,
            color: const Color(0xFFE5DDD5),
          ),
          buildToolIcon(
            icon: Icons.align_horizontal_center_rounded,
            onPressed: _selectedElementId == null ? null : _alignSelectedElementCenter,
            tooltip: '水平居中',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 1,
            height: 16,
            color: const Color(0xFFE5DDD5),
          ),
          buildToolIcon(
            icon: Icons.zoom_out_rounded,
            onPressed: () => _zoom(1 / 1.15),
            tooltip: '缩小画布',
          ),
          const SizedBox(width: 8),
          buildToolIcon(
            icon: Icons.zoom_in_rounded,
            onPressed: () => _zoom(1.15),
            tooltip: '放大画布',
          ),
        ],
      ),
    );
  }

  void _alignSelectedElementCenter() {
    if (_selectedElementId != null) {
      _saveToHistory();
      final idx = _elements.indexWhere((e) => e.id == _selectedElementId);
      if (idx != -1) {
        setState(() {
          _elements[idx].x = (_canvasWidth - _elements[idx].width) / 2;
        });
      }
    }
  }
}


