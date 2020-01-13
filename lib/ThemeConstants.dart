import 'package:flutter/material.dart';

class ThemeConstants {
  static final padding = 20.0;
  static final paddingHalved = 10.0;
  static final paddingQuarter = 5.0;

  static final cardColorNew = Color(0xFF0079C0); // for when a user has not selected any images for this card yet
  static final cardColorSelected = Colors.blueGrey; // for when a user has selected a file but not submitted it yet
  static final cardColorPending = Colors.blueGrey[700]; // for when a the file is pending verification
  static final cardColorError = Color(0xFFd32f2e); // for when a the file has failed verification
  static final cardColorPass = Color(0xFF2f932e); // for when a the file has passed verification
  static final cardColorInfo = Color(0xFF7D7D7D); // for when a the file has passed verification

  static getThemeData() {
    final MaterialColor primaryMaterialColor = const MaterialColor(
      0xFF0079C0,
      const <int, Color>{
        100: const Color(0xFF0079C0),
        200: const Color(0xFF0079C0),
        300: const Color(0xFF0079C0),
        400: const Color(0xFF0079C0),
        500: const Color(0xFF0079C0),
        600: const Color(0xFF0079C0),
        700: const Color(0xFF0079C0),
        800: const Color(0xFF0079C0),
        900: const Color(0xFF0079C0),
      },
    );



    return ThemeData(
      primarySwatch: primaryMaterialColor,
      secondaryHeaderColor: Colors.black,
      backgroundColor: Colors.grey[700],
      cardColor: Colors.blueGrey[50],
    );
  }
}