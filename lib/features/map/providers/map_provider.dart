import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/nearby_user_model.dart';
import '../repositories/map_repository.dart';

class MapProvider extends ChangeNotifier {
  final MapRepository _repository;

  MapProvider(this._repository);

  List<NearbyUser> _nearbyUsers = [];
  bool _isLoading = false;
  LatLng? _currentLocation;
  int _radius = 50; // In km
  String? _error;

  // Getters
  List<NearbyUser> get nearbyUsers => _nearbyUsers;
  bool get isLoading => _isLoading;
  LatLng? get currentLocation => _currentLocation;
  int get radius => _radius;
  String? get error => _error;

  Future<void> initLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled.';
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
            'Location permissions are permanently denied, we cannot request permissions.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);

      // Update backend with current location
      await _repository.updateLocation(position.latitude, position.longitude);

      // Fetch initial users
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

  Timer? _debounce;

  Future<void> updateRadius(int newRadius) async {
    if (_radius == newRadius) return;

    _radius = newRadius;
    notifyListeners(); // Update UI immediately for slider

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
