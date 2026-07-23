import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16.0),
        border: border ?? Border.all(color: AppColors.outlineVariant.withOpacity(0.3), width: 1.0),
        boxShadow: boxShadow ??
            const [
              BoxShadow(
                color: Color(0x0D1A1C2E),
                blurRadius: 30.0,
                offset: Offset(0, 10.0),
              ),
            ],
      ),
      child: child,
    );
  }
}
