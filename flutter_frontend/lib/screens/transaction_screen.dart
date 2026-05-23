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
        return Colors.orange;

      case 'shopping':
        return Colors.pinkAccent;

      case 'travel':
        return Colors.blueAccent;

      case 'income':
        return Colors.green;

      default:
        return Colors.purpleAccent;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;

      case 'shopping':
        return Icons.shopping_bag_rounded;

      case 'travel':
        return Icons.directions_car;

      case 'income':
        return Icons.account_balance_wallet;

      default:
        return Icons.category_rounded;
    }
  }

  Widget buildTransactionCard(Transaction txn) {
    final category =
        txn.category ?? 'Others';

    final categoryColor =
        getCategoryColor(category);

    final categoryIcon =
        getCategoryIcon(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xff12052E),
        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color:
              Colors.deepPurple.withOpacity(0.25),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color:
                  categoryColor.withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(18),
            ),

            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  txn.narration,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: categoryColor
                            .withOpacity(0.15),

                        borderRadius:
                            BorderRadius.circular(
                                30),
                      ),

                      child: Text(
                        category,
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      txn.date,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [
              Text(
                txn.debit > 0
                    ? '-₹${txn.debit.toStringAsFixed(0)}'
                    : '+₹${txn.credit.toStringAsFixed(0)}',

                style: TextStyle(
                  color: txn.debit > 0
                      ? Colors.redAccent
                      : Colors.greenAccent,
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Balance ₹${txn.balance.toStringAsFixed(0)}',

                style: TextStyle(
                  color: Colors.white
                      .withOpacity(0.55),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xff070014),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        centerTitle: true,

        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(22),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              '${transactions.length} Transactions',

              style: TextStyle(
                color:
                    Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,

                itemBuilder: (context, index) {
                  return buildTransactionCard(
                    transactions[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
