import 'package:flutter/material.dart';
import '../services/statement_service.dart';
import '../theme/app_theme.dart';

class AICoachData {
  final String summary;
  final List<dynamic>
  recommendations; // Kept as dynamic to parse JSON maps flexibly

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

  Color _getImpactColor(String? impact) {
    switch (impact?.toLowerCase()) {
      case 'high':
        return const Color(0xFFC62828); // Premium danger red
      case 'medium':
        return const Color(0xFFE65100); // Warning orange
      case 'low':
        return const Color(0xFF1565C0); // Information tech blue
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final String title = rec['title'] ?? 'Budget Adjustment Option';
    final String description = rec['description'] ?? '';
    final String actionItem = rec['action_item'] ?? '';
    final String targetCategory = rec['target_category'] ?? '';
    final String impact = rec['impact'] ?? 'Medium';
    final Color impactColor = _getImpactColor(impact);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Category and Impact Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (targetCategory.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    targetCategory.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
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
          // Strategy Title
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Detailed Description Context
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          // Concrete Structured Action Step Drawer Block
          if (actionItem.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.borderLight),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 16,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, height: 1.4),
                      children: [
                        TextSpan(
                          text: 'Action Step: ',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: actionItem,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'AI Financial Coach',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<AICoachData>(
        future: _coachFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Coach service offline: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text('No overview narrative generated.'),
            );
          }

          final coachData = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Executive Assessment',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    coachData.summary,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Prioritized Actions',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                if (coachData.recommendations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'No urgent risk corrections flagged.',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                else
                  ...coachData.recommendations.map((item) {
                    // Safe verification loop to handle map conversion properties
                    if (item is Map<String, dynamic>) {
                      return _buildRecommendationCard(item);
                    }
                    // Graceful fallback string card container if item properties serialize flat
                    return Card(
                      color: AppColors.surfaceLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          item.toString(),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
