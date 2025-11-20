import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final bool outlined;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 50,
    this.borderRadius = 24,
    this.textStyle,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final start = const Color(AppConstants.gradientStartColorValue);
    final end = const Color(AppConstants.gradientEndColorValue);

    if (outlined) {
      return SizedBox(
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: start.withOpacity(0.9), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: Text(
            label,
            style: (textStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
                .copyWith(color: start),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [start, end]),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: Text(
            label,
            style: (textStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
                .copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}