import 'package:flutter/material.dart';

class GlobalBackground extends StatelessWidget {
  const GlobalBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Colors.black,
                  Colors.black,
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFFE0EAFC),
                  Color(0xFFCFDEF3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
    );
  }
}
