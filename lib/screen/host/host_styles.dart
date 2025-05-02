import 'package:flutter/material.dart';

class AppStyles {
  // Subtle gradient: white to off-white
  static const LinearGradient scaffoldGradient = LinearGradient(
    colors: [
      Color(0xFFF5F5F5), // Light grey (off-white)
      Color(0xFFFFFFFF), // Pure white
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Text styles
  static const TextStyle titleText = TextStyle(
    fontWeight: FontWeight.bold,
    color: Color(
        0xFF333333), // Darker grey for better contrast on white background
    fontSize: 20,
  );

  static const TextStyle participantText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF555555), // Slightly lighter grey
  );

  static const TextStyle awaitingText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF888888), // Medium grey for awaiting status
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle dialogTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF333333), // Dark grey for dialog titles
  );

  // Padding
  static const EdgeInsets defaultPadding = EdgeInsets.all(16);
  static const EdgeInsets textFieldPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  // Button style
  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor:
        const Color(0xFFD3AC70), // Soft gold, to match the white theme
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 8,
  );

  // Input field style
  static final InputDecoration textFieldDecoration = InputDecoration(
    hintStyle:
        const TextStyle(color: Color(0xFF888888)), // Medium grey for hint text
    filled: true,
    fillColor: Color(0xFFF7F7F7), // Light grey background for input fields
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: textFieldPadding,
  );

  // Dialog shape
  static ShapeBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  );

  // Message tile decoration
  static final BoxDecoration messageTileDecoration = BoxDecoration(
    color: Color(0xFFFAFAFA), // Very light grey background for message tiles
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Color(0xFFDDDDDD), // Soft shadow in light grey
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
}
