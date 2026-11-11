import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServices {
  static const String _baseUrl =
      "https://3zp10c66-4000.asse.devtunnels.ms/api/v1";
  static const String _tokenKey = "token-flutter";

  // MENYIMPAN TOKEN
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // MENGAMBIL TOKEN
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // MENGHAPUS TOKEN
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // LOGOUT
  static Future<void> logout() async {
    await removeToken();
  }

  // HEADER
  static Future<Map<String, String>> _headers() async {
    final token = await getToken();

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // HANDLE RESPONSE
  static dynamic _handleResponse(http.Response response) {
    dynamic body;

    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (e) {
      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE SERVER: ${response.body}');

      throw Exception(
        'Server mengirim respons bukan JSON. '
        'Status: ${response.statusCode}. '
        'Isi: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (body is Map) {
      throw Exception(body['message'] ?? 'Terjadi kesalahan');
    }

    throw Exception('Terjadi kesalahan pada server');
  }

  // GET
  static Future<dynamic> get(String endpoint) async {
    final response = await http
        .get(Uri.parse("$_baseUrl$endpoint"), headers: await _headers())
        .timeout(const Duration(seconds: 20));

    return _handleResponse(response);
  }

  // POST JSON
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$_baseUrl$endpoint"),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  // UPLOAD PRODUK DENGAN GAMBAR
  static Future<dynamic> uploadImage(
    String endpoint,
    Map<String, dynamic> data,
    Uint8List imageBytes,
    String imageName,
  ) async {
    final token = await getToken();

    final extension = imageName.split('.').last.toLowerCase();

    // MENENTUKAN TIPE GAMBAR
    MediaType contentType;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = MediaType('image', 'jpeg');
        break;
      case 'png':
        contentType = MediaType('image', 'png');
        break;
      case 'webp':
        contentType = MediaType('image', 'webp');
        break;
      default:
        throw Exception('Format gambar tidak didukung: .$extension');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$_baseUrl$endpoint"),
    );

    request.headers.addAll({
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    });

    // DATA PRODUK
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // GAMBAR PRODUK
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName,
        contentType: contentType,
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final response = await http.Response.fromStream(streamedResponse);
    // DEBUG RESPONSE SERVER
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    return _handleResponse(response);
  }

  // MENGAMBIL USER ID DARI TOKEN
  static Future<int> getUserIdFromToken() async {
    final token = await getToken();

    if (token == null) {
      throw Exception("Token tidak ditemukan. Silakan login.");
    }

    final parts = token.split('.');

    if (parts.length != 3) {
      throw Exception("Format token tidak valid");
    }

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );

    final id = payload['id'];

    if (id is int) return id;

    if (id is String) {
      final parsedId = int.tryParse(id);
      if (parsedId != null) return parsedId;
    }

    throw Exception("User ID tidak ditemukan");
  }

  // MENGAMBIL DATA PROFILE
  static Future<dynamic> getProfile(int userId) async {
    return await get('/users/$userId');
  }

  // DELETE
  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl$endpoint"),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  // UPDATE PRODUK DENGAN GAMBAR (OPSIONAL)
  static Future<dynamic> updateImage(
    String endpoint,
    Map<String, dynamic> data, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await getToken();

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse("$_baseUrl$endpoint"),
    );

    request.headers.addAll({
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    });

    // DATA PRODUK
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // GAMBAR BARU (JIKA DIPILIH)
    if (imageBytes != null && imageName != null) {
      final extension = imageName.split('.').last.toLowerCase();

      MediaType contentType;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        case 'png':
          contentType = MediaType('image', 'png');
          break;
        case 'webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          throw Exception('Format gambar tidak didukung: .$extension');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
          contentType: contentType,
        ),
      );
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('UPDATE STATUS: ${response.statusCode}');
    debugPrint('UPDATE BODY: ${response.body}');

    return _handleResponse(response);
  }
}
