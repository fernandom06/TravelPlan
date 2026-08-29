import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_shell.dart';

/// Responsive container for the place form/details.
///
/// - < 800 dp: bottom sheet (~530 high, top corners 24, drag handle) that
///   lifts with the keyboard via `viewInsets`.
/// - >= 800 dp: right-anchored 400px panel with left corners 24 over a light
///   scrim, living inside the map's `Stack`.
///
/// The child is keyed with a [GlobalKey] so crossing the breakpoint reparents
/// the form element instead of recreating it — text controllers survive.
class PlaceFormContainer extends StatefulWidget {
  const PlaceFormContainer({super.key, required this.child});

  final Widget child;

  @override
  State<PlaceFormContainer> createState() => _PlaceFormContainerState();
}

class _PlaceFormContainerState extends State<PlaceFormContainer> {
  final GlobalKey _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isDesktopLayout(constraints.maxWidth)) {
          return _buildPanel(context);
        }
        return _buildSheet(context);
      },
    );
  }

  Widget _buildPanel(BuildContext context) {
    return Stack(
      children: [
        // Light scrim over the map; does not swallow map taps (closing the
        // form by tapping the map is handled by TravelMap itself).
        Positioned.fill(
          child: IgnorePointer(
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            key: const Key('place-form-panel'),
            width: 400,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              boxShadow: const [AppShadows.soft],
            ),
            child: KeyedSubtree(
              key: _childKey,
              child: SingleChildScrollView(child: widget.child),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheet(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        key: const Key('place-form-sheet'),
        height: 530,
        margin: EdgeInsets.only(bottom: viewInsets.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [AppShadows.soft],
        ),
        child: Column(
          children: [
            const _DragHandle(),
            Expanded(
              child: KeyedSubtree(
                key: _childKey,
                child: SingleChildScrollView(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('place-form-drag-handle'),
      height: 24,
      alignment: Alignment.center,
      child: Container(
        height: 6,
        width: 48,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: AppRadii.pill,
        ),
      ),
    );
  }
}