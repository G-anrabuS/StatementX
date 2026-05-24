import 'package:flutter/material.dart';
import '../models/statement_model.dart';
import '../services/statement_service.dart';
import '../theme/app_theme.dart';
import 'insights_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final String bankName;
  final String? statementId;

  const TransactionsScreen({
    super.key,
    required this.transactions,
    required this.bankName,
    this.statementId,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool isLoadingInsights = false;

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
      default:
        return AppColors.primaryColor;
    }
  }

  Widget buildTransactionCard(Transaction txn, int index) {
    final category = txn.category ?? 'Others';
    final indicatorColor = getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.narration,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: indicatorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      txn.date,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  txn.debit > 0
                      ? '- ₹${txn.debit.toStringAsFixed(0)}'
                      : '+ ₹${txn.credit.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: txn.debit > 0
                        ? const Color(0xFFD32F2F)
                        : AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Bal: ₹${txn.balance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _loadInsights() async {
    if (widget.statementId == null) return;
    setState(() => isLoadingInsights = true);
    try {
      final insights = await StatementService.getStatementInsights(
        widget.statementId!,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InsightsScreen(
              statementId: widget.statementId!,
              bankName: widget.bankName,
              insights: insights,
              totalTransactions: widget.transactions.length,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoadingInsights = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.transactions.length} Transactions',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    ElevatedButton.icon(
                      onPressed: isLoadingInsights ? null : _loadInsights,
                      icon: const Icon(Icons.insights_rounded),
                      label: const Text('Insights'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.transactions.length,
                    itemBuilder: (context, index) =>
                        buildTransactionCard(widget.transactions[index], index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
