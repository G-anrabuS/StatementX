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
        return const Color(0xFFC62828);
      case 'medium':
        return const Color(0xFFE65100);
      case 'low':
        return const Color(0xFF1565C0);
      default:
        return AppColors.textSecondary;
    }
  }

  List<Widget> _buildSegmentedSummary(String summary) {
    final List<Widget> widgets = [];
    final sections = summary.split('###');
    
    for (var section in sections) {
      if (section.trim().isEmpty) continue;
      
      final lines = section.split('\n');
      final String title = lines[0].trim();
      final String content = lines.skip(1).join('\n').trim();
      
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
              Text(
                content,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final String title = rec['title'] ?? 'Recommendation';
    final String description = rec['description'] ?? '';
    final String impact = rec['impact'] ?? 'Medium';
    final String actionItem = rec['action_item'] ?? '';
    final String targetCategory = rec['target_category'] ?? 'General';
    final Color impactColor = _getImpactColor(impact);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar reflecting the impact priority
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: impactColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Impact Priority Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: impactColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$impact Priority',
                            style: TextStyle(
                              color: impactColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        // Target Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tag_rounded, size: 12, color: AppColors.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                targetCategory,
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    if (actionItem.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: AppColors.secondaryTeal, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 12.5, height: 1.35),
                                children: [
                                  const TextSpan(
                                    text: 'Action Step: ',
                                    style: TextStyle(color: AppColors.secondaryTeal, fontWeight: FontWeight.bold),
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
              ),
            ),
          ],
        ),
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
          'AI Strategic Wealth Coach',
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
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            );
          }
          final coachData = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top premium title section
                const Row(
                  children: [
                    Icon(Icons.psychology_outlined, color: AppColors.primaryColor, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'AI Executive Strategy Briefing',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                
                // Render beautifully segmented, clean native card summaries
                ..._buildSegmentedSummary(coachData.summary),
                
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.task_alt_rounded, color: AppColors.secondaryTeal, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Prioritized Wealth Action Roadmap',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                
                // Render tactical prioritized cards
                ...List.generate(
                  coachData.recommendations.length,
                  (i) {
                    final item = coachData.recommendations[i];
                    if (item is Map<String, dynamic>) {
                      return _buildRecommendationCard(item);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
