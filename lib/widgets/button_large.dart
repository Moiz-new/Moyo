import 'package:flutter/material.dart';

class ButtonLarge extends StatelessWidget {
  final bool isBorder;
  final bool isIcon;
  final String label;
  final String iconPath;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Widget icon;

  /// color
  final Color borderColor;
  final Color labelColor;
  final Color backgroundColor;
  final Color iconColor;

  const ButtonLarge({
    super.key,
    this.isBorder = false,
    this.isIcon = false,
    this.label = 'Label',
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

    /// Colors
    this.borderColor = const Color(0xFFD2008F),
    this.labelColor = const Color(0xFFC0BEBD),
    this.backgroundColor = const Color(0xFFFD8405),
    this.iconColor = const Color(0xFFC0BEBD),
    this.borderRadius = 12,
    this.iconPath = "assets/icons/moyo_add_new_address.svg",
    this.onTap,
    this.icon = const Icon(Icons.account_circle_sharp),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: isBorder ? Border.all(color: borderColor, width: 1) : null,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            if (isIcon == true) icon,
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
