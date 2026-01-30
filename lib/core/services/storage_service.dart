import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: AppConstants.tokenKey, value: accessToken);
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }
}