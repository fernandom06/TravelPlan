import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models/trip.dart';
import 'models/trip_draft.dart';
import 'models/trip_update.dart';

class TripApiException implements Exception {
  const TripApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TripApi {
  TripApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<Trip>> fetchTrips() async {
    final response = await _client.get(_uri('/trips'));
    if (response.statusCode != 200) {
      throw TripApiException('Failed to load trips: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Trip> fetchTrip(String id) async {
    final response = await _client.get(_uri('/trips/$id'));
    if (response.statusCode != 200) {
      throw TripApiException('Failed to load trip: ${response.statusCode}');
    }
    return Trip.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Trip> createTrip(TripDraft draft) async {
    final response = await _client.post(
      _uri('/trips'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode != 201) {
      throw TripApiException('Failed to create trip: ${response.statusCode}');
    }
    return Trip.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Trip> updateTrip(String id, TripUpdate update) async {
    final response = await _client.patch(
      _uri('/trips/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(update.toJson()),
    );
    if (response.statusCode != 200) {
      throw TripApiException('Failed to update trip: ${response.statusCode}');
    }
    return Trip.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteTrip(String id) async {
    final response = await _client.delete(_uri('/trips/$id'));
    if (response.statusCode != 204) {
      throw TripApiException('Failed to delete trip: ${response.statusCode}');
    }
  }

  Future<String> uploadImage(
    Uint8List bytes,
    String filename,
    String contentType,
  ) async {
    final request = http.MultipartRequest('POST', _uri('/trips/images'))
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: http.MediaType.parse(contentType),
        ),
      );
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw TripApiException('Failed to upload image: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }
}
