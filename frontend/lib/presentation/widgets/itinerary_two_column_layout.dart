import 'package:flutter/material.dart';

/// Two-column layout for wide screens.
///
/// The whole content is capped at a comfortable width and centered so it does
/// not stretch across ultra-wide windows. The left column has a fixed width
/// and is stretched to the full available height so its panel fills the space
/// instead of hugging its cards; the child is expected to scroll its own
/// content when it overflows. The right column gets the remaining width and
/// the available height directly so it manages its own scrolling (e.g. the day
/// timeline [ListView]). The breakpoint decision lives in the caller.
///
/// The gutter grows with the window once the content hits [maxContentWidth],
/// using some of the otherwise empty side space to push the columns apart.
class ItineraryTwoColumnLayout extends StatelessWidget {
  const ItineraryTwoColumnLayout({
    super.key,
    required this.leftChild,
    required this.rightChild,
  });

  final Widget leftChild;
  final Widget rightChild;

  /// Fixed width of the left (unassigned places) column.
  static const double leftWidth = 340;

  /// Base gap between the two columns on narrow windows.
  static const double gutter = 24;

  /// Gap between the two columns once there is plenty of side space.
  static const double maxGutter = 104;

  /// Max width of the whole two-column content so cards do not stretch across
  /// ultra-wide windows.
  static const double maxContentWidth = 1100;

  /// Window width at which the gutter reaches [maxGutter]. The ramp starts at
  /// [maxContentWidth], when the centered content begins leaving side space.
  static const double gutterRampWidth = 1500;

  double _gutterFor(double availableWidth) {
    final t =
        ((availableWidth - maxContentWidth) /
                (gutterRampWidth - maxContentWidth))
            .clamp(0.0, 1.0);
    return gutter + (maxGutter - gutter) * t;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveGutter = _gutterFor(constraints.maxWidth);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Row(
              children: [
                SizedBox(
                  width: leftWidth,
                  child: SizedBox.expand(child: leftChild),
                ),
                SizedBox(width: effectiveGutter),
                Expanded(child: rightChild),
              ],
            ),
          ),
        );
      },
    );
  }
}
