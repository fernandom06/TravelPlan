import 'package:flutter/material.dart';

/// Two-column layout for wide screens.
///
/// The left column scrolls on its own ([SingleChildScrollView]) and is capped
/// at a comfortable reading width, centered when the column is wider; the
/// right column is handed the available height directly so it manages its own
/// scrolling (e.g. the day timeline [ListView]). The breakpoint decision
/// lives in the caller.
class ItineraryTwoColumnLayout extends StatelessWidget {
  const ItineraryTwoColumnLayout({
    super.key,
    required this.leftChild,
    required this.rightChild,
  });

  final Widget leftChild;
  final Widget rightChild;

  /// Max width of the scrollable left column so cards do not stretch across
  /// ultra-wide windows.
  static const double leftMaxWidth = 480;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: leftMaxWidth),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: leftChild,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: rightChild),
      ],
    );
  }
}
