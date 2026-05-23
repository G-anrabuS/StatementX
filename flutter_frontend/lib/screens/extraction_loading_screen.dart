import 'package:flutter/material.dart';

class ExtractionLoadingScreen extends StatelessWidget {
  const ExtractionLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_graph,
                size: 90,
                color: Colors.greenAccent,
              ),

              const SizedBox(height: 30),

              const Text(
                'StatementX.AI',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              const CircularProgressIndicator(),

              const SizedBox(height: 30),

              const Text(
                'Analyzing bank statement...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Extracting transactions and generating insights',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}