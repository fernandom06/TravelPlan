import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/category.dart';
import 'models/category_draft.dart';
import 'models/place.dart';
import 'models/place_draft.dart';
import 'models/place_update.dart';

class PlaceApiException implements Exception {
  const PlaceApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DuplicateCategoryException implements Exception {
  const DuplicateCategoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CategoryNotEmptyException implements Exception {
  const CategoryNotEmptyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidReassignTargetException implements Exception {
  const InvalidReassignTargetException(this.message);

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
      throw PlaceApiException(
        'Failed to load categories: ${response.statusCode}',
      );
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

  Future<Place> updatePlace(int id, PlaceUpdate update) async {
    throw UnimplementedError();
  }

  Future<void> deletePlace(int id) async {
    throw UnimplementedError();
  }

  Future<Category> createCategory(CategoryDraft draft) async {
    final response = await _client.post(
      _uri('/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode == 409) {
      throw const DuplicateCategoryException('Category already exists');
    }
    if (response.statusCode != 201) {
      throw PlaceApiException(
        'Failed to create category: ${response.statusCode}',
      );
    }
    return Category.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Category> renameCategory(int id, CategoryDraft draft) async {
    final response = await _client.patch(
      _uri('/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode == 409) {
      throw const DuplicateCategoryException('Category already exists');
    }
    if (response.statusCode != 200) {
      throw PlaceApiException(
        'Failed to rename category: ${response.statusCode}',
      );
    }
    return Category.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id, {int? reassignTo}) async {
    final query = reassignTo == null ? '' : '?reassign_to=$reassignTo';
    final response = await _client.delete(_uri('/categories/$id$query'));
    if (response.statusCode == 409) {
      throw const CategoryNotEmptyException('Category has places');
    }
    if (response.statusCode == 422) {
      throw const InvalidReassignTargetException('Invalid reassignment target');
    }
    if (response.statusCode != 204) {
      throw PlaceApiException(
        'Failed to delete category: ${response.statusCode}',
      );
    }
  }
}
