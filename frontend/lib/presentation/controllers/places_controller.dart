import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:latlong2/latlong.dart';

import '../../data/models/category.dart';
import '../../data/models/category_draft.dart';
import '../../data/models/place.dart';
import '../../data/models/place_draft.dart';
import '../../data/models/place_update.dart';
import '../../data/place_api.dart';

class PlacesState {
  const PlacesState({
    required this.places,
    required this.categories,
    required this.isLoading,
  });

  final List<Place> places;
  final List<Category> categories;
  final bool isLoading;
}

class PlacesController extends ValueNotifier<PlacesState> {
  PlacesController(this._api)
    : super(const PlacesState(places: [], categories: [], isLoading: false));

  final PlaceApi _api;

  Future<void> loadAll() async {
    value = PlacesState(
      places: value.places,
      categories: value.categories,
      isLoading: true,
    );
    try {
      final results = await Future.wait<Object>([
        _api.fetchCategories(),
        _api.fetchPlaces(),
      ]);
      value = PlacesState(
        places: results[1] as List<Place>,
        categories: results[0] as List<Category>,
        isLoading: false,
      );
    } catch (_) {
      value = PlacesState(
        places: value.places,
        categories: value.categories,
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<Place> createPlace(PlaceDraft draft) async {
    final place = await _api.createPlace(draft);
    value = PlacesState(
      places: [...value.places, place],
      categories: value.categories,
      isLoading: value.isLoading,
    );
    return place;
  }

  Future<Place> updatePlace(int id, PlaceUpdate update) async {
    final updated = await _api.updatePlace(id, update);
    value = PlacesState(
      places: [for (final p in value.places) p.id == id ? updated : p],
      categories: value.categories,
      isLoading: value.isLoading,
    );
    return updated;
  }

  Future<void> deletePlace(int id) async {
    await _api.deletePlace(id);
    value = PlacesState(
      places: value.places.where((p) => p.id != id).toList(),
      categories: value.categories,
      isLoading: value.isLoading,
    );
  }

  Future<Category> createCategory(CategoryDraft draft) async {
    final category = await _api.createCategory(draft);
    value = PlacesState(
      places: value.places,
      categories: [...value.categories, category],
      isLoading: value.isLoading,
    );
    return category;
  }

  Future<Category> renameCategory(int id, CategoryDraft draft) async {
    final renamed = await _api.renameCategory(id, draft);
    value = PlacesState(
      places: [
        for (final p in value.places)
          p.category.id == id
              ? Place(
                  id: p.id,
                  name: p.name,
                  description: p.description,
                  latitude: p.latitude,
                  longitude: p.longitude,
                  category: renamed,
                )
              : p,
      ],
      categories: [for (final c in value.categories) c.id == id ? renamed : c],
      isLoading: value.isLoading,
    );
    return renamed;
  }

  Future<void> deleteCategory(int id, {int? reassignTo}) async {
    await _api.deleteCategory(id, reassignTo: reassignTo);
    final categories = value.categories.where((c) => c.id != id).toList();
    Category? target;
    if (reassignTo != null) {
      for (final c in categories) {
        if (c.id == reassignTo) {
          target = c;
          break;
        }
      }
    }
    value = PlacesState(
      places: [
        for (final p in value.places)
          p.category.id == id && target != null
              ? Place(
                  id: p.id,
                  name: p.name,
                  description: p.description,
                  latitude: p.latitude,
                  longitude: p.longitude,
                  category: target,
                )
              : p,
      ],
      categories: categories,
      isLoading: value.isLoading,
    );
  }

  Future<LatLng> resolveMapUrl(String url) => _api.resolveMapUrl(url);
}
