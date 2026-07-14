import 'package:flutter/material.dart';
import 'package:island_diary/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme(String defaultFont) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFCDA661),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorsExtension.light.background,
      fontFamily: defaultFont,
      extensions: [AppColorsExtension.light],
    );

    return _applyCommonStyles(baseTheme, defaultFont, AppColorsExtension.light);
  }

  static ThemeData darkTheme(String defaultFont) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFCDA661),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorsExtension.dark.background,
      fontFamily: defaultFont,
      extensions: [AppColorsExtension.dark],
    );

    return _applyCommonStyles(baseTheme, defaultFont, AppColorsExtension.dark);
  }

  static ThemeData legoTheme(String defaultFont) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColorsExtension.lego.cardBackground,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorsExtension.lego.background,
      fontFamily: defaultFont,
      extensions: [AppColorsExtension.lego],
    );

    return _applyCommonStyles(baseTheme, defaultFont, AppColorsExtension.lego);
  }

  static ThemeData cottonTheme(String defaultFont) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColorsExtension.cotton.cardBackground,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorsExtension.cotton.background,
      fontFamily: defaultFont,
      extensions: [AppColorsExtension.cotton],
    );

    return _applyCommonStyles(baseTheme, defaultFont, AppColorsExtension.cotton);
  }

  static ThemeData _applyCommonStyles(ThemeData baseTheme, String font, AppColorsExtension colors) {
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        bodyColor: colors.textBody,
        displayColor: colors.textBody,
        fontFamily: font,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: false,
        backgroundColor: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
