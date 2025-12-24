import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String token = "";

  /// Load token from storage on app start
  static Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
  }

  /// Generic POST
  static Future<dynamic> post(
      String endpoint, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$apiBase/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _parseResponse(res);
  }

  // /// Generic GET list (returns List)
  // static Future<List<dynamic>> getList(String endpoint) async {
  //   final res = await http.get(
  //     Uri.parse('$apiBase/$endpoint'),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //     },
  //   );
  //   return _parseListResponse(res);
  // }

  static Future<List<dynamic>> getList(String endpoint) async {
    final res = await http.get(
      Uri.parse('$apiBase/$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(res.body);

    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'];
    }

    return [];
  }

  /// Generic GET single object
  static Future<Map<String, dynamic>> getOne(String endpoint) async {
    final res = await http.get(
      Uri.parse('$apiBase/$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return _parseMapResponse(res);
  }

  /// Generic DELETE
  static Future<dynamic> delete(String endpoint) async {
    final res = await http.delete(
      Uri.parse('$apiBase/$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return _parseResponse(res);
  }

  // ───────────────────────── Helpers ─────────────────────────

  static dynamic _parseResponse(http.Response res) {
    if (res.body.isEmpty) return null;
    final body = jsonDecode(res.body);
    return body;
  }

  static List<dynamic> _parseListResponse(http.Response res) {
    if (res.body.isEmpty) return [];
    final body = jsonDecode(res.body);

    if (body is List) {
      return body;
    }
    // If API returned single object, wrap in a list
    return [body];
  }

  static Map<String, dynamic> _parseMapResponse(http.Response res) {
    if (res.body.isEmpty) return {};
    final body = jsonDecode(res.body);

    if (body is Map<String, dynamic>) {
      return body;
    }
    // If it's a list and first is map, return first item
    if (body is List && body.isNotEmpty && body.first is Map) {
      return Map<String, dynamic>.from(body.first);
    }
    return {};
  }
}
