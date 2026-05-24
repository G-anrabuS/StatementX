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
        return const Color(0xFFE65100); // Rich safety orange
      case 'shopping':
        return const Color(0xFF6A1B9A); // Royal amethyst purple
      case 'travel':
        return const Color(0xFF1565C0); // Tech cobalt blue
      case 'income':
        return AppColors.primaryGreen; // Financial emerald green
      default:
        return AppColors.secondaryTeal; // Corporate steel teal
    }
  }

  Widget buildTransactionCard(Transaction txn) {
    final category = txn.category ?? 'Others';
    final indicatorColor = getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent indicator line
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Narrative details block
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
                // FIXED: Changed from Row to Wrap to enforce side-by-side alignment on both Web & Android
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing:
                      6, // Adds uniform space between elements horizontally
                  runSpacing:
                      4, // Handles elegant multi-line wrapping safely if text gets too long
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
          const SizedBox(width: 8),
          // Financial values summary block
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  txn.debit > 0
                      ? '- ₹${txn.debit.toStringAsFixed(0)}'
                      : '+ ₹${txn.credit.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: txn.debit > 0
                        ? const Color(0xFFD32F2F)
                        : AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bal: ₹${txn.balance.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoadingInsights = false);
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
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 28,
              vertical: 24,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.transactions.length} Transactions',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isLoadingInsights ? null : _loadInsights,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryGreen,
                                AppColors.secondaryTeal,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isLoadingInsights
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  children: [
                                    Icon(
                                      Icons.insights_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Insights',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.transactions.length,
                    itemBuilder: (context, index) =>
                        buildTransactionCard(widget.transactions[index]),
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
