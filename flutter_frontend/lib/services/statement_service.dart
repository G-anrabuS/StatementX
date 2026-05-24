import 'dart:convert';
import 'dart:io' as io;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/statement_model.dart';
import '../models/insights_model.dart';
import '../models/visualization_model.dart'; // Ensure your visualization response models are located here
import 'auth_service.dart';

class StatementService {
  // Configures local device bridge address transparently when deployed to Android Emulators
  static String get baseUrl {
    if (kIsWeb) {
      return '${Uri.base.origin}/api/statements';
    }
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return 'http://10.149.147.205:8000/api/statements';
    }
    return 'http://127.0.0.1:8000/api/statements';
  }

  /// POST /api/statements/extract
  static Future<StatementResponse> uploadStatement(
    String fileName,
    Uint8List fileBytes, {
    String? password, // <-- Add optional named parameter
  }) async {
    final uri = Uri.parse('$baseUrl/extract');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    // Attach password payload to fields if provided
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return StatementResponse.fromJson(jsonData);
    }

    // Catch password status signals from the backend
    if (response.statusCode == 401) {
      final errorDetail = jsonDecode(response.body)['detail'];
      throw FormatException(errorDetail ?? 'PASSWORD_ERROR');
    }

    throw Exception('Upload failed: ${response.body}');
  }

  /// GET /api/statements
  /// Retrieves and lists all parsed bank statements with their structural database IDs
  static Future<List<StatementMetadata>> listStatements() async {
    final uri = Uri.parse(baseUrl);
    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List;
      return jsonData.map((item) => StatementMetadata.fromJson(item)).toList();
    }

    throw Exception('Failed to list statements: ${response.body}');
  }

  /// GET /api/statements/{statement_id}/insights
  /// Pulls dynamic aggregates, category spending item breakdowns, and subscription checks
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

  /// GET /api/statements/{statement_id}/visualization
  /// Compiles premium health scores, timeline time-series data points, and budget frameworks
  static Future<VisualizationResponse> getStatementVisualization(
    String statementId,
  ) async {
    final uri = Uri.parse('$baseUrl/$statementId/visualization');
    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return VisualizationResponse.fromJson(jsonData);
    }

    throw Exception('Failed to fetch visualization data: ${response.body}');
  }

  /// GET /api/statements/{statement_id}/ai-coach
  /// Fetches ONLY the AI-powered textual summary evaluation and structured prioritized recommendations
  static Future<Map<String, dynamic>> getStatementAICoach(
    String statementId,
  ) async {
    final uri = Uri.parse('$baseUrl/$statementId/ai-coach');
    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('AI Coach pipeline failure: ${response.body}');
  }

  /// POST /api/statements/{statement_id}/chat
  /// RAG-based interactive chat utility matching indexed transaction narration vectors
  static Future<String> chatWithStatement({
    required String statementId,
    required String message,
    required List<Map<String, String>>
    chatHistory, // Changed from List<String> to accept structured rows
  }) async {
    final uri = Uri.parse('$baseUrl/$statementId/chat');

    // Map the internal frontend message objects into the JSON key structure expected by the backend
    final formattedHistory = chatHistory
        .map(
          (m) => {
            'role': m['sender'] == 'user'
                ? 'user'
                : 'assistant', // Map role to standard LLM schemas (user/assistant)
            'content': m['text'] ?? '',
          },
        )
        .toList();

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            'chat_history':
                formattedHistory, // Passing structured dictionaries satisfying Pydantic validation
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['response'] ?? '';
    }

    throw Exception('Semantic document query agent fault: ${response.body}');
  }

  /// GET /api/statements/{statement_id}
  /// Retrieves full details of a specific statement, including its transaction list
  static Future<StatementResponse> getStatement(String statementId) async {
    final uri = Uri.parse('$baseUrl/$statementId');
    final token = await AuthService.getToken();
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return StatementResponse.fromJson(jsonData);
    }

    throw Exception('Failed to fetch statement details: ${response.body}');
  }

  /// GET /api/statements/{statement_id}/export-pdf
  /// Generates and exports a premium PDF report cross-platform
  static Future<void> exportStatementPdf(String statementId) async {
    final uri = Uri.parse('$baseUrl/$statementId/export-pdf');
    final token = await AuthService.getToken();
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('Failed to export PDF: ${response.body}');
    }

    if (kIsWeb) {
      // Secure, high-performance web sandbox download execution via JS interop
      final base64Pdf = base64Encode(response.bodyBytes);
      js.context.callMethod('eval', ["""
        var byteCharacters = atob('$base64Pdf');
        var byteNumbers = new Array(byteCharacters.length);
        for (var i = 0; i < byteCharacters.length; i++) {
            byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        var byteArray = new Uint8Array(byteNumbers);
        var blob = new Blob([byteArray], {type: 'application/pdf'});
        var link = document.createElement('a');
        link.href = window.URL.createObjectURL(blob);
        link.download = 'StatementX_Report_$statementId.pdf';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      """]);
    } else {
      // Mobile Documents directory storage and immediate display
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/StatementX_Report_$statementId.pdf';
      final file = io.File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      await OpenFile.open(filePath);
    }
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
