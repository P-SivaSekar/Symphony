import 'package:flutter/material.dart';

class ColorUtils {
  static Color getColorFromId(String value) {
    int hash = 0;
    for (int i = 0; i < value.length; i++) {
      hash = value.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Convert to soft, premium, deep colors suitable for music player background
    final double h = (hash.abs() % 360).toDouble();
    final double s = 45.0 + (hash.abs() % 15); // 45% - 60% saturation
    final double l = 12.0 + (hash.abs() % 8);  // 12% - 20% lightness (premium dark shades)
    
    return HSLColor.fromAHSL(1.0, h, s / 100.0, l / 100.0).toColor();
  }

  static List<Color> getGradientFromSong(String id, String title) {
    final c1 = getColorFromId(id);
    final c2 = getColorFromId(title);
    return [
      c1,
      Color.alphaBlend(c2.withValues(alpha: 0.5), c1),
      const Color(0xFF020205),
    ];
  }
}
