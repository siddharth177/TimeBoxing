import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brown100,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.brown20,
      onPrimaryContainer: AppColors.brown100,
      secondary: AppColors.green60,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.green10,
      onSecondaryContainer: AppColors.green80,
      tertiary: AppColors.orange40,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.orange10,
      onTertiaryContainer: AppColors.orange80,
      error: AppColors.orange40,
      onError: AppColors.white,
      errorContainer: AppColors.orange10,
      onErrorContainer: AppColors.orange80,
      surface: AppColors.white,
      onSurface: AppColors.brown100,
      surfaceContainerHighest: AppColors.brown10,
      onSurfaceVariant: AppColors.brown60,
      outline: AppColors.brown20,
      outlineVariant: AppColors.brown20,
      shadow: AppColors.brown100,
      scrim: AppColors.brown100,
      inverseSurface: AppColors.brown100,
      onInverseSurface: AppColors.white,
      inversePrimary: AppColors.brown40,
    ),
    scaffoldBg: AppColors.brown10,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.brown60,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.brown80,
      onPrimaryContainer: AppColors.brown20,
      secondary: AppColors.green60,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.green80,
      onSecondaryContainer: AppColors.green30,
      tertiary: AppColors.orange40,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.orange80,
      onTertiaryContainer: AppColors.orange20,
      error: AppColors.orange40,
      onError: AppColors.white,
      errorContainer: AppColors.orange80,
      onErrorContainer: AppColors.orange20,
      surface: AppColors.brown80,
      onSurface: AppColors.white,
      surfaceContainerHighest: AppColors.brown70,
      onSurfaceVariant: AppColors.brown20,
      outline: AppColors.brown70,
      outlineVariant: AppColors.brown80,
      shadow: AppColors.brown100,
      scrim: AppColors.brown100,
      inverseSurface: AppColors.brown20,
      onInverseSurface: AppColors.brown100,
      inversePrimary: AppColors.brown60,
    ),
    scaffoldBg: AppColors.brown100,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBg,
  }) {
    final base = brightness == Brightness.light
        ? ThemeData.light()
        : ThemeData.dark();
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: GoogleFonts.urbanistTextTheme(
        base.textTheme,
      ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.urbanist(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          textStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: const StadiumBorder(),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          textStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: const StadiumBorder(),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? AppColors.brown10
            : AppColors.brown80,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: scheme.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.green60
              : AppColors.gray40,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.green30
              : AppColors.gray20,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.green60
              : AppColors.transparent,
        ),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.green60
              : scheme.outline,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: GoogleFonts.urbanist(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.brown100
            : AppColors.white,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? (brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.brown100)
                : (brightness == Brightness.dark
                      ? AppColors.brown40
                      : AppColors.brown40),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.urbanist(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? (brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.brown100)
                : AppColors.brown40,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.brown100
            : AppColors.white,
        selectedIconTheme: IconThemeData(
          color: brightness == Brightness.dark
              ? AppColors.white
              : AppColors.brown100,
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.brown40,
          size: 24,
        ),
        selectedLabelTextStyle: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: brightness == Brightness.dark
              ? AppColors.white
              : AppColors.brown100,
        ),
        unselectedLabelTextStyle: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.brown40,
        ),
        indicatorColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
