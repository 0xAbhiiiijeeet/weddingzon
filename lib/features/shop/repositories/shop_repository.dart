import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../vendor/models/product_model.dart';

class ShopRepository {
  final ApiService _apiService;

  ShopRepository(this._apiService);

  Future<List<Product>> getAllProducts() async {
    debugPrint('');
    debugPrint('┌─────────────────────────────────────────────────────────┐');
    debugPrint('│ [SHOP_REPO] 🛍️ GET ALL PRODUCTS                        │');
    debugPrint('└─────────────────────────────────────────────────────────┘');
    debugPrint('[SHOP_REPO] 📡 API Endpoint: GET /products');
    debugPrint('[SHOP_REPO] ⏳ Fetching all vendor products...');

    try {
      final response = await _apiService.dio.get('/products');

      debugPrint('[SHOP_REPO] ✅ API RESPONSE RECEIVED');
      debugPrint('[SHOP_REPO] 📊 Status Code: ${response.statusCode}');
      debugPrint('[SHOP_REPO] 📦 Response Type: ${response.data.runtimeType}');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> productsJson = response.data['data'];
        debugPrint('[SHOP_REPO] 📋 Products count: ${productsJson.length}');

        final products = productsJson
            .map((json) => Product.fromJson(json))
            .toList();

        debugPrint(
          '[SHOP_REPO] 🎯 Successfully parsed ${products.length} products',
        );
        if (products.isNotEmpty) {
          debugPrint('[SHOP_REPO] 📦 Sample product: ${products.first.name}');
        }
        debugPrint(
          '┌─────────────────────────────────────────────────────────┐',
        );
        debugPrint(
          '│ [SHOP_REPO] 🎉 GET ALL PRODUCTS SUCCESS                │',
        );
        debugPrint(
          '└─────────────────────────────────────────────────────────┘',
        );
        debugPrint('');
        return products;
      } else {
        debugPrint('[SHOP_REPO] ⚠️ WARNING: Unexpected response structure');
        debugPrint('[SHOP_REPO] ⚠️ response.data: ${response.data}');
        return [];
      }
    } on DioException catch (dioError, stackTrace) {
      debugPrint('');
      debugPrint('╔═════════════════════════════════════════════════════════╗');
      debugPrint('║ [SHOP_REPO] ❌ DIO EXCEPTION - GET PRODUCTS             ║');
      debugPrint('╚═════════════════════════════════════════════════════════╝');
      debugPrint('[SHOP_REPO] 🔴 Error Type: ${dioError.type}');
      debugPrint(
        '[SHOP_REPO] 🔴 Status Code: ${dioError.response?.statusCode}',
      );
      debugPrint('[SHOP_REPO] 🔴 Error Message: ${dioError.message}');
      debugPrint('[SHOP_REPO] 📋 Response Data: ${dioError.response?.data}');
      debugPrint('[SHOP_REPO] 📚 Stack Trace:');
      debugPrint(stackTrace.toString().split('\n').take(10).join('\n'));
      debugPrint('╚═════════════════════════════════════════════════════════╝');
      debugPrint('');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('╔═════════════════════════════════════════════════════════╗');
      debugPrint('║ [SHOP_REPO] ❌ GENERAL EXCEPTION - GET PRODUCTS         ║');
      debugPrint('╚═════════════════════════════════════════════════════════╝');
      debugPrint('[SHOP_REPO] 🔴 Exception Type: ${e.runtimeType}');
      debugPrint('[SHOP_REPO] 🔴 Exception Message: $e');
      debugPrint('[SHOP_REPO] 📚 Stack Trace:');
      debugPrint(stackTrace.toString().split('\n').take(10).join('\n'));
      debugPrint('╚═════════════════════════════════════════════════════════╝');
      debugPrint('');
      rethrow;
    }
  }
}
