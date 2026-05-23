import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/statement_model.dart';
import '../models/insights_model.dart';

class StatementService {
  // Configures local device bridge address transparently when deployed to Android Emulators
  static String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return 'http://10.149.147.205:8000/api/statements';
    }
    return 'http://127.0.0.1:8000/api/statements';
  }

  static Future<StatementResponse> uploadStatement(
    String fileName,
    Uint8List fileBytes,
  ) async {
    final uri = Uri.parse('$baseUrl/extract');
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

  static Future<List<StatementMetadata>> listStatements() async {
    final uri = Uri.parse(baseUrl);
    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List;
      return jsonData.map((item) => StatementMetadata.fromJson(item)).toList();
    }

    throw Exception('Failed to list statements: ${response.body}');
  }

  static Future<StatementInsights> getStatementInsights(
    String statementId,
  ) async {
    final uri = Uri.parse('$baseUrl/$statementId/insights');
    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return StatementInsights.fromJson(jsonData);
    }

    throw Exception('Failed to fetch insights: ${response.body}');
  }
}

class StatementMetadata {
  final String statementId;
  final String fileName;
  final String bankName;
  final String? uploadedAt;

  StatementMetadata({
    required this.statementId,
    required this.fileName,
    required this.bankName,
    this.uploadedAt,
  });

  factory StatementMetadata.fromJson(Map<String, dynamic> json) {
    return StatementMetadata(
      statementId: json['statement_id'] ?? json['id'] ?? '',
      fileName: json['file_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      uploadedAt: json['uploaded_at'],
    );
  }
}
