part of '../../diary_book_export_page.dart';

extension _ExportCanvasGestureExtension on _DiaryBookExportPageState {
  // 渲染单个画布元素与编辑控制点
  Widget _buildCanvasElement(ExportElement element) {
    final isSelected = element.id == _selectedElementId;
    const double handlePadding = 12.0;

    // 移动手势包裹在 Transform.rotate 外层，使 details.delta 保持屏幕坐标系，
    // 无论元素旋转多少度，向左拖就向左移。
    // ValueKey 确保 Flutter 按元素 ID 而非位置匹配 widget，避免选中切换后
    // 手势识别器的回调 closure 被替换为错误元素的回调。
    final double screenY = getScreenY(element.y);

    return Positioned(
      key: ValueKey(element.id),
      left: element.x - handlePadding,
      top: screenY - handlePadding,
      child: GestureDetector(
        onPanStart: (element.isLocked || element.id == _editingElementId || element.id != _selectedElementId)
            ? null
            : (details) {
                _saveToHistory();
                updateState(() {
                  _activeHandle = 'move';
                  _dragX = element.x;
                  _dragY = screenY;
                });
              },
        onPanEnd: (element.isLocked || element.id == _editingElementId || element.id != _selectedElementId)
            ? null
            : (details) {
                updateState(() {
                  _activeHandle = null;
                });
              },
        onPanCancel: (element.isLocked || element.id == _editingElementId || element.id != _selectedElementId)
            ? null
            : () {
                updateState(() {
                  _activeHandle = null;
                });
              },
        onPanUpdate: (element.isLocked || element.id == _editingElementId || element.id != _selectedElementId)
            ? null
            : (details) {
                  updateState(() {
                  // 此处 delta 已是屏幕坐标系（GestureDetector 在 Transform.rotate 外），
                  // 虚拟拖拽坐标累加 delta（保留没有被磁吸强制修正的真实手势轨迹）
                  _dragX += details.delta.dx;
                  _dragY += details.delta.dy;

                  double newX = _dragX;
                  double newY = _dragY;

                  // 页边距与相邻元素磁吸对齐（仅在元素基本未旋转时才做磁吸，旋转后对齐参考线没有意义）
                  final double rotationMod = element.rotation % (2 * pi);
                  final bool nearNoRotation = rotationMod < 0.1 || rotationMod > (2 * pi - 0.1);
                  if (nearNoRotation) {
                    const double snapThreshold = 8.0;

                    // 1. 页边距磁吸
                    if ((_dragX - _margin.left).abs() < snapThreshold) {
                      newX = _margin.left;
                    } else if ((_dragX + element.width - (_canvasWidth - _margin.right)).abs() < snapThreshold) {
                      newX = _canvasWidth - _margin.right - element.width;
                    }
                    if ((_dragY - _margin.top).abs() < snapThreshold) {
                      newY = _margin.top;
                    } else if ((_dragY + element.height - (_canvasHeight - _margin.bottom)).abs() < snapThreshold) {
                      newY = _canvasHeight - _margin.bottom - element.height;
                    }

                    // 2. 相邻元素对齐吸附 (遍历其他可见未旋转元素)
                    for (var other in _elements) {
                      if (other.id == element.id || !other.isVisible) continue;

                      final double otherRot = other.rotation % (2 * pi);
                      final bool otherNearNoRotation = otherRot < 0.1 || otherRot > (2 * pi - 0.1);
                      if (!otherNearNoRotation) continue;

                      // --- Y 轴方向对齐吸附 ---
                      // 顶部对齐
                      if ((_dragY - other.y).abs() < snapThreshold) {
                        newY = other.y;
                      }
                      // 底部对齐
                      else if ((_dragY + element.height - (other.y + other.height)).abs() < snapThreshold) {
                        newY = other.y + other.height - element.height;
                      }
                      // 垂直居中对齐
                      else if (((_dragY + element.height / 2) - (other.y + other.height / 2)).abs() < snapThreshold) {
                        newY = other.y + other.height / 2 - element.height / 2;
                      }
                      // 纵向首尾相连邻接
                      else if ((_dragY - (other.y + other.height)).abs() < snapThreshold) {
                        newY = other.y + other.height;
                      }
                      else if (((_dragY + element.height) - other.y).abs() < snapThreshold) {
                        newY = other.y - element.height;
                      }

                      // --- X 轴方向对齐吸附 ---
                      // 左侧对齐
                      if ((_dragX - other.x).abs() < snapThreshold) {
                        newX = other.x;
                      }
                      // 右侧对齐
                      else if ((_dragX + element.width - (other.x + other.width)).abs() < snapThreshold) {
                        newX = other.x + other.width - element.width;
                      }
                      // 水平居中对齐
                      else if (((_dragX + element.width / 2) - (other.x + other.width / 2)).abs() < snapThreshold) {
                        newX = other.x + other.width / 2 - element.width / 2;
                      }
                      // 横向首尾并排邻接
                      else if ((_dragX - (other.x + other.width)).abs() < snapThreshold) {
                        newX = other.x + other.width;
                      }
                      else if (((_dragX + element.width) - other.x).abs() < snapThreshold) {
                        newX = other.x - element.width;
                      }
                    }
                  }

                  // 旋转感知的边界限制：
                  // 旋转后轴对齐包围盒的半尺寸 = (W·|cosθ| + H·|sinθ|) / 2
                  // 以元素中心点做 clamp，确保旋转后四个角均不超出纸张。
                  final double abscos = cos(element.rotation).abs();
                  final double abssin = sin(element.rotation).abs();
                  final double rotatedHalfW = (element.width * abscos + element.height * abssin) / 2;
                  final double rotatedHalfH = (element.width * abssin + element.height * abscos) / 2;

                  final double cx = (newX + element.width / 2)
                      .clamp(rotatedHalfW, (_canvasWidth - rotatedHalfW).clamp(rotatedHalfW, _canvasWidth));
                  final double cy = (newY + element.height / 2)
                      .clamp(rotatedHalfH, (_totalCanvasHeight - rotatedHalfH).clamp(rotatedHalfH, _totalCanvasHeight));

                  element.x = cx - element.width / 2;
                  element.y = getLayoutY(cy - element.height / 2);
                });

              },
        child: Transform.rotate(
          angle: element.rotation,
          child: GestureDetector(
            // 仅处理点击类手势，不再注册 pan（pan 已由外层处理）
            onTapDown: (_) {
              _selectElement(element.id);
            },
            onDoubleTap: element.isLocked
                ? null
                : () {
                    _selectElement(element.id);
                    if (element.type == 'text') {
                      updateState(() {
                        _editingElementId = element.id;
                        _inlineFocusNode.requestFocus();
                      });
                    } else if (element.type == 'image') {
                      _showImageEditDialog(element);
                    }
                  },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
            // 元素本尊（作为唯一的非 Positioned 子项，用于撑起 Stack 的大小）
            Padding(
              padding: const EdgeInsets.only(left: handlePadding, right: handlePadding, top: handlePadding, bottom: handlePadding + 50.0),
              child: Container(
                width: element.width,
                height: (element.type == 'text' || element.type == 'diary_header')
                    ? null
                    : (element.type == 'line' ? (element.height < 30.0 ? 30.0 : element.height) : element.height),
                alignment: element.type == 'line' ? Alignment.center : null,
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
                    updateState(() {
                      _activeHandle = 'topLeft';
                    });
                  },
                  onPanEnd: (_) {
                    updateState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanCancel: () {
                    updateState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanUpdate: (details) {
                    updateState(() {
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
                    updateState(() {
                      _activeHandle = 'topRight';
                    });
                  },
                  onPanEnd: (_) {
                    updateState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanCancel: () {
                    updateState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanUpdate: (details) {
                    updateState(() {
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
                    updateState(() {
                      _activeHandle = 'bottomLeft';
                    });
                  },
                  onPanEnd: (_) {
                    updateState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanCancel: () {
                    updateState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanUpdate: (details) {
                    updateState(() {
                      _saveToHistory();
                      final double newX = (element.x + details.delta.dx).clamp(0.0, element.x + element.width - 30.0);
                      final double dx = newX - element.x;
                      element.x = newX;
                      element.width -= dx;

                      element.height = (element.height + details.delta.dy).clamp(10.0, (_totalCanvasHeight - element.y).clamp(10.0, _totalCanvasHeight));
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
                    updateState(() {
                      _activeHandle = 'bottomRight';
                    });
                  },
                  onPanEnd: (_) {
                    updateState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanCancel: () {
                    updateState(() {
                      _activeHandle = null;
                    });
                  },
                  onPanUpdate: (details) {
                    updateState(() {
                      _saveToHistory();
                      element.width = (element.width + details.delta.dx).clamp(30.0, (_canvasWidth - element.x).clamp(30.0, _canvasWidth));
                      element.height = (element.height + details.delta.dy).clamp(10.0, (_totalCanvasHeight - element.y).clamp(10.0, _totalCanvasHeight));
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
                      updateState(() {
                        _activeHandle = 'leftSide';
                      });
                    },
                    onPanEnd: (_) {
                      updateState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanCancel: () {
                      updateState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanUpdate: (details) {
                      updateState(() {
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
                      updateState(() {
                        _activeHandle = 'rightSide';
                      });
                    },
                    onPanEnd: (_) {
                      updateState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanCancel: () {
                      updateState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanUpdate: (details) {
                      updateState(() {
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
                      _saveToHistory();
                      updateState(() {
                        element.rotation += pi / 2;
                      });
                    },
                    onPanStart: (_) {
                      _saveToHistory();
                      updateState(() {
                        _activeHandle = 'rotate';
                      });
                    },
                    onPanEnd: (_) {
                      updateState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanCancel: () {
                      updateState(() {
                        _activeHandle = null;
                      });
                    },
                    onPanUpdate: (details) {
                      updateState(() {
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
                      updateState(() {
                        element.isLocked = false;
                      });
                      _selectElement(element.id); // 解锁后保持选中当前元素，防止事件穿透导致选中底下重合的其他元素
                    },
                    child: const Icon(Icons.lock, color: Colors.white, size: 14),
                  ),
                ),
              ),
              ],
            ),        // Stack 结束
          ),          // 内层 GestureDetector 结束
        ),            // Transform.rotate 结束
      ),              // 外层 GestureDetector 结束
    );                // Positioned 结束
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
}
