import 'package:flutter/material.dart';
import '../models/insights_model.dart';
import '../theme/app_theme.dart';
// Import the new intelligence screen layers
import 'visualization_screen.dart';
import 'ai_coach_screen.dart';
import 'chat_bot_screen.dart';

class InsightsScreen extends StatefulWidget {
  final String statementId; // Added to map backend endpoints cleanly
  final String bankName;
  final StatementInsights insights;
  final int totalTransactions;

  const InsightsScreen({
    super.key,
    required this.statementId,
    required this.bankName,
    required this.insights,
    required this.totalTransactions,
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFE65100);
      case 'shopping':
        return const Color(0xFF6A1B9A);
      case 'travel':
        return const Color(0xFF1565C0);
      case 'income':
        return AppColors.primaryGreen;
      case 'utilities':
        return const Color(0xFFC2185B);
      case 'entertainment':
        return const Color(0xFF00838F);
      default:
        return AppColors.secondaryTeal;
    }
  }

  Widget _buildQuickActionMenu(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Ledger Intelligence',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionButton(
                  context,
                  label: 'Analytics Dashboard',
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFF1565C0),
                  targetScreen: VisualizationScreen(
                    statementId: widget.statementId,
                  ),
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  context,
                  label: 'AI Executive Coach',
                  icon: Icons.bolt,
                  color: const Color(0xFFE65100),
                  targetScreen: AICoachScreen(statementId: widget.statementId),
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  context,
                  label: 'Semantic Chat',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryColor,
                  targetScreen: ChatBotScreen(statementId: widget.statementId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Widget targetScreen,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.08),
        foregroundColor: color,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtext,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isMobile ? 12 : 13,
                  ),
                ),
              ),
              Icon(icon, color: color, size: isMobile ? 16 : 18),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isMobile ? 20 : 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (widget.insights.categoryBreakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Center(
          child: Text(
            'No spending data available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final sortedCategories = widget.insights.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
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
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...topCategories.map((entry) {
            final category = entry.key;
            final amount = entry.value;
            final total = widget.insights.totalExpense > 0
                ? (amount / widget.insights.totalExpense * 100)
                : 0.0;
            final color = getCategoryColor(category);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: total / 100,
                      backgroundColor: AppColors.bgLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        color.withOpacity(0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${total.toStringAsFixed(1)}% of expenses',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubscriptions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
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
          const Text(
            'Recurring Subscriptions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.insights.subscriptions.map((sub) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.vendor,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        sub.frequency,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${sub.averageAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        sub.lastTransactionDate,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnomalies() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
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
          const Text(
            'Anomalies Detected',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.insights.anomalies.take(4).map((anomaly) {
            final color = anomaly.type.toLowerCase() == 'high_value'
                ? const Color(0xFFC62828)
                : const Color(0xFFE65100);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          anomaly.narration,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        anomaly.type.replaceAll('_', ' '),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    anomaly.reason,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        anomaly.date,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '₹${anomaly.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Insights',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 28,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.bankName} Analysis',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.totalTransactions} transactions analyzed',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Inject the Quick Actions Analytics Control Hub
                _buildQuickActionMenu(context),

                GridView.count(
                  crossAxisCount: isMobile ? 2 : 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isMobile ? 1.35 : 1.1,
                  children: [
                    _buildStatCard(
                      label: 'Total Income',
                      value:
                          '₹${widget.insights.totalIncome.toStringAsFixed(0)}',
                      icon: Icons.arrow_upward,
                      color: AppColors.primaryGreen,
                      subtext: 'Credits',
                      isMobile: isMobile,
                    ),
                    _buildStatCard(
                      label: 'Total Expense',
                      value:
                          '₹${widget.insights.totalExpense.toStringAsFixed(0)}',
                      icon: Icons.arrow_downward,
                      color: const Color(0xFFC62828),
                      subtext: 'Debits',
                      isMobile: isMobile,
                    ),
                    _buildStatCard(
                      label: 'Net Savings',
                      value:
                          '₹${widget.insights.netSavings.toStringAsFixed(0)}',
                      icon: Icons.wallet_rounded,
                      color: AppColors.secondaryColor,
                      subtext: 'Saved',
                      isMobile: isMobile,
                    ),
                    _buildStatCard(
                      label: 'Saving Rate',
                      value:
                          '${(widget.insights.savingRate * 100).toStringAsFixed(1)}%',
                      icon: Icons.pie_chart,
                      color: const Color(0xFF6A1B9A),
                      subtext: 'Ratio',
                      isMobile: isMobile,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCategoryBreakdown(),
                if (widget.insights.subscriptions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSubscriptions(),
                ],
                if (widget.insights.anomalies.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildAnomalies(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
