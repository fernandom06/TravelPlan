import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/itinerary_item.dart';
import 'models/itinerary_move.dart';

class ItineraryApiException implements Exception {
  const ItineraryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ItineraryApi {
  ItineraryApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<ItineraryItem>> fetchItinerary(String tripId) async {
    final response = await _client.get(_uri('/trips/$tripId/itinerary'));
    if (response.statusCode != 200) {
      throw ItineraryApiException(
        'Failed to load itinerary: ${response.statusCode}',
      );
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ItineraryItem> addPlace(String tripId, int placeId) async {
    final response = await _client.post(
      _uri('/trips/$tripId/itinerary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'place_id': placeId}),
    );
    if (response.statusCode != 201) {
      throw ItineraryApiException(
        'Failed to add place to itinerary: ${response.statusCode}',
      );
    }
    return ItineraryItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ItineraryItem> moveItem(
    String tripId,
    int itemId,
    ItineraryMove move,
  ) async {
    final response = await _client.patch(
      _uri('/trips/$tripId/itinerary/$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(move.toJson()),
    );
    if (response.statusCode != 200) {
      throw ItineraryApiException(
        'Failed to move itinerary item: ${response.statusCode}',
      );
    }
    return ItineraryItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> removeItem(String tripId, int itemId) async {
    final response = await _client.delete(
      _uri('/trips/$tripId/itinerary/$itemId'),
    );
    if (response.statusCode != 204) {
      throw ItineraryApiException(
        'Failed to remove itinerary item: ${response.statusCode}',
      );
    }
  }
}
