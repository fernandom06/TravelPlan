import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../data/models/category.dart';
import '../../data/models/place.dart';
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

  Future<Place> createPlace({
    required String name,
    required int categoryId,
    String? description,
    required double latitude,
    required double longitude,
  }) async {
    final place = await _api.createPlace(
      name: name,
      categoryId: categoryId,
      description: description,
      latitude: latitude,
      longitude: longitude,
    );
    value = PlacesState(
      places: [...value.places, place],
      categories: value.categories,
      isLoading: value.isLoading,
    );
    return place;
  }
}
