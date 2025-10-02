import 'package:flutter/material.dart';

class Oval extends StatelessWidget {
  const Oval({
    super.key,
    required this.icon,
    required this.width,
    this.height = 50,
    this.backgroundColor = const Color(0xFF419C9C),
    this.iconColor = Colors.white,
    this.iconSize = 28,
    this.onTap,
  });

  final IconData icon;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: const LinearGradient(
            colors: [Color(0xFF419C9C), Color(0xFF2D6F6F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}