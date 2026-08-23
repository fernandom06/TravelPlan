import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/category.dart';
import 'models/place.dart';
import 'models/place_draft.dart';

class PlaceApiException implements Exception {
  const PlaceApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlaceApi {
  PlaceApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<Category>> fetchCategories() async {
    final response = await _client.get(_uri('/categories'));
    if (response.statusCode != 200) {
      throw PlaceApiException('Failed to load categories: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Place>> fetchPlaces() async {
    final response = await _client.get(_uri('/places'));
    if (response.statusCode != 200) {
      throw PlaceApiException('Failed to load places: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Place> createPlace(PlaceDraft draft) async {
    final response = await _client.post(
      _uri('/places'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': draft.name,
        'category_id': draft.categoryId,
        'description': draft.description,
        'latitude': draft.latitude,
        'longitude': draft.longitude,
      }),
    );
    if (response.statusCode != 201) {
      throw PlaceApiException('Failed to create place: ${response.statusCode}');
    }
    return Place.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
