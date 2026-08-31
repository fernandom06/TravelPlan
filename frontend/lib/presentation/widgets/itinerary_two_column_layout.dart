import 'package:flutter/material.dart';

/// Two-column layout for wide screens.
///
/// The left column scrolls on its own ([SingleChildScrollView]); the right
/// column is handed the available height directly so it manages its own
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: leftChild,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: rightChild),
      ],
    );
  }
}
