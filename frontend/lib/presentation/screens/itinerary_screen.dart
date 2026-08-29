import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/itinerary_item.dart';
import '../../data/models/itinerary_slot.dart';
import '../../data/models/place.dart';
import '../../data/models/trip.dart';
import '../controllers/itinerary_controller.dart';
import '../controllers/places_controller.dart';
import '../widgets/general_items_section.dart';
import '../widgets/itinerary_slot_section.dart';
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

  late final TabController _tabController;
  late List<DateTime> _days;
  Timer? _dayHoverTimer;

  @override
  void initState() {
    super.initState();
    _days = _deriveDays(widget.trip);
    _tabController = TabController(length: _days.length, vsync: this);
    _load();
  }

  @override
  void didUpdateWidget(covariant ItineraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newDays = _deriveDays(widget.trip);
    if (newDays.length != _days.length ||
        widget.trip.startDate != oldWidget.trip.startDate) {
      _days = newDays;
      _tabController.dispose();
      _tabController = TabController(length: _days.length, vsync: this);
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
      _showSaveError(e);
    }
  }

  void _moveItem(int itemId, DateTime? day, ItinerarySlot? slot, int index) {
    widget.itineraryController
        .moveItem(itemId, day, slot, index)
        .catchError((Object error) => _showSaveError(error));
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
    widget.itineraryController
        .removeItem(itemId)
        .catchError((Object error) => _showSaveError(error));
  }

  void _addPlace(Place place) {
    widget.itineraryController
        .addPlace(place)
        .catchError((Object error) => _showSaveError(error));
  }

  void _showSaveError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
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
      appBar: AppBar(title: Text(widget.trip.name)),
      body: ValueListenableBuilder<bool>(
        valueListenable: widget.online,
        builder: (_, isOnline, _) => Column(
          children: [
            if (!isOnline) const OfflineBanner(),
            Expanded(
              child: ValueListenableBuilder<ItineraryState>(
                valueListenable: widget.itineraryController,
                builder: (_, state, _) => _buildContent(state),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'itinerary-add-fab',
        onPressed: _openPicker,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(ItineraryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final general = state.items.where((i) => i.isUnassigned).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return Column(
      children: [
        GeneralItemsSection(
          items: general,
          onAcceptItem: (item, index) => _moveItem(item.id, null, null, index),
          onDeleteItem: _removeItem,
        ),
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [for (var i = 0; i < _days.length; i++) _dayTab(i)],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final day in _days) _daySections(day, state.items),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayTab(int index) {
    final day = _days[index];
    final label =
        'Día ${index + 1} · ${_twoDigits(day.day)}/${_twoDigits(day.month)}';
    return DragTarget<ItineraryItem>(
      onMove: (details) => _scheduleDayOpen(index),
      onLeave: (data) => _cancelDayOpen(),
      onAcceptWithDetails: (details) {
        _cancelDayOpen();
        _dropOnDay(details.data, day);
      },
      builder: (context, candidateData, rejectedData) => Tab(text: label),
    );
  }

  Widget _daySections(DateTime day, List<ItineraryItem> items) {
    Widget section(ItinerarySlot slot) {
      final slotItems =
          items.where((i) => i.dayDate == day && i.slot == slot).toList()
            ..sort((a, b) => a.position.compareTo(b.position));
      return ItinerarySlotSection(
        title: slot.label,
        slot: slot,
        items: slotItems,
        onAcceptItem: (item, slot, index) =>
            _moveItem(item.id, day, slot, index),
        onDeleteItem: _removeItem,
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        section(ItinerarySlot.morning),
        section(ItinerarySlot.afternoon),
        section(ItinerarySlot.night),
      ],
    );
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
