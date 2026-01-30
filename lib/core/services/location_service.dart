import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';

class LocationService {
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[LOCATION] Permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LOCATION] Permission denied forever');
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LOCATION] Location services are disabled');
        return null;
      }

      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint(
        '[LOCATION] Got position: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('[LOCATION] Error getting position: $e');
      return null;
    }
  }

  Future<Map<String, String?>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        debugPrint('[LOCATION] No placemarks found');
        return {};
      }

      final place = placemarks.first;
      debugPrint('[LOCATION] Found place: ${place.toJson()}');

      return {
        'city': place.locality ?? place.subAdministrativeArea,
        'state': place.administrativeArea,
        'country': place.country,
        'postal_code': place.postalCode,
      };
    } catch (e) {
      debugPrint('[LOCATION] Error getting address: $e');
      return {};
    }
  }

  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      debugPrint('[LOCATION] Getting coordinates for address: $address');
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        debugPrint('[LOCATION] No locations found for address: $address');
        return null;
      }

      final location = locations.first;
      debugPrint(
        '[LOCATION] Found location: ${location.latitude}, ${location.longitude}',
      );

      return Position(
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: location.timestamp,
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } catch (e) {
      debugPrint('[LOCATION] Error getting coordinates from address: $e');
      return null;
    }
  }

  Future<Map<String, String?>> getCurrentLocationAddress() async {
    debugPrint('[LOCATION] ========== Getting Current Location ==========');
    final position = await getCurrentPosition();
    if (position == null) {
      debugPrint('[LOCATION] ERROR: Could not get position');
      return {};
    }

    debugPrint('[LOCATION] ========== Position Retrieved ==========');
    debugPrint('[LOCATION] Latitude: ${position.latitude}');
    debugPrint('[LOCATION] Longitude: ${position.longitude}');
    debugPrint('[LOCATION] Accuracy: ${position.accuracy} meters');

    final address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    debugPrint('[LOCATION] ========== Address Parsed ==========');
    debugPrint('[LOCATION] City: ${address['city'] ?? 'NOT FOUND'}');
    debugPrint('[LOCATION] State: ${address['state'] ?? 'NOT FOUND'}');
    debugPrint('[LOCATION] Country: ${address['country'] ?? 'NOT FOUND'}');
    debugPrint('[LOCATION] Pincode: ${address['postal_code'] ?? 'NOT FOUND'}');
    debugPrint('[LOCATION] ==========================================');

    return address;
  }

  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
          'countrycodes': 'in',
        },
        options: Options(headers: {'User-Agent': 'WeddingZon/1.0'}),
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((item) {
          return {
            'display_name': item['display_name'],
            'lat': double.tryParse(item['lat'] ?? '0'),
            'lon': double.tryParse(item['lon'] ?? '0'),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[LOCATION] Error getting suggestions: $e');
      return [];
    }
  }
}
