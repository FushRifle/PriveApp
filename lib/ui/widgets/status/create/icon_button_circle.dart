import 'package:flutter/material.dart';

class IconButtonCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const IconButtonCircle({
    super.key,
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: iconColor,
            size: size * 0.43,
          ),
        ),
      ),
    );
  }
}