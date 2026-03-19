import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

/// Provider for the PineconeService
final pineconeServiceProvider = Provider<PineconeService>((ref) {
  return PineconeService();
});

/// Service to handle interactions with the Pinecone Vector Database REST API.
class PineconeService {
  /// Base headers required for Pinecone API requests.
  Map<String, String> get _headers {
    return {
      'Api-Key': AppConfig.pineconeApiKey,
      'Content-Type': 'application/json',
      'X-Pinecone-API-Version': '2024-07',
    };
  }

  /// Upserts vectors into the Pinecone index.
  /// 
  /// [vectors] A list of maps, where each map represents a vector object.
  /// Example: `[{'id': 'vec1', 'values': [0.1, 0.2, ...], 'metadata': {'type': 'workout'}}]`
  Future<bool> upsertVectors(List<Map<String, dynamic>> vectors) async {
    if (AppConfig.pineconeApiKey.isEmpty || AppConfig.pineconeHost.isEmpty) {
      debugPrint('[PineconeService] Cannot upsert: Missing API Key or Host.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('https://${AppConfig.pineconeHost}/vectors/upsert'),
        headers: _headers,
        body: jsonEncode({
          'vectors': vectors,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[PineconeService] Upserted ${vectors.length} vectors successfully.');
        return true;
      } else {
        debugPrint('[PineconeService] Failed to upsert. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[PineconeService] Exception during upsert: $e');
      return false;
    }
  }

  /// Queries the Pinecone index for similar vectors.
  /// 
  /// [vector] The query vector (List of doubles).
  /// [topK] The number of closest matches to return.
  /// [includeMetadata] Whether to include the metadata payload in the response.
  Future<Map<String, dynamic>?> queryVectors({
    required List<double> vector,
    int topK = 5,
    bool includeMetadata = true,
  }) async {
    if (AppConfig.pineconeApiKey.isEmpty || AppConfig.pineconeHost.isEmpty) {
      debugPrint('[PineconeService] Cannot query: Missing API Key or Host.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('https://${AppConfig.pineconeHost}/query'),
        headers: _headers,
        body: jsonEncode({
          'vector': vector,
          'topK': topK,
          'includeMetadata': includeMetadata,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('[PineconeService] Failed to query. Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[PineconeService] Exception during query: $e');
      return null;
    }
  }
}
