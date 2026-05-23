import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/statement_model.dart';
import '../services/statement_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool isLoading = false;
  StatementResponse? statementData;
  String? errorMessage;

  Future<void> pickAndUploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // important for web support
    );

    if (result == null) return;

    final file = result.files.single;

    if (file.bytes == null) {
      setState(() {
        errorMessage = 'Unable to read selected PDF file.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      statementData = null;
      errorMessage = null;
    });

    try {
      final response = await StatementService.uploadStatement(
        file.name,
        file.bytes!,
      );

      setState(() {
        statementData = response;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildTransactionCard(Transaction txn) {
      return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              txn.date,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(txn.narration),
            const SizedBox(height: 10),
            Text('Debit: ₹${txn.debit.toStringAsFixed(2)}'),
            Text('Credit: ₹${txn.credit.toStringAsFixed(2)}'),
            Text('Balance: ₹${txn.balance.toStringAsFixed(2)}'),
            
          ],
        ),
      ),
    );
  }

  Widget buildResultView() {
    if (statementData == null) return const SizedBox();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statementData!.bankName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Transactions: ${statementData!.totalTransactions}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: statementData!.transactions.length,
              itemBuilder: (context, index) {
                return buildTransactionCard(statementData!.transactions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingView() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Parsing statement layout parameters with StatementX.AI...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildErrorView() {
    if (errorMessage == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 171, 174, 244),

    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 171, 174, 244),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'StatementX.AI',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    const Text(
                      'Upload Your Bank Statement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Upload a PDF statement and analyze your transactions instantly',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: 230,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed:
                            isLoading ? null : pickAndUploadPdf,

                        icon: const Icon(Icons.upload_file_rounded),

                        label: const Text(
                          'Upload PDF',
                          style: TextStyle(fontSize: 16),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 101, 93, 239),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    buildErrorView(),

                    if (isLoading) ...[
                      const SizedBox(height: 20),
                      buildLoadingView(),
                    ],

                    if (!isLoading && statementData != null) ...[
                      const SizedBox(height: 20),
                      buildResultView(),
                    ],
                  ],
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