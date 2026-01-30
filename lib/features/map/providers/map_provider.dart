import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';
import '../models/nearby_user_model.dart';
import '../repositories/map_repository.dart';

class MapProvider extends ChangeNotifier {
  final MapRepository _repository;

  MapProvider(this._repository);

  List<NearbyUser> _nearbyUsers = [];
  bool _isLoading = false;
  LatLng? _currentLocation;
  int _radius = 50;
  String? _error;
  bool _isPermissionDeniedForever = false;

  List<NearbyUser> get nearbyUsers => _nearbyUsers;
  bool get isLoading => _isLoading;
  LatLng? get currentLocation => _currentLocation;
  int get radius => _radius;
  String? get error => _error;
  bool get isPermissionDeniedForever => _isPermissionDeniedForever;

  Future<void> initLocation() async {
    _isLoading = true;
    _error = null;
    _isPermissionDeniedForever = false;
    notifyListeners();

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error =
            'Location services are disabled. Please enable location services.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error =
            'Location permissions are permanently denied. Please enable them in settings.';
        _isPermissionDeniedForever = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);

      await _repository.updateLocation(position.latitude, position.longitude);

      await fetchNearbyUsers();
    } catch (e) {
      _error = 'Error getting location: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyUsers() async {
    if (_currentLocation == null) return;

    try {
      final users = await _repository.getNearbyUsers(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radius: _radius,
      );
      _nearbyUsers = users;
      notifyListeners();
    } catch (e) {
      debugPrint('[MapProvider] Error fetching users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSuggestions(String query) async {
    if (query.length < 3) return [];

    try {
      final locationService = LocationService();
      return await locationService.getAddressSuggestions(query);
    } catch (e) {
      debugPrint('[MapProvider] Error getting suggestions: $e');
      return [];
    }
  }

  Future<bool> searchLocation(String query) async {
    debugPrint('[MapProvider] Searching for: $query');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final locationService = LocationService();
      final position = await locationService.getCoordinatesFromAddress(query);

      if (position != null) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        debugPrint('[MapProvider] Found location: $_currentLocation');

        await fetchNearbyUsers();
        return true;
      } else {
        _error = 'Location not found';
        return false;
      }
    } catch (e) {
      _error = 'Error searching location: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> moveToLocation(double lat, double lng) async {
    _currentLocation = LatLng(lat, lng);
    debugPrint('[MapProvider] Moved to location: $_currentLocation');
    await fetchNearbyUsers();
    notifyListeners();
  }

  Timer? _debounce;

  Future<void> updateRadius(int newRadius) async {
    if (_radius == newRadius) return;

    _radius = newRadius;
    notifyListeners();

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_currentLocation != null) {
        debugPrint('[MapProvider] Fetching users with new radius: $_radius km');
        fetchNearbyUsers();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}