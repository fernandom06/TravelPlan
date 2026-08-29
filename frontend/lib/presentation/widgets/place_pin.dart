import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Teardrop map pin: a 32×32 square with three rounded corners rotated -45°,
/// a 2px white border and a white inner circle holding the category icon in
/// terracotta. The "new place" variant ([halo]) uses the accent tone and a
/// soft halo to stand out from saved places.
class PlacePin extends StatelessWidget {
  const PlacePin({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.halo = false,
  });

  final IconData icon;
  final Color color;
  final bool halo;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -math.pi / 4,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: halo
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
          ),
        ),
      ),
    );
  }
}