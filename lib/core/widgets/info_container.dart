import 'package:flutter/material.dart';

/// A reusable styled container for displaying informational content.
///
/// Used throughout the app for status boxes, alerts, and informational panels.
/// Provides consistent styling with border, padding, and background color.
class InfoContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final double borderWidth;

  const InfoContainer({
    super.key,
    required this.child,
    this.backgroundColor = Colors.blue,
    this.borderColor = Colors.blue,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.borderWidth = 1,
  });

  /// Success info container (green)
  factory InfoContainer.success({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return InfoContainer(
      backgroundColor: Colors.green[50]!,
      borderColor: Colors.green,
      padding: padding,
      child: child,
    );
  }

  /// Error/warning info container (red)
  factory InfoContainer.error({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return InfoContainer(
      backgroundColor: Colors.red[50]!,
      borderColor: Colors.red,
      padding: padding,
      child: child,
    );
  }

  /// Warning info container (yellow/amber)
  factory InfoContainer.warning({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return InfoContainer(
      backgroundColor: Colors.yellow[50]!,
      borderColor: Colors.yellow[700]!,
      padding: padding,
      child: child,
    );
  }

  /// Info container (blue)
  factory InfoContainer.info({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return InfoContainer(
      backgroundColor: Colors.blue[50]!,
      borderColor: Colors.blue,
      padding: padding,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
