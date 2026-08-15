import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFCFDC28);
  static const Color secondary = Color(0xFF12667F);
  static const Color tertiary = Color(0xFFC65B5B);
  static const Color alternate = Color(0xFFD0D0D0);
  static const Color primaryBackground = Color(0xFFCFDC28);
  static const Color secondaryBackground = Color(0xFFD0D0D0);
  static const Color primaryText = Color(0xFF12667F);
  static const Color secondaryText = Color(0xFF6B7A8A);
  static const Color accent1 = Color(0xFF12667F);
  static const Color accent2 = Color(0xFF4A4A4A);
  static const Color accent3 = Color(0xFF7A9C9C);
  static const Color accent4 = Color(0xFFADB5BD);
  static const Color success = Color(0xFF329B47);
  static const Color warning = Color(0xFFDAA520);
  static const Color error = Color(0xFFC65B5B);
  static const Color info = Color(0xFF2680EB);
  static const Color onPrimary = Color(0xFF12667F);
  static const Color onSecondary = Color(0xFFFFFFFF);
}

class AppTheme {
  static AppThemeData of(BuildContext context) {
    return AppThemeData(context);
  }

  static ThemeData get lightTheme => _lightTheme;
  static ThemeData get darkTheme => _darkTheme;

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFCFDC28),
      secondary: Color(0xFF12667F),
      tertiary: Color(0xFFC65B5B),
      error: Color(0xFFC65B5B),
      surface: Color(0xFFD0D0D0),
      onPrimary: Color(0xFF12667F),
      onSecondary: Color(0xFFFFFFFF),
      onError: Color(0xFFFFFFFF),
      onSurface: Color(0xFF12667F),
    ),
    scaffoldBackgroundColor: const Color(0xFFCFDC28),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF12667F),
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 2,
      centerTitle: false,
    ),
    textTheme: GoogleFonts.getTextTheme(
      'Plus Jakarta Sans',
      TextTheme(
        displayLarge: GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 56, height: 1.1),
        displayMedium: GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 44, height: 1.15),
        displaySmall: GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 36, height: 1.2),
        headlineLarge: GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 32, height: 1.2),
        headlineMedium: GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 26, height: 1.25),
        headlineSmall: GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 24, height: 1.3),
        titleLarge: GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 20, height: 1.3),
        titleMedium: GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 17, height: 1.4),
        titleSmall: GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
        bodyLarge: GoogleFonts.getFont('Inter', fontWeight: FontWeight.w400, fontSize: 16, height: 1.5),
        bodyMedium: GoogleFonts.getFont('Inter', fontWeight: FontWeight.w400, fontSize: 14, height: 1.5),
        bodySmall: GoogleFonts.getFont('Inter', fontWeight: FontWeight.w400, fontSize: 12, height: 1.4),
        labelLarge: GoogleFonts.getFont('Inter', fontWeight: FontWeight.w600, fontSize: 14, height: 1.3),
        labelMedium: GoogleFonts.getFont('Inter', fontWeight: FontWeight.w600, fontSize: 12, height: 1.3),
        labelSmall: GoogleFonts.getFont('Inter', fontWeight: FontWeight.w600, fontSize: 10, height: 1.2),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE1E1E1),
      thickness: 1,
      space: 0,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF5C9E9E),
      secondary: Color(0xFF7A9C9C),
      tertiary: Color(0xFFFF7F00),
      error: Color(0xFFFF5252),
      surface: Color(0xFF0F182A),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onError: Color(0xFFFFFFFF),
      onSurface: Color(0xFFFFF9F9),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F182A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D6B66),
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 2,
    ),
    textTheme: GoogleFonts.getTextTheme(
      'Plus Jakarta Sans',
      TextTheme(
        bodyMedium: GoogleFonts.getFont('Inter', fontWeight: FontWeight.w400, fontSize: 14, height: 1.5, color: const Color(0xFFFFF9F9)),
        bodySmall: GoogleFonts.getFont('Inter', fontWeight: FontWeight.w400, fontSize: 12, height: 1.4, color: const Color(0xFFFFF9F9)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE1E1E1),
      thickness: 1,
      space: 0,
    ),
  );
}

class AppThemeData {
  final BuildContext context;
  AppThemeData(this.context);

  ThemeData get theme => Theme.of(context);

  Color get primary => const Color(0xFFCFDC28);
  Color get secondary => const Color(0xFF12667F);
  Color get tertiary => const Color(0xFFC65B5B);
  Color get alternate => const Color(0xFFD0D0D0);
  Color get primaryBackground => const Color(0xFFCFDC28);
  Color get secondaryBackground => const Color(0xFFD0D0D0);
  Color get primaryText => const Color(0xFF12667F);
  Color get secondaryText => const Color(0xFF6B7A8A);
  Color get accent1 => const Color(0xFF12667F);
  Color get accent2 => const Color(0xFF4A4A4A);
  Color get accent3 => const Color(0xFF7A9C9C);
  Color get accent4 => const Color(0xFFADB5BD);
  Color get success => const Color(0xFF329B47);
  Color get warning => const Color(0xFFDAA520);
  Color get error => const Color(0xFFC65B5B);
  Color get info => const Color(0xFF2680EB);
  Color get onPrimary => const Color(0xFF12667F);
  Color get onSecondary => const Color(0xFFFFFFFF);

  TextStyle get displayLarge => GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 56, height: 1.1);
  TextStyle get displayMedium => GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 44, height: 1.15);
  TextStyle get displaySmall => GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 36, height: 1.2);
  TextStyle get headlineLarge => GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 32, height: 1.2);
  TextStyle get headlineMedium => GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 26, height: 1.25);
  TextStyle get headlineSmall => GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 24, height: 1.3);
  TextStyle get titleLarge => GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 20, height: 1.3);
  TextStyle get titleMedium => GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 17, height: 1.4);
  TextStyle get titleSmall => GoogleFonts.getFont('Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 14, height: 1.4);
  TextStyle get bodyLarge => GoogleFonts.getFont('Inter', fontWeight: FontWeight.w400, fontSize: 16, height: 1.5);
  TextStyle get bodyMedium => GoogleFonts.getFont('Inter', fontWeight: FontWeight.w400, fontSize: 14, height: 1.5);
  TextStyle get bodySmall => GoogleFonts.getFont('Inter', fontWeight: FontWeight.w400, fontSize: 12, height: 1.4);
  TextStyle get labelLarge => GoogleFonts.getFont('Inter', fontWeight: FontWeight.w600, fontSize: 14, height: 1.3);
  TextStyle get labelMedium => GoogleFonts.getFont('Inter', fontWeight: FontWeight.w600, fontSize: 12, height: 1.3);
  TextStyle get labelSmall => GoogleFonts.getFont('Inter', fontWeight: FontWeight.w600, fontSize: 10, height: 1.2);
}
