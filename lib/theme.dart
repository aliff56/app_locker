import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kPrimaryColor = Color(0xFF5B2EFF);
const kBgColor = Color(0xFF162C65);
const kRadius = 20.0;
const kCardColor = Color(0xFF9FACDF);
const kDarkBgColor = Color(0xFF181A20);

ThemeData appTheme() {
  final textTheme = GoogleFonts.beVietnamProTextTheme(
    ThemeData.dark().textTheme,
  );
  return ThemeData(
    scaffoldBackgroundColor: kBgColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      brightness: Brightness.dark,
    ),
    textTheme: textTheme,
    primaryColor: kPrimaryColor,
    fontFamily: GoogleFonts.beVietnamPro().fontFamily,
    useMaterial3: true,
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kBgColor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
        backgroundColor: kCardColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
    cardColor: kCardColor,
    cardTheme: CardThemeData(
      color: kCardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgColor,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
    ),
  );
}

ThemeData appDarkTheme() {
  final textTheme = GoogleFonts.beVietnamProTextTheme(
    ThemeData.dark().textTheme,
  );
  return ThemeData(
    scaffoldBackgroundColor: kDarkBgColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      brightness: Brightness.dark,
    ),
    textTheme: textTheme,
    primaryColor: kPrimaryColor,
    fontFamily: GoogleFonts.beVietnamPro().fontFamily,
    useMaterial3: true,
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kBgColor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
    cardColor: kCardColor,
    cardTheme: CardThemeData(
      color: kCardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgColor,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kDarkBgColor,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Colors.white70,
    ),
  );
}
