import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/nearby_user_model.dart';

class MapRepository {
  final ApiService _apiService;

  MapRepository(this._apiService);

  Future<List<NearbyUser>> getNearbyUsers({
    required double latitude,
    required double longitude,
    int radius = 50,
  }) async {
    try {
      debugPrint(
        '[MapRepository] Fetching nearby users: lat=$latitude, lng=$longitude, r=$radius',
      );

      final response = await _apiService.dio.get(
        '${AppConstants.baseUrl}/users/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
      );

      debugPrint('[MapRepository] Response status: ${response.statusCode}');
      debugPrint('[MapRepository] Response data: ${response.data}');

      if (response.statusCode == 200 &&
          (response.data['data'] != null || response.data['users'] != null)) {
        final List<dynamic> usersJson =
            response.data['data'] ?? response.data['users'];
        debugPrint('[MapRepository] Parsed ${usersJson.length} users.');
        return usersJson.map((json) => NearbyUser.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[MapRepository] Error fetching nearby users: $e');
      if (e is DioException) {
        debugPrint('[MapRepository] DioError: ${e.response?.data}');
      }
      return [];
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      await _apiService.dio.patch(
        '${AppConstants.baseUrl}/users/location',
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } catch (e) {
      debugPrint('[MapRepository] Error updating location: $e');
    }
  }
}
