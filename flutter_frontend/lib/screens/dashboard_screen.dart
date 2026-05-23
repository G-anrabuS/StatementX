
import 'package:flutter/material.dart';

import '../models/statement_model.dart';

class DashboardScreen extends StatelessWidget {
  final StatementResponse data;

  const DashboardScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            
            Text(
              data.bankName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            
            Text(
              'Total Transactions: ${data.totalTransactions}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // TRANSACTION LIST
            Expanded(
              child: ListView.builder(
                itemCount: data.transactions.length,

                itemBuilder: (context, index) {

                  final txn = data.transactions[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),

                    child: Padding(
                      padding: const EdgeInsets.all(14),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          // DATE
                          Text(
                            txn.date,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // NARRATION
                          Text(
                            txn.narration,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,

                            children: [

                              // DEBIT
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  const Text(
                                    'Debit',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),

                                  Text(
                                    '₹${txn.debit.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              // CREDIT
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  const Text(
                                    'Credit',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),

                                  Text(
                                    '₹${txn.credit.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              // BALANCE
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  const Text(
                                    'Balance',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),

                                  Text(
                                    '₹${txn.balance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

