import 'dart:math';
import 'package:flutter/material.dart';

class AppSpacings {
  AppSpacings._();

  // --- Margin & Padding ---
  static const double pagePadding = 16.0;
  static const double cardPadding = 16.0;
  
  // --- Border Radius ---
  static final BorderRadius cardRadius = BorderRadius.circular(16.0);
  static final BorderRadius dialogRadius = BorderRadius.circular(28.0);
  static final BorderRadius alertRadius = BorderRadius.circular(24.0);

  // --- Layout Limits ---
  /// 用于获取弹窗的最大宽度，防止在 iPad 或 PC 等大屏幕上撑满全屏
  static double dialogMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 手机上距离两侧 40，平板/桌面端最大限制 400
    return min(screenWidth - 80, 400.0);
  }
}
