import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? blurColor;
  final double blurSigmaX;
  final double blurSigmaY;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.blurColor,
    this.blurSigmaX = 8.0,
    this.blurSigmaY = 8.0,
    this.border,
    this.boxShadow,
    this.hasBlur = true,
  });

  final bool hasBlur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final effectiveBlurColor = blurColor ?? (isDark
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.2));

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBlurColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), width: 0.5),
      ),
      child: child,
    );

    if (hasBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY),
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: content,
    );
  }
}
