import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/statement_model.dart';

class StatementService {
  static String get baseUrl {
    // Dynamically resolve URL if running in a web browser
    if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        // Local development: Point to backend port 8000
        return 'http://127.0.0.1:8000/api/statements/extract';
      } else {
        // Production deployment: Point to the same host/port through Nginx proxy
        final portPart = Uri.base.port == 80 || Uri.base.port == 443 || Uri.base.port == 0 ? '' : ':${Uri.base.port}';
        return '${Uri.base.scheme}://${Uri.base.host}$portPart/api/statements/extract';
      }
    }
    // Fallback for non-web environments (mobile/desktop simulators)
    return 'http://127.0.0.1:8000/api/statements/extract';
  }

  static Future<StatementResponse> uploadStatement(
    String fileName,
    Uint8List fileBytes,
  ) async {
    final uri = Uri.parse(baseUrl);

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return StatementResponse.fromJson(jsonData);
    }

    throw Exception('Upload failed: ${response.body}');
  }
}
