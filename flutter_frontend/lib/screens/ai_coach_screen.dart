import 'package:flutter/material.dart';
import '../services/statement_service.dart';
import '../theme/app_theme.dart';

class AICoachData {
  final String summary;
  final List<dynamic> recommendations;

  AICoachData({required this.summary, required this.recommendations});

  factory AICoachData.fromJson(Map<String, dynamic> json) {
    return AICoachData(
      summary: json['summary'] ?? 'No overview narrative generated.',
      recommendations: json['recommendations'] as List? ?? [],
    );
  }
}

class AICoachScreen extends StatefulWidget {
  final String statementId;
  const AICoachScreen({super.key, required this.statementId});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  late Future<AICoachData> _coachFuture;

  // Translation State
  String? translatedSummary;
  List<Map<String, String>> translatedRecommendations = [];
  bool isTranslated = false;
  bool isTranslating = false;

  @override
  void initState() {
    super.initState();
    _coachFuture = _fetchAICoachData();
  }

  Future<AICoachData> _fetchAICoachData() async {
    final rawJson = await StatementService.getStatementAICoach(
      widget.statementId,
    );
    return AICoachData.fromJson(rawJson);
  }

  void _toggleLanguage(AICoachData data) async {
    if (isTranslated) {
      setState(() => isTranslated = false);
      return;
    }

    setState(() => isTranslating = true);

    // Collect all text
    List<String> items = [data.summary];
    for (var rec in data.recommendations) {
      if (rec is Map<String, dynamic>) {
        items.add(rec['title'] ?? '');
        items.add(rec['description'] ?? '');
      }
    }

    try {
      List<String> translated = await StatementService.translatePackedList(
        items: items,
        targetLang: 'hi', // Target Hindi
      );

      setState(() {
        translatedSummary = translated[0];
        translatedRecommendations = [];
        int idx = 1;
        for (var rec in data.recommendations) {
          if (rec is Map<String, dynamic>) {
            translatedRecommendations.add({
              'title': translated[idx++],
              'description': translated[idx++],
            });
          }
        }
        isTranslated = true;
      });
    } finally {
      setState(() => isTranslating = false);
    }
  }

  Color _getImpactColor(String? impact) {
    switch (impact?.toLowerCase()) {
      case 'high':
        return const Color(0xFFC62828);
      case 'medium':
        return const Color(0xFFE65100);
      case 'low':
        return const Color(0xFF1565C0);
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec, int index) {
    final String title = isTranslated
        ? (translatedRecommendations[index]['title'] ?? '')
        : (rec['title'] ?? '');
    final String description = isTranslated
        ? (translatedRecommendations[index]['description'] ?? '')
        : (rec['description'] ?? '');
    final String impact = rec['impact'] ?? 'Medium';
    final Color impactColor = _getImpactColor(impact);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: impactColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$impact Impact',
                  style: TextStyle(
                    color: impactColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('AI Financial Coach'),
        actions: [
          IconButton(
            icon: Icon(
              isTranslated
                  ? Icons.g_translate_rounded
                  : Icons.translate_rounded,
            ),
            onPressed: isTranslating
                ? null
                : () => _fetchAICoachData().then((d) => _toggleLanguage(d)),
          ),
        ],
      ),
      body: FutureBuilder<AICoachData>(
        future: _coachFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final coachData = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isTranslated ? translatedSummary! : coachData.summary),
                const SizedBox(height: 28),
                ...List.generate(
                  coachData.recommendations.length,
                  (i) =>
                      _buildRecommendationCard(coachData.recommendations[i], i),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
