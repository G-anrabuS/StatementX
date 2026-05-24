import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/visualization_model.dart';
import '../services/statement_service.dart';
import '../theme/app_theme.dart';

class VisualizationScreen extends StatefulWidget {
  final String statementId;

  const VisualizationScreen({super.key, required this.statementId});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen> {
  late Future<VisualizationResponse> _visualizationFuture;

  @override
  void initState() {
    super.initState();
    _visualizationFuture = StatementService.getStatementVisualization(
      widget.statementId,
    );
  }

  Color parseHexColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  Color getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return AppColors.primaryGreen;
      case 'good':
        return AppColors.secondaryTeal;
      case 'fair':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFFC62828);
    }
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
          'Financial Analytics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<VisualizationResponse>(
        future: _visualizationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading intelligence dashboard: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFC62828)),
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text('No visualization metrics generated.'),
            );
          }

          final data = snapshot.data!;
          return Center(
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
                      '${data.bankName} Dashboard',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildHealthOverviewCard(data.healthIndicators, isMobile),
                    const SizedBox(height: 24),
                    if (isMobile) ...[
                      _buildCategoryDonutCard(data.categoryBreakdown),
                      const SizedBox(height: 24),
                      _buildBudgetFrameworkCard(data.budgetAllocation),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildCategoryDonutCard(
                              data.categoryBreakdown,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildBudgetFrameworkCard(
                              data.budgetAllocation,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildCashFlowTimelineCard(data.cashFlowTimeline, isMobile),
                    const SizedBox(height: 24),
                    _buildSpendingPatternsCard(data.spendingPattern, isMobile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthOverviewCard(HealthIndicators metrics, bool isMobile) {
    final ratingColor = getRatingColor(metrics.healthRating);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Financial Health Score',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${metrics.healthScore.toStringAsFixed(0)} / 100',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ratingColor.withOpacity(0.3)),
                ),
                child: Text(
                  metrics.healthRating,
                  style: TextStyle(
                    color: ratingColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppColors.borderLight),
          GridView.count(
            crossAxisCount: isMobile ? 2 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isMobile ? 2.2 : 2.5,
            children: [
              _buildMetricSubItem(
                'Savings Rate',
                '${metrics.savingsRate.toStringAsFixed(1)}%',
              ),
              _buildMetricSubItem(
                'Burn Rate',
                '${metrics.burnRate.toStringAsFixed(1)}%',
              ),
              _buildMetricSubItem(
                'Daily Avg Spend',
                '₹${metrics.averageDailyExpense.toStringAsFixed(0)}',
              ),
              _buildMetricSubItem(
                'Runway Ratio',
                '${metrics.liquidityRatio.toStringAsFixed(1)} months',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSubItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDonutCard(List<CategoryVisualItem> breakdown) {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Allocation',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: breakdown.isEmpty
                ? const Center(child: Text('No allocations recorded.'))
                : Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 45,
                            sections: breakdown.map((item) {
                              return PieChartSectionData(
                                color: parseHexColor(item.color),
                                value: item.percentage,
                                radius: 18,
                                showTitle: false,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: breakdown.map((item) {
                              final itemColor = parseHexColor(item.color);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      color: itemColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${item.percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: itemColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetFrameworkCard(BudgetAllocation allocation) {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '50/30/20 Budget Compliance',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBudgetFrameworkBar(
                  'Essential Needs',
                  allocation.needsPercentage,
                  allocation.needsTargetPercentage,
                  const Color(0xFF1565C0),
                ),
                _buildBudgetFrameworkBar(
                  'Discretionary Wants',
                  allocation.wantsPercentage,
                  allocation.wantsTargetPercentage,
                  const Color(0xFF6A1B9A),
                ),
                _buildBudgetFrameworkBar(
                  'Savings/Surplus',
                  allocation.savingsPercentage,
                  allocation.savingsTargetPercentage,
                  AppColors.primaryGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetFrameworkBar(
    String label,
    double actual,
    double target,
    Color color,
  ) {
    final validatedActual = actual.clamp(0.0, 100.0) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Actual: ${actual.toStringAsFixed(1)}% (Target: ${target.toStringAsFixed(0)}%)',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: validatedActual,
            backgroundColor: AppColors.bgLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowTimelineCard(
    List<CashFlowDataPoint> timeline,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash Flow History',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: timeline.isEmpty
                ? const Center(
                    child: Text(
                      'No timeline dataset sequential metrics found.',
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              int idx = value.toInt();
                              if (idx >= 0 && idx < timeline.length) {
                                // Downsample X-axis text ticks to prevent visual collision text clusters
                                if (timeline.length > 6 &&
                                    idx % (timeline.length ~/ 4) != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    timeline[idx].date,
                                    style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: timeline
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(e.key.toDouble(), e.value.income),
                              )
                              .toList(),
                          isCurved: true,
                          color: AppColors.primaryGreen,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: timeline
                              .asMap()
                              .entries
                              .map(
                                (e) =>
                                    FlSpot(e.key.toDouble(), e.value.expense),
                              )
                              .toList(),
                          isCurved: true,
                          color: const Color(0xFFC62828),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendIndicator(
                AppColors.primaryGreen,
                'Inflows / Credits',
              ),
              const SizedBox(width: 24),
              _buildLegendIndicator(
                const Color(0xFFC62828),
                'Outflows / Debits',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSpendingPatternsCard(SpendingPattern pattern, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temporal Spending Distribution',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildPatternStatBox(
                  'Weekday Expenses',
                  '₹${pattern.weekdayTotal.toStringAsFixed(0)}',
                  'Avg: ₹${pattern.weekdayAverage.toStringAsFixed(0)}/txn',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPatternStatBox(
                  'Weekend Expenses',
                  '₹${pattern.weekendTotal.toStringAsFixed(0)}',
                  'Avg: ₹${pattern.weekendAverage.toStringAsFixed(0)}/txn',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternStatBox(String title, String aggregate, String meta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            aggregate,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
