import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
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

  /// Get current position
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

  /// Get address from coordinates (reverse geocoding)
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
      };
    } catch (e) {
      debugPrint('[LOCATION] Error getting address: $e');
      return {};
    }
  }

  /// Get current location and address (combined)
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
    debugPrint('[LOCATION] ==========================================');

    return address;
  }
}
