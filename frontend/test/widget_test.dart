import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/controllers/places_controller.dart';

class _FakePlaceApi extends PlaceApi {
  _FakePlaceApi() : super(baseUrl: 'http://fake');

  @override
  Future<List<Category>> fetchCategories() async => const [];

  @override
  Future<List<Place>> fetchPlaces() async => const [];
}

void main() {
  testWidgets('TravelPlanApp smoke test', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      TravelPlanApp(online: online, placesController: controller),
    );
    await tester.pump();

    expect(find.text('TravelPlan'), findsOneWidget);
  });
}
