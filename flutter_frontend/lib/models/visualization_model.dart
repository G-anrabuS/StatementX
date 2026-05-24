class CashFlowDataPoint {
  final String date;
  final double income;
  final double expense;
  final double cumulativeIncome;
  final double cumulativeExpense;
  final double netCashFlow;
  final double balance;

  CashFlowDataPoint({
    required this.date,
    required this.income,
    required this.expense,
    required this.cumulativeIncome,
    required this.cumulativeExpense,
    required this.netCashFlow,
    required this.balance,
  });

  factory CashFlowDataPoint.fromJson(Map<String, dynamic> json) {
    return CashFlowDataPoint(
      date: json['date'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
      cumulativeIncome: (json['cumulative_income'] ?? 0).toDouble(),
      cumulativeExpense: (json['cumulative_expense'] ?? 0).toDouble(),
      netCashFlow: (json['net_cash_flow'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }
}

class BudgetAllocation {
  final double needsAmount;
  final double needsPercentage;
  final double needsTargetPercentage;
  final double wantsAmount;
  final double wantsPercentage;
  final double wantsTargetPercentage;
  final double savingsAmount;
  final double savingsPercentage;
  final double savingsTargetPercentage;

  BudgetAllocation({
    required this.needsAmount,
    required this.needsPercentage,
    required this.needsTargetPercentage,
    required this.wantsAmount,
    required this.wantsPercentage,
    required this.wantsTargetPercentage,
    required this.savingsAmount,
    required this.savingsPercentage,
    required this.savingsTargetPercentage,
  });

  factory BudgetAllocation.fromJson(Map<String, dynamic> json) {
    return BudgetAllocation(
      needsAmount: (json['needs_amount'] ?? 0).toDouble(),
      needsPercentage: (json['needs_percentage'] ?? 0).toDouble(),
      needsTargetPercentage: (json['needs_target_percentage'] ?? 50.0)
          .toDouble(),
      wantsAmount: (json['wants_amount'] ?? 0).toDouble(),
      wantsPercentage: (json['wants_percentage'] ?? 0).toDouble(),
      wantsTargetPercentage: (json['wants_target_percentage'] ?? 30.0)
          .toDouble(),
      savingsAmount: (json['savings_amount'] ?? 0).toDouble(),
      savingsPercentage: (json['savings_percentage'] ?? 0).toDouble(),
      savingsTargetPercentage: (json['savings_target_percentage'] ?? 20.0)
          .toDouble(),
    );
  }
}

class CategoryVisualItem {
  final String category;
  final double amount;
  final double percentage;
  final int transactionCount;
  final String color;

  CategoryVisualItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    required this.color,
  });

  factory CategoryVisualItem.fromJson(Map<String, dynamic> json) {
    return CategoryVisualItem(
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      transactionCount: json['transaction_count'] ?? 0,
      color: json['color'] ?? '#757575',
    );
  }
}

class SpendingPattern {
  final double weekdayTotal;
  final double weekendTotal;
  final double weekdayAverage;
  final double weekendAverage;
  final int weekdayCount;
  final int weekendCount;

  SpendingPattern({
    required this.weekdayTotal,
    required this.weekendTotal,
    required this.weekdayAverage,
    required this.weekendAverage,
    required this.weekdayCount,
    required this.weekendCount,
  });

  factory SpendingPattern.fromJson(Map<String, dynamic> json) {
    return SpendingPattern(
      weekdayTotal: (json['weekday_total'] ?? 0).toDouble(),
      weekendTotal: (json['weekend_total'] ?? 0).toDouble(),
      weekdayAverage: (json['weekday_average'] ?? 0).toDouble(),
      weekendAverage: (json['weekend_average'] ?? 0).toDouble(),
      weekdayCount: json['weekday_count'] ?? 0,
      weekendCount: json['weekend_count'] ?? 0,
    );
  }
}

class HealthIndicators {
  final double savingsRate;
  final double burnRate;
  final double discretionarySpendRatio;
  final double essentialSpendRatio;
  final double healthScore;
  final String healthRating;
  final double liquidityRatio;
  final double averageDailyExpense;
  final double savingsConsistency;

  HealthIndicators({
    required this.savingsRate,
    required this.burnRate,
    required this.discretionarySpendRatio,
    required this.essentialSpendRatio,
    required this.healthScore,
    required this.healthRating,
    required this.liquidityRatio,
    required this.averageDailyExpense,
    required this.savingsConsistency,
  });

  factory HealthIndicators.fromJson(Map<String, dynamic> json) {
    return HealthIndicators(
      savingsRate: (json['savings_rate'] ?? 0).toDouble(),
      burnRate: (json['burn_rate'] ?? 0).toDouble(),
      discretionarySpendRatio: (json['discretionary_spend_ratio'] ?? 0)
          .toDouble(),
      essentialSpendRatio: (json['essential_spend_ratio'] ?? 0).toDouble(),
      healthScore: (json['health_score'] ?? 0).toDouble(),
      healthRating: json['health_rating'] ?? 'Critical',
      liquidityRatio: (json['liquidity_ratio'] ?? 0).toDouble(),
      averageDailyExpense: (json['average_daily_expense'] ?? 0).toDouble(),
      savingsConsistency: (json['savings_consistency'] ?? 0).toDouble(),
    );
  }
}

class VisualizationResponse {
  final String statementId;
  final String bankName;
  final HealthIndicators healthIndicators;
  final List<CashFlowDataPoint> cashFlowTimeline;
  final BudgetAllocation budgetAllocation;
  final List<CategoryVisualItem> categoryBreakdown;
  final SpendingPattern spendingPattern;

  VisualizationResponse({
    required this.statementId,
    required this.bankName,
    required this.healthIndicators,
    required this.cashFlowTimeline,
    required this.budgetAllocation,
    required this.categoryBreakdown,
    required this.spendingPattern,
  });

  factory VisualizationResponse.fromJson(Map<String, dynamic> json) {
    return VisualizationResponse(
      statementId: json['statement_id'] ?? '',
      bankName: json['bank_name'] ?? '',
      healthIndicators: HealthIndicators.fromJson(
        json['health_indicators'] ?? {},
      ),
      cashFlowTimeline: (json['cash_flow_timeline'] as List? ?? [])
          .map((item) => CashFlowDataPoint.fromJson(item))
          .toList(),
      budgetAllocation: BudgetAllocation.fromJson(
        json['budget_allocation'] ?? {},
      ),
      categoryBreakdown: (json['category_breakdown'] as List? ?? [])
          .map((item) => CategoryVisualItem.fromJson(item))
          .toList(),
      spendingPattern: SpendingPattern.fromJson(json['spending_pattern'] ?? {}),
    );
  }
}
