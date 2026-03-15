import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/exceptions.dart';
import '../models/food_product_model.dart';

/// Service for fetching nutritional product data from OpenFoodFacts.
class FoodService {
  static const _host = 'world.openfoodfacts.org';
  static const _fields =
      'product_name,brands,nutriments,ingredients_text,serving_size,serving_quantity,nutriscore_grade';

  /// Fetch product data from OpenFoodFacts.
  ///
  /// Returns null if the product is not found (status != 1).
  /// Throws [NetworkException] on connectivity / timeout issues.
  /// Throws [ServerException] on unexpected HTTP status codes.
  Future<FoodProduct?> getProductByBarcode(String barcode) async {
    final uri = Uri.https(_host, '/api/v2/product/$barcode', {'fields': _fields});

    final http.Response response;
    try {
      response = await http
          .get(uri, headers: {'User-Agent': 'GymOS-Flutter/1.0'})
          .timeout(const Duration(seconds: 10));
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('timed out')) {
        throw const RequestTimeoutException();
      }
      throw NetworkException(
        'Could not reach the nutrition database. Check your connection.',
        originalError: e,
      );
    }

    if (response.statusCode != 200) {
      throw ServerException(response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if ((body['status'] as int? ?? 0) != 1) {
      return null; // Product not found — not an error
    }

    final product = body['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    return FoodProduct.fromOpenFoodFacts(barcode, product);
  }
}
