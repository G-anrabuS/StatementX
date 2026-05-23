import 'package:flutter/material.dart';
import '../models/statement_model.dart';
import '../services/statement_service.dart';
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
        return const Color(0xFFF97316);
      case 'shopping':
        return const Color(0xFF8B5CF6);
      case 'travel':
        return const Color(0xFF3B82F6);
      case 'income':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_cart_rounded;
      case 'travel':
        return Icons.directions_car_rounded;
      case 'income':
        return Icons.account_balance_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  Widget buildTransactionCard(Transaction txn) {
    final category = txn.category ?? 'Others';
    final categoryColor = getCategoryColor(category);
    final categoryIcon = getCategoryIcon(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Flexible(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.narration,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  txn.date,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(), // Pushes amount block completely rightward
          SizedBox(
            width:
                140, // Expanded slightly for safe web rendering without text clipping
            child: Column(
              crossAxisAlignment: CrossAxisAlignment
                  .end, // FIXED: Force right alignment inside Column
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  txn.debit > 0
                      ? '- ₹${txn.debit.toStringAsFixed(0)}'
                      : '+ ₹${txn.credit.toStringAsFixed(0)}',
                  textAlign: TextAlign
                      .right, // FIXED: Force right text alignment rule on Web
                  style: TextStyle(
                    color: txn.debit > 0
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Balance: ₹${txn.balance.toStringAsFixed(0)}',
                  textAlign: TextAlign
                      .right, // FIXED: Force right text alignment rule on Web
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.4,
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
    if (widget.statementId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load insights')),
        );
      }
      return;
    }

    setState(() {
      isLoadingInsights = true;
    });

    try {
      final insights = await StatementService.getStatementInsights(
        widget.statementId!,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InsightsScreen(
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
      if (mounted) {
        setState(() {
          isLoadingInsights = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE9ECF2)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 28,
              vertical: isMobile ? 18 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.transactions.length} Transactions',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9ECF2)),
                          ),
                          child: const Icon(
                            Icons.filter_list_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                    Color(0xff6D5DFB),
                                    Color(0xff7C4DFF),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.transactions.length,
                    itemBuilder: (context, index) {
                      return buildTransactionCard(widget.transactions[index]);
                    },
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
