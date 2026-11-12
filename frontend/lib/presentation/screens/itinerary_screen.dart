import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/day_label.dart';
import '../../data/models/itinerary_item.dart';
import '../../data/models/itinerary_slot.dart';
import '../../data/models/place.dart';
import '../../data/models/trip.dart';
import '../controllers/itinerary_controller.dart';
import '../controllers/places_controller.dart';
import '../widgets/dashed_action_card.dart';
import '../widgets/day_pill_strip.dart';
import '../widgets/general_items_section.dart';
import '../widgets/itinerary_slot_section.dart';
import '../widgets/itinerary_two_column_layout.dart';
import '../widgets/offline_banner.dart';
import '../widgets/place_picker_dialog.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({
    super.key,
    required this.trip,
    required this.itineraryController,
    required this.placesController,
    required this.online,
    required this.baseUrl,
  });

  final Trip trip;
  final ItineraryController itineraryController;
  final PlacesController placesController;
  final ValueNotifier<bool> online;
  final String baseUrl;

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen>
    with SingleTickerProviderStateMixin {
  static const _dayHoverDelay = Duration(milliseconds: 500);
  static const _twoColumnBreakpoint = 900.0;
  static const _dayTimelineMaxWidth = 680.0;

  late TabController _tabController;
  late List<DateTime> _days;
  Timer? _dayHoverTimer;

  @override
  void initState() {
    super.initState();
    _days = _deriveDays(widget.trip);
    _tabController = _createTabController();
    _load();
  }

  TabController _createTabController() {
    final controller = TabController(length: _days.length, vsync: this);
    controller.addListener(_onTabChanged);
    return controller;
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ItineraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newDays = _deriveDays(widget.trip);
    if (newDays.length != _days.length ||
        widget.trip.startDate != oldWidget.trip.startDate) {
      _days = newDays;
      _tabController.dispose();
      _tabController = _createTabController();
      _load();
    }
  }

  @override
  void dispose() {
    _dayHoverTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  static List<DateTime> _deriveDays(Trip trip) {
    final count = trip.endDate.difference(trip.startDate).inDays + 1;
    return [
      for (var i = 0; i < count; i++) trip.startDate.add(Duration(days: i)),
    ];
  }

  Future<void> _load() async {
    try {
      await widget.itineraryController.loadItinerary(widget.trip);
    } catch (e) {
      if (!mounted) return;
      // With an empty itinerary the error view takes over instead of letting
      // the failure masquerade as an empty plan; with visible items the
      // screen keeps them usable and just notifies.
      if (widget.itineraryController.value.items.isEmpty) return;
      _showNotice(
        'No se pudo actualizar el itinerario. Revisa tu conexión.',
        _load,
      );
    }
  }

  /// Runs an optimistic operation; on success any lingering error snackbar
  /// is dismissed, on failure a persistent one offers a real retry.
  Future<void> _attempt(Future<void> Function() operation) async {
    try {
      await operation();
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (_) {
      _showSaveError(operation);
    }
  }

  void _showSaveError(Future<void> Function() retry) {
    _showNotice('No se pudo guardar el cambio. Revisa tu conexión.', retry);
  }

  void _showNotice(String message, Future<void> Function() retry) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          // Stays until the user retries or dismisses it: on an unreliable
          // field connection a 4-second snackbar would vanish unheard.
          duration: const Duration(days: 1),
          showCloseIcon: true,
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: () => unawaited(_attempt(retry)),
          ),
        ),
      );
  }

  void _moveItem(int itemId, DateTime? day, ItinerarySlot? slot, int index) {
    unawaited(
      _attempt(
        () => widget.itineraryController.moveItem(itemId, day, slot, index),
      ),
    );
  }

  void _dropOnDay(ItineraryItem item, DateTime day) {
    final morningCount = widget.itineraryController.value.items
        .where((i) => i.dayDate == day && i.slot == ItinerarySlot.morning)
        .length;
    _moveItem(item.id, day, ItinerarySlot.morning, morningCount);
  }

  void _scheduleDayOpen(int index) {
    _dayHoverTimer?.cancel();
    _dayHoverTimer = Timer(_dayHoverDelay, () {
      if (mounted && _tabController.index != index) {
        _tabController.animateTo(index);
      }
    });
  }

  void _cancelDayOpen() {
    _dayHoverTimer?.cancel();
    _dayHoverTimer = null;
  }

  void _removeItem(int itemId) {
    unawaited(
      _attempt(() => widget.itineraryController.removeItem(itemId)),
    );
  }

  void _addPlace(Place place) {
    unawaited(_attempt(() => widget.itineraryController.addPlace(place)));
  }

  Future<void> _openPicker() async {
    final places = widget.placesController.value.places;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => PlacePickerDialog(
        places: places,
        onPlaceSelected: (placeId) {
          for (final place in places) {
            if (place.id == placeId) {
              _addPlace(place);
              return;
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.trip.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontSize: 28),
        ),
        centerTitle: false,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: widget.online,
        builder: (_, isOnline, _) => Column(
          children: [
            if (!isOnline) const OfflineBanner(),
            Expanded(
              child: ValueListenableBuilder<ItineraryState>(
                valueListenable: widget.itineraryController,
                builder: (_, state, _) {
                  final content = _buildContent(state);
                  if (!state.isMutating) return content;
                  return Column(
                    children: [
                      Semantics(
                        label: 'Guardando cambios',
                        child: const LinearProgressIndicator(
                          minHeight: 2,
                          color: AppColors.primary,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ItineraryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadError != null && state.items.isEmpty) {
      return _buildLoadError();
    }
    final general = state.items.where((i) => i.isUnassigned).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _twoColumnBreakpoint) {
          return _buildTwoColumn(state, general);
        }
        return _buildStacked(state, general);
      },
    );
  }

  /// Explicit failure state for a load that left the itinerary empty: it
  /// must be impossible to mistake a network failure for an empty plan.
  Widget _buildLoadError() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar el itinerario',
              style: textTheme.titleMedium?.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              'Comprueba tu conexión con el servidor.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => unawaited(_load()),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStacked(ItineraryState state, List<ItineraryItem> general) {
    return Column(
      children: [
        _buildDayPillStrip(centered: false, state: state),
        _buildGeneralSection(general),
        Expanded(child: _buildDayTimeline(state, centered: false)),
      ],
    );
  }

  Widget _buildTwoColumn(ItineraryState state, List<ItineraryItem> general) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDayPillStrip(centered: true, state: state),
        Expanded(
          child: ItineraryTwoColumnLayout(
            leftChild: _buildGeneralSection(general, vertical: true),
            rightChild: _buildDayTimeline(state, centered: true),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSection(
    List<ItineraryItem> general, {
    bool vertical = false,
  }) {
    return GeneralItemsSection(
      layout: vertical
          ? GeneralItemsLayout.vertical
          : GeneralItemsLayout.carousel,
      items: general,
      onAcceptItem: (item, index) => _moveItem(item.id, null, null, index),
      onDeleteItem: _removeItem,
      onOpenItem: _openMoveSheet,
      trailing: DashedActionCard(
        label: '¿Añadimos un lugar?',
        onTap: _openPicker,
        compact: true,
      ),
    );
  }

  Widget _buildDayPillStrip({
    required bool centered,
    required ItineraryState state,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.muted)),
      ),
      child: DayPillStrip(
        days: _days,
        selectedIndex: _tabController.index,
        counts: [
          for (final day in _days)
            state.items.where((item) => item.dayDate == day).length,
        ],
        onSelect: (index) => _tabController.animateTo(index),
        onDropOnDay: _dropOnDay,
        onHoverStart: _scheduleDayOpen,
        onHoverEnd: _cancelDayOpen,
        centered: centered,
      ),
    );
  }

  Widget _buildDayTimeline(ItineraryState state, {required bool centered}) {
    return TabBarView(
      controller: _tabController,
      children: [
        for (final day in _days)
          _daySections(day, state.items, centered: centered),
      ],
    );
  }

  Widget _daySections(
    DateTime day,
    List<ItineraryItem> items, {
    bool centered = false,
  }) {
    Widget section(ItinerarySlot slot) {
      final slotItems =
          items.where((i) => i.dayDate == day && i.slot == slot).toList()
            ..sort((a, b) => a.position.compareTo(b.position));
      return ItinerarySlotSection(
        title: slot.label,
        slot: slot,
        items: slotItems,
        isLast: slot == ItinerarySlot.night,
        onAcceptItem: (item, slot, index) =>
            _moveItem(item.id, day, slot, index),
        onDeleteItem: _removeItem,
        onOpenItem: _openMoveSheet,
      );
    }

    final sections = [
      section(ItinerarySlot.morning),
      section(ItinerarySlot.afternoon),
      section(ItinerarySlot.night),
    ];
    if (!centered) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: sections,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _dayTimelineMaxWidth),
              child: Column(children: sections),
            ),
          ),
        ),
      ),
    );
  }

  /// Non-drag alternative for reordering: a plain tap on a card opens a
  /// sheet with explicit move targets plus remove, so touch, keyboard and
  /// screen-reader users all have a path that is not a drag gesture.
  void _openMoveSheet(ItineraryItem item) {
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Mover "${item.place.name}"',
                  style: textTheme.titleMedium?.copyWith(color: AppColors.text),
                ),
              ),
              for (final target in _moveTargets(item))
                ListTile(
                  leading: Icon(target.icon, color: AppColors.primary),
                  title: Text(target.label),
                  subtitle: target.subtitle == null
                      ? null
                      : Text(target.subtitle!),
                  onTap: () =>
                      _applyMoveFromSheet(sheetContext, item, target),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Quitar del itinerario'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeItem(item.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<_MoveTarget> _moveTargets(ItineraryItem item) {
    final targets = <_MoveTarget>[];
    final assignedDay = item.dayDate;
    if (assignedDay != null) {
      targets.add(
        const _MoveTarget('Por asignar', Icons.archive_outlined),
      );
    }
    final targetDay = assignedDay ?? _days[_tabController.index];
    final daySubtitle =
        'Día ${_days.indexOf(targetDay) + 1} · ${dayLabel(targetDay)}';
    for (final slot in ItinerarySlot.values) {
      if (assignedDay != null && slot == item.slot) continue;
      targets.add(
        _MoveTarget(
          slot.label,
          ItinerarySlotSection.iconFor(slot),
          day: targetDay,
          slot: slot,
          subtitle: assignedDay == null ? daySubtitle : null,
        ),
      );
    }
    return targets;
  }

  void _applyMoveFromSheet(
    BuildContext sheetContext,
    ItineraryItem item,
    _MoveTarget target,
  ) {
    Navigator.pop(sheetContext);
    final items = widget.itineraryController.value.items;
    final count = items
        .where(
          (other) =>
              other.dayDate == target.day && other.slot == target.slot,
        )
        .length;
    _moveItem(item.id, target.day, target.slot, count);
  }
}

/// One destination row inside the move sheet. [day]/[slot] are null for the
/// unassigned container; [daySubtitle] labels a cross-day destination.
class _MoveTarget {
  const _MoveTarget(this.label, this.icon, {this.day, this.slot, this.subtitle});

  final String label;
  final IconData icon;
  final DateTime? day;
  final ItinerarySlot? slot;
  final String? subtitle;
}
