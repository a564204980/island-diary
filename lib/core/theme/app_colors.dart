import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color glassBackground;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textBody;
  final Color border;
  final Color shadow;
  final Color lightShadow;

  const AppColorsExtension({
    required this.background,
    required this.glassBackground,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textBody,
    required this.border,
    required this.shadow,
    required this.lightShadow,
  });

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? glassBackground,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textBody,
    Color? border,
    Color? shadow,
    Color? lightShadow,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      glassBackground: glassBackground ?? this.glassBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textBody: textBody ?? this.textBody,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      lightShadow: lightShadow ?? this.lightShadow,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      lightShadow: Color.lerp(lightShadow, other.lightShadow, t)!,
    );
  }

  // 便利方法，供全应用统一获取
  static AppColorsExtension of(BuildContext context) {
    return Theme.of(context).extension<AppColorsExtension>() ?? light;
  }

  // --- 默认亮色主题 (Light) ---
  static final AppColorsExtension light = AppColorsExtension(
    background: const Color(0xFFE6F3F5),
    glassBackground: Colors.white.withValues(alpha: 0.85),
    cardBackground: Colors.white,
    textPrimary: const Color(0xFF4A4A4A),
    textSecondary: const Color(0xFF7A7A7A),
    textBody: const Color(0xFF5A3E28),
    border: const Color(0xFFE5E5EA),
    shadow: Colors.black.withValues(alpha: 0.1),
    lightShadow: Colors.black.withValues(alpha: 0.08),
  );

  // --- 默认暗色主题 (Dark) ---
  static final AppColorsExtension dark = AppColorsExtension(
    background: const Color(0xFF0F172A),
    glassBackground: const Color(0xFF2C2C2E).withValues(alpha: 0.85),
    cardBackground: const Color(0xFF2C2C2E),
    textPrimary: const Color(0xFFE5E5EA),
    textSecondary: const Color(0xFFC7C7CC),
    textBody: const Color(0xFFE5E5EA),
    border: const Color(0xFF38383A),
    shadow: Colors.black.withValues(alpha: 0.4),
    lightShadow: Colors.black.withValues(alpha: 0.3),
  );

  // --- 乐高主题 (Lego) - 高饱和/对比度 ---
  static final AppColorsExtension lego = AppColorsExtension(
    background: const Color(0xFFFFD500), // 乐高黄
    glassBackground: Colors.white.withValues(alpha: 0.95), // 偏实心的白色
    cardBackground: const Color(0xFFE3000F), // 乐高红
    textPrimary: const Color(0xFF000000), // 纯黑高对比
    textSecondary: const Color(0xFFFFFFFF), // 纯白
    textBody: const Color(0xFF0055BF), // 乐高蓝
    border: const Color(0xFF000000), // 积木硬线条边框
    shadow: Colors.black.withValues(alpha: 0.25),
    lightShadow: Colors.black.withValues(alpha: 0.15),
  );

  // --- 棉花岛主题 (Cotton) - 马卡龙/柔和色系 ---
  static final AppColorsExtension cotton = AppColorsExtension(
    background: const Color(0xFFFBE4E7), // 樱花粉背景
    glassBackground: Colors.white.withValues(alpha: 0.80),
    cardBackground: const Color(0xFFFFF6F7), // 柔和奶白卡片
    textPrimary: const Color(0xFF8B6B70), // 莫兰迪深粉褐
    textSecondary: const Color(0xFFAFA2A4), // 浅褐
    textBody: const Color(0xFF8B6B70),
    border: const Color(0xFFF2D5D9), // 淡粉边框
    shadow: const Color(0xFFD6C4C6).withValues(alpha: 0.5), // 柔和粉红阴影
    lightShadow: const Color(0xFFD6C4C6).withValues(alpha: 0.3),
  );
}
