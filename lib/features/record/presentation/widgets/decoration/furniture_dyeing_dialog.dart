import 'package:flutter/material.dart';
import '../../../domain/models/furniture_item.dart';
import '../../../domain/models/placed_furniture.dart';
import '../furniture_sprite.dart';

class FurnitureDyeingDialog extends StatefulWidget {
  final PlacedFurniture pf;
  final VoidCallback? onDyeConfirm;
  final Function(FurnitureColorVariant)? onVariantSelected;

  const FurnitureDyeingDialog({
    super.key,
    required this.pf,
    this.onDyeConfirm,
    this.onVariantSelected,
  });

  @override
  State<FurnitureDyeingDialog> createState() => _FurnitureDyeingDialogState();
}

class _FurnitureDyeingDialogState extends State<FurnitureDyeingDialog> {
  late FurnitureColorVariant _selectedVariant;

  @override
  void initState() {
    super.initState();
    final item = widget.pf.item;
    // 自动寻找匹配当前贴图路径的变体
    _selectedVariant = item.colorVariants.firstWhere(
      (v) => v.imagePath == item.imagePath,
      orElse: () => item.colorVariants.isNotEmpty
          ? item.colorVariants.first
          : FurnitureColorVariant(
              id: 'default',
              name: item.name,
              imagePath: item.imagePath,
              color: Colors.grey,
            ),
    );
  }

  FurnitureItem get item => widget.pf.item;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 520, // 加大宽度
        decoration: BoxDecoration(
          color: const Color(0xFFE8E1F5),
          borderRadius: BorderRadius.circular(32),
        ),
        padding: const EdgeInsets.all(24),
        child: IntrinsicHeight( // 使高度适应内容
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧：家具卡片展示区 (缩小并固定比例)
              Expanded(
                flex: 5,
                child: _buildFurnitureCard(),
              ),
              const SizedBox(width: 24),
              // 右侧：染色相关操作区
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '颜色选择',
                      style: TextStyle(
                        color: Color(0xFF5D4E7A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildColorSelector(),
                    const SizedBox(height: 24),
                    _buildStatusHint(),
                    const Spacer(),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFurnitureCard() {
    // 动态创建带有选中变体图片的 item
    final previewItem = item.copyWith(imagePath: _selectedVariant.imagePath);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // 预览图 (缩小内边距)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AspectRatio(
                      aspectRatio: item.intrinsicWidth / item.intrinsicHeight,
                      child: FurnitureSprite(
                        item: previewItem, // 使用预览 item
                      ),
                    ),
                  ),
                ),
                // 左上角颜色圆点
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _selectedVariant.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                // 右上角染色标识
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFA78BFA),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: const Icon(Icons.brush_rounded, color: Colors.white, size: 16),
                  ),
                ),
                // 右下角数量
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9C7A1).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: Color(0xFF8B5E3C),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 底部名称条
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFB4A1D9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Text(
              _selectedVariant.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5D4E7A),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: item.colorVariants.map((v) {
        final isSelected = v.id == _selectedVariant.id;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedVariant = v);
            widget.onVariantSelected?.call(v);
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: v.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF8B5E3C) : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusHint() {
    final bool isCurrent = _selectedVariant.imagePath == item.imagePath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCurrent ? '当前已是该配色' : '染色消耗：',
          style: TextStyle(
            color: isCurrent ? const Color(0xFFA78BFA) : const Color(0xFF8B5E3C),
            fontSize: 14,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (!isCurrent) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCostItem(Icons.colorize_rounded, '染料 x${_selectedVariant.dyeCost}'),
              const SizedBox(width: 16),
              _buildCostItem(Icons.monetization_on_rounded, '金币 x${_selectedVariant.goldCost}'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCostItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8B5E3C)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF8B5E3C), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            widget.onDyeConfirm?.call();
          },
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF9892B1), // 改为深紫色风格
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: const Text(
              '立即染色',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1A7B1),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
