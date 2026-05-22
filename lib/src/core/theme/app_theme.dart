import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const seed = Color(0xFF1E8E5A);
    const accent = Color(0xFFE86F4A);

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: seed,
      secondary: accent,
      surface: const Color(0xFFF8FAF7),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAF7),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFFF8FAF7),
        foregroundColor: Color(0xFF17201B),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDE5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDE5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: seed, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: seed.withOpacity(0.12),
      ),
      fontFamily: null,
      visualDensity: VisualDensity.standard,
      extensions: const <ThemeExtension<dynamic>>[
        AppExtraColors(
          warning: Color(0xFFFFB020),
          success: Color(0xFF1E8E5A),
          danger: Color(0xFFC83A2B),
          muted: Color(0xFF66736B),
        ),
      ],
    );
  }
}

class AppExtraColors extends ThemeExtension<AppExtraColors> {
  const AppExtraColors({
    required this.warning,
    required this.success,
    required this.danger,
    required this.muted,
  });

  final Color warning;
  final Color success;
  final Color danger;
  final Color muted;

  @override
  ThemeExtension<AppExtraColors> copyWith({
    Color? warning,
    Color? success,
    Color? danger,
    Color? muted,
  }) {
    return AppExtraColors(
      warning: warning ?? this.warning,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      muted: muted ?? this.muted,
    );
  }

  @override
  ThemeExtension<AppExtraColors> lerp(
    covariant ThemeExtension<AppExtraColors>? other,
    double t,
  ) {
    if (other is! AppExtraColors) {
      return this;
    }

    return AppExtraColors(
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      success: Color.lerp(success, other.success, t) ?? success,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
    );
  }
}

extension MoneyText on num {
  String get money => '${AppConstants.currency} ${toStringAsFixed(2)}';
}
