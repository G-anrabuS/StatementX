class Transaction {
  final String date;
  final String narration;
  final double debit;
  final double credit;
  final double balance;
  final String? category;
  final String? subCategory;
  final double? confidence;

  Transaction({
    required this.date,
    required this.narration,
    required this.debit,
    required this.credit,
    required this.balance,
    this.category,
    this.subCategory,
    this.confidence,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: json['date'],
      narration: json['narration'],
      debit: (json['debit'] ?? 0).toDouble(),
      credit: (json['credit'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      category: json['category'],
      subCategory: json['sub_category'],
      confidence: json['confidence']?.toDouble(),
    );
  }
}

class StatementResponse {
  final String bankName;
  final int totalTransactions;
  final List<Transaction> transactions;

  StatementResponse({
    required this.bankName,
    required this.totalTransactions,
    required this.transactions,
  });

  factory StatementResponse.fromJson(Map<String, dynamic> json) {
    return StatementResponse(
      bankName: json['bank_name'],
      totalTransactions: json['total_transactions'],
      transactions: (json['transactions'] as List)
          .map((txn) => Transaction.fromJson(txn))
          .toList(),
    );
  }
}
