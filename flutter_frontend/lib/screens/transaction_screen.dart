import 'package:flutter/material.dart';
import '../models/statement_model.dart';

class TransactionsScreen extends StatelessWidget {
  final List<Transaction> transactions;

  const TransactionsScreen({
    super.key,
    required this.transactions,
  });

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

    final categoryColor =
        getCategoryColor(category);

    final categoryIcon =
        getCategoryIcon(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: const Color(0xFFE9ECF2),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // CATEGORY ICON
          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color:
                  categoryColor.withOpacity(0.1),

              borderRadius:
                  BorderRadius.circular(14),
            ),

            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // LEFT SECTION
          Flexible(
            flex: 4,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  txn.narration,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 5),

                // CATEGORY + DATE
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      txn.category ?? 'Others',

                      style: const TextStyle(
                        color:
                            Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      txn.date,

                      style: const TextStyle(
                        color:
                            Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // RIGHT SECTION
         const Spacer(),

const Spacer(),

SizedBox(
  width: 120,

  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,

    children: [
    Text(
      txn.debit > 0
          ? '- ₹${txn.debit.toStringAsFixed(0)}'
          : '+ ₹${txn.credit.toStringAsFixed(0)}',

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
      'Balance\n₹${txn.balance.toStringAsFixed(0)}',

      textAlign: TextAlign.start,

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

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width <
            800;

    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        scrolledUnderElevation: 0,

        iconTheme: const IconThemeData(
          color: Color(0xFF111827),
        ),

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
          preferredSize:
              const Size.fromHeight(1),

          child: Container(
            height: 1,
            color:
                const Color(0xFFE9ECF2),
          ),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 1100,
          ),

          child: Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal:
                  isMobile ? 16 : 28,

              vertical:
                  isMobile ? 18 : 24,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    Text(
                      '${transactions.length} Transactions',

                      style:
                          const TextStyle(
                        color:
                            Color(0xFF64748B),

                        fontSize: 15,

                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.all(
                              10),

                      decoration:
                          BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                                    12),

                        border: Border.all(
                          color:
                              const Color(
                            0xFFE9ECF2,
                          ),
                        ),
                      ),

                      child: const Icon(
                        Icons
                            .filter_list_rounded,

                        size: 20,

                        color: Color(
                            0xFF64748B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: ListView.builder(
                    itemCount:
                        transactions.length,

                    itemBuilder:
                        (context, index) {
                      return buildTransactionCard(
                        transactions[index],
                      );
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

