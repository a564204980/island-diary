import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MomentsInteractionPopover extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isNight;

  const MomentsInteractionPopover({
    super.key,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onEdit,
    required this.onDelete,
    this.isNight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42, 
      decoration: BoxDecoration(
        color: isNight 
            ? const Color(0xFF26241E).withValues(alpha: 0.98) 
            : const Color(0xFF5D4037).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: isLiked ? '取消' : '赞',
            onTap: onLike,
            iconColor: isLiked ? const Color(0xFFF35555) : Colors.white,
          ),
          _buildDivider(),
          _buildItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: '回响',
            onTap: onComment,
          ),
          _buildDivider(),
          _buildItem(
            icon: Icons.edit_note_rounded,
            label: '编辑',
            onTap: onEdit,
          ),
          _buildDivider(),
          _buildItem(
            icon: Icons.delete_outline_rounded,
            label: '删除',
            onTap: onDelete,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms).moveX(begin: 20, end: 0, curve: Curves.easeOut);
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 0.5,
      height: 18,
      color: Colors.black.withValues(alpha: 0.2),
    );
  }
}
