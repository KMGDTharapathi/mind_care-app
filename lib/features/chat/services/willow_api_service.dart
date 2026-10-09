import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Calls the Willow LLaMA model served from Google Colab via ngrok.
///
/// Usage:
///   1. Run Cell 10 in your Colab notebook to start the API server.
///   2. Copy the ngrok URL printed by the cell.
///   3. Update [baseUrl] below with that URL (or set it at runtime via [setBaseUrl]).
class WillowApiService {
  static String _baseUrl = 'https://paint-assurance-humanitarian-amanda.trycloudflare.com';

  /// Update the base URL at runtime (e.g. from a settings screen or env).
  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get baseUrl => _baseUrl;

  /// Returns true if the API URL has been configured.
  static bool get isConfigured =>
      _baseUrl.isNotEmpty && !_baseUrl.contains('YOUR_NGROK_URL_HERE');

  /// Send a message to Willow and get a response.
  /// Returns null if the API is unreachable or not configured.
  static Future<String?> chat(String message) async {
    if (!isConfigured) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
              // Bypass Cloudflare browser warning page
              'cf-access-client-id': 'bypass',
              'User-Agent': 'MindCareApp/1.0',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Support both {response: "..."} and {response: "...", emotion: "..."}
        return data['response'] as String?;
      }
      debugPrint('Willow API error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Willow API unreachable: $e');
      return null;
    }
  }

  /// Check if the server is alive.
  static Future<bool> healthCheck() async {
    if (!isConfigured) return false;
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {
              'cf-access-client-id': 'bypass',
              'User-Agent': 'MindCareApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
