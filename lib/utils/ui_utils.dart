import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UIUtils {
  static void showPopup(BuildContext context, String msg) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (ctx.mounted) Navigator.pop(ctx);
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          alignment: Alignment.bottomCenter,
          insetPadding: const EdgeInsets.only(bottom: 140, left: 24, right: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF24243E).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
            ),
          ),
        );
      },
    );
  }
}
