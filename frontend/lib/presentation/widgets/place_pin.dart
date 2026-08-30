import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

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

/// Wraps a map pin so hovering it (desktop with a mouse) reveals a small
/// sketchbook-style label with the place name. Taps pass through to [child].
class PinHoverTooltip extends StatefulWidget {
  const PinHoverTooltip({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<PinHoverTooltip> createState() => _PinHoverTooltipState();
}

class _PinHoverTooltipState extends State<PinHoverTooltip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_hovering)
            Positioned(
              top: -34,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: double.infinity,
                  fit: OverflowBoxFit.deferToChild,
                  alignment: Alignment.topCenter,
                  child: Container(
                    key: const Key('place-pin-tooltip'),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.8),
                      borderRadius: AppRadii.pill,
                      boxShadow: const [AppShadows.soft],
                    ),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
