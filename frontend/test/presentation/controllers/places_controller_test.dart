import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/category_draft.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/models/place_draft.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/presentation/controllers/places_controller.dart';

class _FakePlaceApi extends PlaceApi {
  _FakePlaceApi({
    this.categories = const [],
    this.places = const [],
    this.createdPlace,
    this.createdCategory,
    this.error,
    this.createCategoryError,
    this.renamedCategory,
    this.renameError,
    this.deleteError,
  }) : super(baseUrl: 'http://fake');

  final List<Category> categories;
  final List<Place> places;
  final Place? createdPlace;
  final Category? createdCategory;
  final Object? error;
  final Object? createCategoryError;
  final Category? renamedCategory;
  final Object? renameError;
  final Object? deleteError;

  int? deletedCategoryId;
  int? deleteReassignTo;

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
  Future<Place> createPlace(PlaceDraft draft) async {
    if (error != null) throw error!;
    return createdPlace!;
  }

  @override
  Future<Category> createCategory(CategoryDraft draft) async {
    if (createCategoryError != null) throw createCategoryError!;
    return createdCategory!;
  }

  @override
  Future<Category> renameCategory(int id, CategoryDraft draft) async {
    if (renameError != null) throw renameError!;
    return renamedCategory!;
  }

  @override
  Future<void> deleteCategory(int id, {int? reassignTo}) async {
    if (deleteError != null) throw deleteError!;
    deletedCategoryId = id;
    deleteReassignTo = reassignTo;
  }
}

const _category = Category(id: 1, name: 'Naturaleza');
const _playa = Category(id: 2, name: 'Playa');
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
    final controller = PlacesController(
      _FakePlaceApi(error: Exception('boom')),
    );
    addTearDown(controller.dispose);

    await expectLater(controller.loadAll(), throwsA(isA<Exception>()));

    expect(controller.value.isLoading, isFalse);
  });

  test('createPlace adds the created place to state', () async {
    final controller = PlacesController(
      _FakePlaceApi(categories: [_category], createdPlace: _place),
    );
    addTearDown(controller.dispose);
    await controller.loadAll();

    final created = await controller.createPlace(
      const PlaceDraft(
        name: 'Mirador',
        categoryId: 1,
        latitude: 42.5,
        longitude: -3.1,
      ),
    );

    expect(created, _place);
    expect(controller.value.places, [_place]);
  });

  test('createPlace propagates errors', () async {
    final controller = PlacesController(
      _FakePlaceApi(error: Exception('boom')),
    );
    addTearDown(controller.dispose);

    await expectLater(
      controller.createPlace(
        const PlaceDraft(
          name: 'Mirador',
          categoryId: 1,
          latitude: 42.5,
          longitude: -3.1,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('createCategory appends the created category to state', () async {
    final controller = PlacesController(
      _FakePlaceApi(categories: [_category], createdCategory: _playa),
    );
    addTearDown(controller.dispose);
    await controller.loadAll();

    final created = await controller.createCategory(
      const CategoryDraft(name: 'Playa'),
    );

    expect(created, _playa);
    expect(controller.value.categories, [_category, _playa]);
  });

  test('createCategory propagates errors without changing state', () async {
    final controller = PlacesController(
      _FakePlaceApi(
        categories: [_category],
        createCategoryError: Exception('boom'),
      ),
    );
    addTearDown(controller.dispose);
    await controller.loadAll();
    final before = controller.value.categories;

    await expectLater(
      controller.createCategory(const CategoryDraft(name: 'Playa')),
      throwsA(isA<Exception>()),
    );

    expect(controller.value.categories, before);
  });

  test('renameCategory updates the category and embedded places', () async {
    final controller = PlacesController(
      _FakePlaceApi(
        categories: [_category],
        places: [_place],
        renamedCategory: const Category(id: 1, name: 'Costa'),
      ),
    );
    addTearDown(controller.dispose);
    await controller.loadAll();

    final renamed = await controller.renameCategory(
      1,
      const CategoryDraft(name: 'Costa'),
    );

    expect(renamed, const Category(id: 1, name: 'Costa'));
    expect(controller.value.categories, [const Category(id: 1, name: 'Costa')]);
    expect(controller.value.places.single.category.name, 'Costa');
  });

  test('renameCategory propagates errors without changing state', () async {
    final controller = PlacesController(
      _FakePlaceApi(
        categories: [_category],
        places: [_place],
        renameError: Exception('boom'),
      ),
    );
    addTearDown(controller.dispose);
    await controller.loadAll();
    final before = controller.value;

    await expectLater(
      controller.renameCategory(1, const CategoryDraft(name: 'Costa')),
      throwsA(isA<Exception>()),
    );

    expect(controller.value.categories, before.categories);
    expect(controller.value.places, before.places);
  });

  test('deleteCategory removes the category from state', () async {
    final controller = PlacesController(
      _FakePlaceApi(categories: [_category, _playa]),
    );
    addTearDown(controller.dispose);
    await controller.loadAll();

    await controller.deleteCategory(1);

    expect(controller.value.categories, [_playa]);
  });

  test('deleteCategory with reassignTo updates embedded places', () async {
    final controller = PlacesController(
      _FakePlaceApi(categories: [_category, _playa], places: [_place]),
    );
    addTearDown(controller.dispose);
    await controller.loadAll();

    await controller.deleteCategory(1, reassignTo: 2);

    expect(controller.value.categories, [_playa]);
    expect(controller.value.places.single.category, _playa);
  });

  test('deleteCategory propagates errors without changing state', () async {
    final controller = PlacesController(
      _FakePlaceApi(categories: [_category], deleteError: Exception('boom')),
    );
    addTearDown(controller.dispose);
    await controller.loadAll();
    final before = controller.value.categories;

    await expectLater(
      controller.deleteCategory(1, reassignTo: 2),
      throwsA(isA<Exception>()),
    );

    expect(controller.value.categories, before);
  });
}
