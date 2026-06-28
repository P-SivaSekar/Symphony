import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

Widget testScroll() {
  return TextScroll(
    'Long text',
    mode: TextScrollMode.endless,
    velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
    delayBefore: const Duration(seconds: 2),
    pauseBetween: const Duration(seconds: 2),
    style: const TextStyle(fontSize: 14),
    selectable: false,
  );
}
