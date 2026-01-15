import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Service to persist user data locally using SharedPreferences
class UserStorageService {
  static const String _userKey = 'cached_user';

  /// Save user to SharedPreferences
  static Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      debugPrint('[USER_STORAGE] User saved to local storage');
    } catch (e) {
      debugPrint('[USER_STORAGE] Failed to save user: $e');
    }
  }

  /// Load user from SharedPreferences
  static Future<User?> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson == null) {
        debugPrint('[USER_STORAGE] No cached user found');
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = User.fromJson(userMap);
      debugPrint(
        '[USER_STORAGE] User loaded from local storage: ${user.email}',
      );
      return user;
    } catch (e) {
      debugPrint('[USER_STORAGE] Failed to load user: $e');
      return null;
    }
  }

  /// Clear user from SharedPreferences
  static Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      debugPrint('[USER_STORAGE] User cleared from local storage');
    } catch (e) {
      debugPrint('[USER_STORAGE] Failed to clear user: $e');
    }
  }

  /// Check if a cached user exists
  static Future<bool> hasUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }
}
