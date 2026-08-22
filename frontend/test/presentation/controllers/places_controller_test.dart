import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/presentation/controllers/places_controller.dart';

class _FakePlaceApi extends PlaceApi {
  _FakePlaceApi({
    this.categories = const [],
    this.places = const [],
    this.createdPlace,
    this.error,
  }) : super(baseUrl: 'http://fake');

  final List<Category> categories;
  final List<Place> places;
  final Place? createdPlace;
  final Object? error;

  @override
  Future<List<Category>> fetchCategories() async {
    if (error != null) throw error!;
    return categories;
  }

  @override
  Future<List<Place>> fetchPlaces() async {
    if (error != null) throw error!;
    return places;
  }

  @override
  Future<Place> createPlace({
    required String name,
    required int categoryId,
    String? description,
    required double latitude,
    required double longitude,
  }) async {
    if (error != null) throw error!;
    return createdPlace!;
  }
}

const _category = Category(id: 1, name: 'Naturaleza');
const _place = Place(
  id: 1,
  name: 'Mirador',
  description: null,
  latitude: 42.5,
  longitude: -3.1,
  category: _category,
);

void main() {
  test('loadAll populates categories and places', () async {
    final controller = PlacesController(
      _FakePlaceApi(categories: [_category], places: [_place]),
    );
    addTearDown(controller.dispose);

    expect(controller.value.isLoading, isFalse);

    final future = controller.loadAll();
    expect(controller.value.isLoading, isTrue);

    await future;

    expect(controller.value.isLoading, isFalse);
    expect(controller.value.categories, [_category]);
    expect(controller.value.places, [_place]);
  });

  test('loadAll propagates errors and resets isLoading', () async {
    final controller = PlacesController(_FakePlaceApi(error: Exception('boom')));
    addTearDown(controller.dispose);

    await expectLater(controller.loadAll(), throwsA(isA<Exception>()));

    expect(controller.value.isLoading, isFalse);
  });

  test('createPlace adds the created place to state', () async {
    final controller = PlacesController(
      _FakePlaceApi(
        categories: [_category],
        createdPlace: _place,
      ),
    );
    addTearDown(controller.dispose);
    await controller.loadAll();

    final created = await controller.createPlace(
      name: 'Mirador',
      categoryId: 1,
      latitude: 42.5,
      longitude: -3.1,
    );

    expect(created, _place);
    expect(controller.value.places, [_place]);
  });

  test('createPlace propagates errors', () async {
    final controller = PlacesController(_FakePlaceApi(error: Exception('boom')));
    addTearDown(controller.dispose);

    await expectLater(
      controller.createPlace(
        name: 'Mirador',
        categoryId: 1,
        latitude: 42.5,
        longitude: -3.1,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
