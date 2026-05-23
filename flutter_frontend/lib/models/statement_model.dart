class Transaction {
  final String date;
  final String narration;
  final double debit;
  final double credit;
  final double balance;

  Transaction({
    required this.date,
    required this.narration,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: json['date'],
      narration: json['narration'],
      debit: (json['debit'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
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
          .map((e) => Transaction.fromJson(e))
          .toList(),
    );
  }
}
