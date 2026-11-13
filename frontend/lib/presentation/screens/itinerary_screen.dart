import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/day_label.dart';
import '../../data/models/itinerary_item.dart';
import '../../data/models/itinerary_slot.dart';
import '../../data/models/place.dart';
import '../../data/models/trip.dart';
import '../controllers/itinerary_controller.dart';
import '../controllers/itinerary_drag_session.dart';
import '../controllers/places_controller.dart';
import '../widgets/day_pill_strip.dart';
import '../widgets/error_notice.dart';
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

  /// One drag session for the whole screen: every section shares it so only
  /// one preview hole is visible and it is cleared when the drag ends.
  final ItineraryDragSession _dragSession = ItineraryDragSession();

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
    _dragSession.dispose();
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
      showErrorNotice(
        context,
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
    showErrorNotice(
      context,
      'No se pudo guardar el cambio. Revisa tu conexión.',
      retry,
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
    // El drop en la pill de día termina el arrastre fuera de toda sección.
    _dragSession.end();
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

  /// Removes an item and offers "Deshacer" in a snackbar: quitting a place
  /// by accident must be reversible, not a delete-then-recreate chore. The
  /// removed instance (with its day/slot/position) feeds the undo.
  Future<void> _removeItem(int itemId) async {
    final controller = widget.itineraryController;
    ItineraryItem? removed;
    try {
      removed = await controller.removeItem(itemId);
    } catch (_) {
      _showSaveError(() => controller.removeItem(itemId));
      return;
    }
    final removedItem = removed;
    if (removedItem == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${removedItem.place.name}" quitado del itinerario'),
          // Long enough to read the place name and react; shorter than the
          // persistent error snackbars, which stay until dismissed.
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () =>
                unawaited(_attempt(() => controller.restoreItem(removedItem))),
          ),
        ),
      );
  }

  void _addPlace(Place place, {DateTime? day, ItinerarySlot? slot}) {
    unawaited(
      _attempt(
        () => widget.itineraryController.addPlace(place, day: day, slot: slot),
      ),
    );
  }

  /// Opens the place picker. With [day]/[slot] the picked places go straight
  /// to that container (empty-slot tap); without, they land unassigned.
  Future<void> _openPicker({DateTime? day, ItinerarySlot? slot}) async {
    final places = widget.placesController.value.places;
    final subtitle = day == null || slot == null
        ? null
        : '${slot.label} · Día ${_days.indexOf(day) + 1} · ${dayLabel(day)}';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => PlacePickerDialog(
        places: places,
        subtitle: subtitle,
        onPlaceSelected: (placeId) {
          for (final place in places) {
            if (place.id == placeId) {
              _addPlace(place, day: day, slot: slot);
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
        ),
        centerTitle: false,
      ),
      // Thumb-zone entry for the picker: adding a place is the most common
      // action on this screen, and it is the single add affordance — the
      // general section no longer duplicates it with an inline card.
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'itinerary-add-fab',
        onPressed: () => unawaited(_openPicker()),
        icon: const Icon(Icons.add),
        label: const Text('Añadir lugar'),
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
    // The FAB owns the add affordance; the section keeps only its own
    // drag/drop and move-sheet entry points.
    return GeneralItemsSection(
      layout: vertical
          ? GeneralItemsLayout.vertical
          : GeneralItemsLayout.carousel,
      dragSession: _dragSession,
      items: general,
      onAcceptItem: (item, index) => _moveItem(item.id, null, null, index),
      onDeleteItem: _removeItem,
      onOpenItem: _openMoveSheet,
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
        day: day,
        dragSession: _dragSession,
        title: slot.label,
        slot: slot,
        items: slotItems,
        isLast: slot == ItinerarySlot.night,
        dayLabel: 'Día ${_days.indexOf(day) + 1} · ${dayLabel(day)}',
        onAcceptItem: (item, slot, index) =>
            _moveItem(item.id, day, slot, index),
        onDeleteItem: _removeItem,
        onOpenItem: _openMoveSheet,
        onAddPlace: () => unawaited(_openPicker(day: day, slot: slot)),
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
  /// sheet with a day selector plus per-slot targets and remove, so touch,
  /// keyboard and screen-reader users all have a path that is not a drag
  /// gesture — and moving to *any* day needs no drag either.
  void _openMoveSheet(ItineraryItem item) {
    final items = widget.itineraryController.value.items;
    int countIn(DateTime? day, ItinerarySlot? slot) => items
        .where((other) => other.dayDate == day && other.slot == slot)
        .length;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return _MoveSheet(
          item: item,
          days: _days,
          initialDay: item.dayDate ?? _days[_tabController.index],
          onMove: (day, slot) {
            Navigator.pop(sheetContext);
            _moveItem(item.id, day, slot, countIn(day, slot));
          },
          onRemove: () {
            Navigator.pop(sheetContext);
            unawaited(_removeItem(item.id));
          },
        );
      },
    );
  }
}

/// Move sheet for one itinerary item: a day selector on top (same "Día N ·
/// dd Mmm" vocabulary as the pill strip) and one target row per slot of the
/// selected day, plus "Por asignar" and remove. Stateless regarding the
/// controller — it reports the chosen target through callbacks.
class _MoveSheet extends StatefulWidget {
  const _MoveSheet({
    required this.item,
    required this.days,
    required this.initialDay,
    required this.onMove,
    required this.onRemove,
  });

  final ItineraryItem item;
  final List<DateTime> days;
  final DateTime initialDay;
  final void Function(DateTime? day, ItinerarySlot? slot) onMove;
  final VoidCallback onRemove;

  @override
  State<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends State<_MoveSheet> {
  late DateTime _selectedDay = widget.initialDay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final item = widget.item;
    final dayIndex = widget.days.indexOf(_selectedDay);
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
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < widget.days.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _dayChip(i),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final slot in ItinerarySlot.values)
                    _slotTile(slot, dayIndex, item),
                  if (item.dayDate != null)
                    ListTile(
                      leading: const Icon(
                        Icons.archive_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Por asignar'),
                      subtitle: const Text('Fuera de los días del itinerario'),
                      onTap: () => widget.onMove(null, null),
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.textSecondary,
                    ),
                    title: const Text('Quitar del itinerario'),
                    onTap: widget.onRemove,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayChip(int index) {
    final day = widget.days[index];
    final selected = day == _selectedDay;
    final label = 'Día ${index + 1} · ${dayLabel(day)}';
    // Same vocabulary as the pill strip: announced as a selectable button;
    // the label comes from the chip text.
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => setState(() => _selectedDay = day),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryDeep
                : AppColors.muted.withValues(alpha: 0.6),
            borderRadius: AppRadii.pill,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? Colors.white : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _slotTile(ItinerarySlot slot, int dayIndex, ItineraryItem item) {
    final isCurrent = item.dayDate == _selectedDay && item.slot == slot;
    return ListTile(
      enabled: !isCurrent,
      leading: Icon(
        ItinerarySlotSection.iconFor(slot),
        color: isCurrent ? AppColors.textSecondary : AppColors.primary,
      ),
      title: Text(slot.label),
      subtitle: Text(
        isCurrent
            ? 'Ya está en este bloque'
            : 'Día ${dayIndex + 1} · ${dayLabel(_selectedDay)}',
      ),
      onTap: isCurrent ? null : () => widget.onMove(_selectedDay, slot),
    );
  }
}
