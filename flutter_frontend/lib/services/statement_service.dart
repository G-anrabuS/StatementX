import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html; // Need to handle web specific download
import '../models/statement_model.dart';
import '../models/insights_model.dart';
import '../models/visualization_model.dart';
import 'auth_service.dart';

class StatementService {
  // ... rest of class

  static Future<void> exportStatementPdf(String statementId) async {
    final url = Uri.parse('$baseUrl/$statementId/export-pdf');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final fileName = 'StatementX_Analysis_$statementId.pdf';

      if (kIsWeb) {
        // Web: Create an anchor element and trigger download
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile: Save to temp directory and open
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      }
    } else {
      throw Exception('Failed to export PDF: ${response.body}');
    }
  }
  // Configures local device bridge address transparently
  static String get baseUrl {
    if (kIsWeb) {
      return '${Uri.base.origin}/api/statements';
    }
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return 'http://10.149.147.205:8000/api/statements';
    }
    return 'http://127.0.0.1:8000/api/statements';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Optimized Batch Translation using HTML Packing
  /// Sends a list of strings wrapped in HTML to the backend for single-trip processing.
  static Future<List<String>> translatePackedList({
    required List<String> items,
    required String targetLang,
  }) async {
    if (items.isEmpty) return [];

    // 1. PACKING STAGE: Wrap individual elements inside unique tracking tags
    final htmlBuffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      String cleanText = items[i]
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      htmlBuffer.write('<p id="$i">$cleanText</p>');
    }

    // Direct path to the /translate/html endpoint (removing the /statements prefix)
    final url = Uri.parse(
      baseUrl.replaceAll('/api/statements', '/api/translate/html'),
    );

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'html_content': htmlBuffer.toString(),
          'target_lang': targetLang,
          'source_lang': 'auto',
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        String translatedHtml = data['translated_html'] ?? '';

        // 2. UNPACKING STAGE: Reconstruct the collection using Regex
        final exp = RegExp(
          r'<p id="\d+">(.*?)</p>',
          caseSensitive: false,
          dotAll: true,
        );
        final matches = exp.allMatches(translatedHtml);

        List<String> results = [];
        for (final match in matches) {
          String decodedValue = match.group(1) ?? '';
          decodedValue = decodedValue
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>');
          results.add(decodedValue.trim());
        }

        return results.length == items.length ? results : items;
      } else {
        throw Exception(
          'Server rejected packed payload: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('HTML packing pipeline error: $e');
    }
  }

  static Future<StatementResponse> uploadStatement(
    String fileName,
    Uint8List fileBytes, {
    String? password,
  }) async {
    final uri = Uri.parse('$baseUrl/extract');
    final request = http.MultipartRequest('POST', uri);
    
    // Add Authorization header
    final token = await AuthService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return StatementResponse.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 401) {
      throw FormatException(
        jsonDecode(response.body)['detail'] ?? 'PASSWORD_ERROR',
      );
    }
    throw Exception('Upload failed: ${response.body}');
  }

  static Future<List<StatementMetadata>> listStatements() async {
    final response = await http
        .get(Uri.parse(baseUrl), headers: await _getHeaders())
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List;
      return jsonData.map((item) => StatementMetadata.fromJson(item)).toList();
    }
    throw Exception('Failed to list statements: ${response.body}');
  }

  static Future<StatementResponse> getStatement(
    String statementId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/$statementId'), headers: await _getHeaders())
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200)
      return StatementResponse.fromJson(jsonDecode(response.body));
    throw Exception('Failed to fetch statement: ${response.body}');
  }

  static Future<StatementInsights> getStatementInsights(
    String statementId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/$statementId/insights'), headers: await _getHeaders())
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200)
      return StatementInsights.fromJson(jsonDecode(response.body));
    throw Exception('Failed to fetch insights: ${response.body}');
  }

  static Future<VisualizationResponse> getStatementVisualization(
    String statementId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/$statementId/visualization'), headers: await _getHeaders())
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200)
      return VisualizationResponse.fromJson(jsonDecode(response.body));
    throw Exception('Failed to fetch visualization: ${response.body}');
  }

  static Future<Map<String, dynamic>> getStatementAICoach(
    String statementId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/$statementId/ai-coach'), headers: await _getHeaders())
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200)
      return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('AI Coach failure: ${response.body}');
  }

  static Future<String> chatWithStatement({
    required String statementId,
    required String message,
    required List<Map<String, String>> chatHistory,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/$statementId/chat'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'message': message,
            'chat_history': chatHistory
                .map(
                  (m) => {
                    'role': m['sender'] == 'user' ? 'user' : 'assistant',
                    'content': m['text'] ?? '',
                  },
                )
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200)
      return jsonDecode(response.body)['response'] ?? '';
    throw Exception('Chat agent fault: ${response.body}');
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
