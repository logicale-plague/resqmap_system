import 'package:flutter/material.dart';

class AppListItemCard extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isThreeLine;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final Color? leftBorderColor;
  final double leftBorderWidth;

  const AppListItemCard({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isThreeLine = false,
    this.contentPadding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.elevation = 2,
    this.leftBorderColor,
    this.leftBorderWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: contentPadding,
      leading: leading,
      title: title,
      subtitle: subtitle,
      isThreeLine: isThreeLine,
      trailing: trailing,
      onTap: onTap,
    );

    return Card(
      margin: margin,
      elevation: elevation,
      child: leftBorderColor == null
          ? tile
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: leftBorderColor!,
                    width: leftBorderWidth,
                  ),
                ),
              ),
              child: tile,
            ),
    );
  }
}
