import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/day_label.dart';
import '../../data/models/itinerary_item.dart';

/// Horizontally scrollable strip of day pills for the itinerary header.
///
/// The active pill is highlighted in [AppColors.primaryDeep] and the strip
/// auto-scrolls via [Scrollable.ensureVisible] so the selected pill always
/// stays in view. Each pill is a [DragTarget<ItineraryItem>] so hovering a
/// pill while dragging can switch the visible day and dropping assigns the
/// item to that day. Wrapped in a [Scrollbar] for desktop platforms.
///
/// When [counts] is provided it must match [days] in length; each pill then
/// shows how many items that day holds, so the strip doubles as a plan
/// overview.
class DayPillStrip extends StatefulWidget {
  const DayPillStrip({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDropOnDay,
    required this.onHoverStart,
    required this.onHoverEnd,
    this.counts,
    this.centered = false,
  });

  final List<DateTime> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final void Function(ItineraryItem item, DateTime day) onDropOnDay;
  final void Function(int index) onHoverStart;
  final VoidCallback onHoverEnd;

  /// Items assigned per day (same order and length as [days]). A pill with
  /// zero items omits the count. Null keeps the label without a count.
  final List<int>? counts;

  /// Whether the pill row is centered when it fits the viewport (desktop
  /// layouts). When false the pills start at the left edge.
  final bool centered;

  @override
  State<DayPillStrip> createState() => _DayPillStripState();
}

class _DayPillStripState extends State<DayPillStrip> {
  final ScrollController _scrollController = ScrollController();
  late List<GlobalKey> _pillKeys;

  @override
  void initState() {
    super.initState();
    _pillKeys = List.generate(widget.days.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(covariant DayPillStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days.length != widget.days.length) {
      _pillKeys = List.generate(widget.days.length, (_) => GlobalKey());
      return;
    }
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _revealSelected(widget.selectedIndex);
    }
  }

  void _revealSelected(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _pillKeys[index].currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Scrollbar(
        controller: _scrollController,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: widget.centered
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    for (var i = 0; i < widget.days.length; i++)
                      _DayPill(
                        key: _pillKeys[i],
                        index: i,
                        label: _pillLabel(index: i, day: widget.days[i]),
                        count: widget.counts?[i] ?? 0,
                        active: i == widget.selectedIndex,
                        day: widget.days[i],
                        onSelect: () => widget.onSelect(i),
                        onHoverStart: widget.onHoverStart,
                        onHoverEnd: widget.onHoverEnd,
                        onDropOnDay: widget.onDropOnDay,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _pillLabel({required int index, required DateTime day}) =>
      'Día ${index + 1} · ${dayLabel(day)}';
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    super.key,
    required this.index,
    required this.label,
    required this.count,
    required this.active,
    required this.day,
    required this.onSelect,
    required this.onHoverStart,
    required this.onHoverEnd,
    required this.onDropOnDay,
  });

  final int index;
  final String label;

  /// Items assigned to this day; rendered as a small badge instead of a
  /// third "· N" text segment so the label keeps a single rhythm.
  final int count;
  final bool active;
  final DateTime day;
  final VoidCallback onSelect;
  final void Function(int index) onHoverStart;
  final VoidCallback onHoverEnd;
  final void Function(ItineraryItem item, DateTime day) onDropOnDay;

  /// The badge swaps colors on the active pill so it keeps its contrast
  /// against the deep terracotta fill instead of melting into it.
  Widget? get _badge {
    if (count <= 0) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: active ? Colors.white : AppColors.primaryDeep,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Lora',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.primaryDeep : Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    return DragTarget<ItineraryItem>(
      onMove: (details) => onHoverStart(index),
      onLeave: (data) => onHoverEnd(),
      onAcceptWithDetails: (details) {
        onHoverEnd();
        onDropOnDay(details.data, day);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        // Button + selected so a screen reader announces the pill as a
        // selectable control ("Día 2 · 02 Jun, seleccionado, botón"); the
        // label itself comes from the pill text.
        return Semantics(
          button: true,
          selected: active,
          child: GestureDetector(
            onTap: onSelect,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                // Deep terracotta: white 13px text on [AppColors.primary] only
                // reaches ~2.9:1, which fails AA for small text outdoors.
                color: active
                    ? AppColors.primaryDeep
                    : AppColors.muted.withValues(alpha: 0.6),
                borderRadius: AppRadii.pill,
                border: highlighted
                    ? Border.all(color: AppColors.accent, width: 2)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? Colors.white : AppColors.text,
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 6), badge],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
