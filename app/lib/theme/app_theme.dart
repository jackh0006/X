import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const orange = Color(0xFFF97316);
  static const orangeDeep = Color(0xFFC2410C);
  static const orangeSoft = Color(0xFFFB923C);
  static const charcoal = Color(0xFF1C1917);

  static const _lightBg = Color(0xFFFFFDFB);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceAlt = Color(0xFFF7F2EE);
  static const _lightText = Color(0xFF1C1917);
  static const _lightMuted = Color(0xFF6E655F);
  static const _lightBorder = Color(0xFFECE4DE);

  static const _darkBg = Color(0xFF100E0D);
  static const _darkSurface = Color(0xFF201C1A);
  static const _darkSurfaceAlt = Color(0xFF2A2523);
  static const _darkText = Color(0xFFFAF7F4);
  static const _darkMuted = Color(0xFFB8AFA8);
  static const _darkBorder = Color(0xFF3A332F);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: orangeDeep,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFE3D0),
      onPrimaryContainer: Color(0xFF5A1A00),
      secondary: orange,
      onSecondary: charcoal,
      secondaryContainer: Color(0xFFFFE8D6),
      onSecondaryContainer: Color(0xFF4A1C00),
      tertiary: Color(0xFF4C5F45),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD6E8CB),
      onTertiaryContainer: Color(0xFF12200D),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: _lightSurface,
      onSurface: _lightText,
      surfaceContainerHighest: _lightSurfaceAlt,
      onSurfaceVariant: _lightMuted,
      outline: _lightBorder,
      outlineVariant: Color(0xFFF0EAE5),
      shadow: Color(0x14000000),
      scrim: Colors.black,
      inverseSurface: _lightText,
      onInverseSurface: _lightSurface,
      inversePrimary: orangeSoft,
    );
    return _build(
      scheme: scheme,
      background: _lightBg,
      surface: _lightSurface,
      surfaceAlt: _lightSurfaceAlt,
      text: _lightText,
      muted: _lightMuted,
      border: _lightBorder,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: orangeSoft,
      onPrimary: charcoal,
      primaryContainer: Color(0xFF5A2A0A),
      onPrimaryContainer: Color(0xFFFFE3D0),
      secondary: orange,
      onSecondary: charcoal,
      secondaryContainer: Color(0xFF4A2A12),
      onSecondaryContainer: Color(0xFFFFE8D6),
      tertiary: Color(0xFFA9C79F),
      onTertiary: Color(0xFF1A2A16),
      tertiaryContainer: Color(0xFF33452E),
      onTertiaryContainer: Color(0xFFD6E8CB),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: _darkSurface,
      onSurface: _darkText,
      surfaceContainerHighest: _darkSurfaceAlt,
      onSurfaceVariant: _darkMuted,
      outline: _darkBorder,
      outlineVariant: Color(0xFF2B2522),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _darkText,
      onInverseSurface: _darkBg,
      inversePrimary: orangeDeep,
    );
    return _build(
      scheme: scheme,
      background: _darkBg,
      surface: _darkSurface,
      surfaceAlt: _darkSurfaceAlt,
      text: _darkText,
      muted: _darkMuted,
      border: _darkBorder,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color text,
    required Color muted,
    required Color border,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: 'Inter',
          bodyColor: text,
          displayColor: text,
        )
        .copyWith(
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: -1.4,
            height: 1.05,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.1,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontFamily: 'Inter',
            height: 1.5,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Inter',
            height: 1.5,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: border),
    );

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: text,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        helperStyle: TextStyle(color: muted, height: 1.4),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: orange, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: charcoal,
          disabledBackgroundColor: surfaceAlt,
          disabledForegroundColor: muted,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: border),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.brightness == Brightness.dark
            ? _lightText
            : charcoal,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: orange.withValues(alpha: 0.20),
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.6,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: orangeDeep);
          }
          return IconThemeData(color: muted);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: orange.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(
          color: scheme.brightness == Brightness.dark ? orangeSoft : orangeDeep,
        ),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.4,
          color: text,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: muted,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.brightness == Brightness.dark
              ? _lightText
              : charcoal,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}
