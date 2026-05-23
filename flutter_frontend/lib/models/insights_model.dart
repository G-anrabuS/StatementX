class SubscriptionItem {
  final String vendor;
  final double averageAmount;
  final String frequency;
  final String lastTransactionDate;

  SubscriptionItem({
    required this.vendor,
    required this.averageAmount,
    required this.frequency,
    required this.lastTransactionDate,
  });

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      vendor: json['vendor'] ?? '',
      averageAmount: (json['average_amount'] ?? 0).toDouble(),
      frequency: json['frequency'] ?? '',
      lastTransactionDate: json['last_transaction_date'] ?? '',
    );
  }
}

class AnomalyItem {
  final String transactionId;
  final String date;
  final String narration;
  final double amount;
  final String type;
  final String reason;

  AnomalyItem({
    required this.transactionId,
    required this.date,
    required this.narration,
    required this.amount,
    required this.type,
    required this.reason,
  });

  factory AnomalyItem.fromJson(Map<String, dynamic> json) {
    return AnomalyItem(
      transactionId: json['transaction_id'] ?? '',
      date: json['date'] ?? '',
      narration: json['narration'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}

class StatementInsights {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingRate;
  final String highestSpendingCategory;
  final Map<String, double> categoryBreakdown;
  final List<SubscriptionItem> subscriptions;
  final List<AnomalyItem> anomalies;

  StatementInsights({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingRate,
    required this.highestSpendingCategory,
    required this.categoryBreakdown,
    required this.subscriptions,
    required this.anomalies,
  });

  factory StatementInsights.fromJson(Map<String, dynamic> json) {
    return StatementInsights(
      totalIncome: (json['total_income'] ?? 0).toDouble(),
      totalExpense: (json['total_expense'] ?? 0).toDouble(),
      netSavings: (json['net_savings'] ?? 0).toDouble(),
      savingRate: (json['saving_rate'] ?? 0).toDouble(),
      highestSpendingCategory: json['highest_spending_category'] ?? '',
      categoryBreakdown: Map<String, double>.from(
        (json['category_breakdown'] as Map? ?? {}).map(
          (key, value) => MapEntry(key.toString(), (value ?? 0).toDouble()),
        ),
      ),
      subscriptions: (json['subscriptions'] as List? ?? [])
          .map((item) => SubscriptionItem.fromJson(item))
          .toList(),
      anomalies: (json['anomalies'] as List? ?? [])
          .map((item) => AnomalyItem.fromJson(item))
          .toList(),
    );
  }
}
