import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'directions_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsRepository {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  final Dio _dio;

  DirectionsRepository({required Dio dio}) : _dio = dio;

  Future<Directions> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    await dotenv.load(fileName: ".env");
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': dotenv.env['GOOGLE_MAPS_API_KEY'],
          'mode': 'walking',
        },
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return Directions.fromMap(response.data);
      } else {
        throw Exception('Failed to fetch directions');
      }
    } catch (e) {
      // Handle exceptions
      print('Error fetching directions: $e');
      return Directions(
        bounds: LatLngBounds(
          northeast: LatLng(0.0, 0.0),
          southwest: LatLng(0.0, 0.0),
        ),
        polylinePoints: [],
        totalDistance: 'N/A',
        totalDuration: 'N/A',
      );
    }
  }
}
