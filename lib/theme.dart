import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kPrimaryColor = Color(0xFF5B2EFF);
const kBgColor = Color(0xFFF4F5FA);
const kRadius = 20.0;
const kDarkBgColor = Color(0xFF181A20);
const kDarkCardColor = Color(0xFF23243A);

ThemeData appTheme() {
  final textTheme = GoogleFonts.poppinsTextTheme();
  return ThemeData(
    scaffoldBackgroundColor: kBgColor,
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
    textTheme: textTheme,
    primaryColor: kPrimaryColor,
    fontFamily: GoogleFonts.poppins().fontFamily,
    useMaterial3: true,
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
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
  );
}

ThemeData appDarkTheme() {
  final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);
  return ThemeData(
    scaffoldBackgroundColor: kDarkBgColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      brightness: Brightness.dark,
    ),
    textTheme: textTheme,
    primaryColor: kPrimaryColor,
    fontFamily: GoogleFonts.poppins().fontFamily,
    useMaterial3: true,
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
    cardTheme: CardThemeData(
      color: kDarkCardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkBgColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kDarkBgColor,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Colors.white70,
    ),
  );
}
