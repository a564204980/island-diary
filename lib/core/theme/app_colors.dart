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
  final Color controlActive;
  final Color controlUnselected;
  final Color controlContainer;

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
    required this.controlActive,
    required this.controlUnselected,
    required this.controlContainer,
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
    Color? controlActive,
    Color? controlUnselected,
    Color? controlContainer,
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
      controlActive: controlActive ?? this.controlActive,
      controlUnselected: controlUnselected ?? this.controlUnselected,
      controlContainer: controlContainer ?? this.controlContainer,
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
      controlActive: Color.lerp(controlActive, other.controlActive, t)!,
      controlUnselected: Color.lerp(controlUnselected, other.controlUnselected, t)!,
      controlContainer: Color.lerp(controlContainer, other.controlContainer, t)!,
    );
  }

  // 便利方法，供全应用统一获取
  static AppColorsExtension of(BuildContext context) {
    return Theme.of(context).extension<AppColorsExtension>() ?? light;
  }

  // 根据岛屿主题与夜间模式智能计算当前 AppColorsExtension
  static AppColorsExtension current({required String themeId, required bool isNight}) {
    if (themeId == 'cotton_candy') {
      return isNight
          ? cotton.copyWith(
              textPrimary: Colors.white,
              textSecondary: Colors.white70,
              controlUnselected: Colors.white.withValues(alpha: 0.6),
              controlContainer: const Color(0xFF8676FF).withValues(alpha: 0.25),
            )
          : cotton;
    } else if (themeId == 'lego') {
      return lego;
    } else {
      return isNight ? dark : light;
    }
  }

  // --- 默认亮色主题 (Light) - 水蓝清爽风 ---
  static final AppColorsExtension light = AppColorsExtension(
    background: const Color(0xFFE6F3F5),
    glassBackground: Colors.white.withValues(alpha: 0.85),
    cardBackground: Colors.white,
    textPrimary: const Color(0xFF2C4A61),
    textSecondary: const Color(0xFF5A788F),
    textBody: const Color(0xFF2C4A61),
    border: const Color(0xFFD0E3ED),
    shadow: Colors.black.withValues(alpha: 0.1),
    lightShadow: Colors.black.withValues(alpha: 0.08),
    controlActive: const Color(0xFF2C4A61),
    controlUnselected: const Color(0xFF5A788F),
    controlContainer: const Color(0xFFFFFDF9).withValues(alpha: 0.85),
  );

  // --- 默认暗色主题 (Dark) - 夜间海风 ---
  static final AppColorsExtension dark = AppColorsExtension(
    background: const Color(0xFF0F172A),
    glassBackground: const Color(0xFF2C2C2E).withValues(alpha: 0.85),
    cardBackground: const Color(0xFF2C2C2E),
    textPrimary: const Color(0xFFE3F2FD),
    textSecondary: Colors.white70,
    textBody: const Color(0xFFE3F2FD),
    border: Colors.white.withValues(alpha: 0.08),
    shadow: Colors.black.withValues(alpha: 0.4),
    lightShadow: Colors.black.withValues(alpha: 0.3),
    controlActive: const Color(0xFFD4A373),
    controlUnselected: Colors.white.withValues(alpha: 0.5),
    controlContainer: Colors.black.withValues(alpha: 0.35),
  );

  // --- 乐高主题 (Lego) - 高饱和/活力积木 ---
  static final AppColorsExtension lego = AppColorsExtension(
    background: const Color(0xFFFFD500),
    glassBackground: Colors.white.withValues(alpha: 0.95),
    cardBackground: const Color(0xFFE3000F),
    textPrimary: const Color(0xFF000000),
    textSecondary: const Color(0xFF424242),
    textBody: const Color(0xFF0055BF),
    border: const Color(0xFF000000),
    shadow: Colors.black.withValues(alpha: 0.25),
    lightShadow: Colors.black.withValues(alpha: 0.15),
    controlActive: const Color(0xFFFFC100),
    controlUnselected: Colors.black.withValues(alpha: 0.5),
    controlContainer: Colors.black.withValues(alpha: 0.15),
  );

  // --- 棉花岛主题 (Cotton) - 柔和粉紫系 ---
  static final AppColorsExtension cotton = AppColorsExtension(
    background: const Color(0xFFFBE4E7),
    glassBackground: Colors.white.withValues(alpha: 0.80),
    cardBackground: const Color(0xFFFFF6F7),
    textPrimary: const Color(0xFF4E3A46),
    textSecondary: const Color(0xFF8D7A84),
    textBody: const Color(0xFF8B6B70),
    border: const Color(0xFFFFD1E1).withValues(alpha: 0.45),
    shadow: const Color(0xFFD6C4C6).withValues(alpha: 0.5),
    lightShadow: const Color(0xFFD6C4C6).withValues(alpha: 0.3),
    controlActive: const Color(0xFFFF94B8),
    controlUnselected: const Color(0xFF6F5E63).withValues(alpha: 0.6),
    controlContainer: const Color(0xFFFFCADB).withValues(alpha: 0.45),
  );
}
