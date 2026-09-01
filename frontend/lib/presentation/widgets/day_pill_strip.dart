import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/itinerary_item.dart';

/// Horizontally scrollable strip of day pills for the itinerary header.
///
/// The active pill is highlighted in [AppColors.primary] and the strip
/// auto-scrolls via [Scrollable.ensureVisible] so the selected pill always
/// stays in view. Each pill is a [DragTarget<ItineraryItem>] so hovering a
/// pill while dragging can switch the visible day and dropping assigns the
/// item to that day. Wrapped in a [Scrollbar] for desktop platforms.
class DayPillStrip extends StatefulWidget {
  const DayPillStrip({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDropOnDay,
    required this.onHoverStart,
    required this.onHoverEnd,
    this.centered = false,
  });

  final List<DateTime> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final void Function(ItineraryItem item, DateTime day) onDropOnDay;
  final void Function(int index) onHoverStart;
  final VoidCallback onHoverEnd;

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        label:
                            'Día ${i + 1} · ${_dayMonthLabel(widget.days[i])}',
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

  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static String _dayMonthLabel(DateTime day) =>
      '${_twoDigits(day.day)} ${_months[day.month - 1]}';

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    super.key,
    required this.index,
    required this.label,
    required this.active,
    required this.day,
    required this.onSelect,
    required this.onHoverStart,
    required this.onHoverEnd,
    required this.onDropOnDay,
  });

  final int index;
  final String label;
  final bool active;
  final DateTime day;
  final VoidCallback onSelect;
  final void Function(int index) onHoverStart;
  final VoidCallback onHoverEnd;
  final void Function(ItineraryItem item, DateTime day) onDropOnDay;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItineraryItem>(
      onMove: (details) => onHoverStart(index),
      onLeave: (data) => onHoverEnd(),
      onAcceptWithDetails: (details) {
        onHoverEnd();
        onDropOnDay(details.data, day);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary
                  : AppColors.muted.withValues(alpha: 0.6),
              borderRadius: AppRadii.pill,
              border: highlighted
                  ? Border.all(color: AppColors.accent, width: 2)
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? Colors.white : AppColors.text,
              ),
            ),
          ),
        );
      },
    );
  }
}
