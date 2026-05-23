import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/statement_model.dart';

class StatementService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/statements/extract';

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
      const Duration(seconds: 30),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return StatementResponse.fromJson(jsonData);
    }

    throw Exception('Upload failed: ${response.body}');
  }
}
