import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/statement_model.dart';
import '../services/statement_service.dart';

import 'transaction_screen.dart';

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
      withData: true,
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TransactionsScreen(transactions: response.transactions),
        ),
      );
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

  Widget featureCard(IconData icon, String title, String subtitle) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff12052E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.deepPurple.withOpacity(0.15),
            child: Icon(icon, color: Colors.purpleAccent),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
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
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: const Color(0xff070014),

      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: Image.network(
                  'https://www.transparenttextures.com/patterns/cubes.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1250),

                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 45,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff0B031C),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),

                        child: isMobile
                            ? Column(
                                children: [
                                  buildLeftSection(),
                                  const SizedBox(height: 40),
                                  buildIllustration(),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: buildLeftSection()),

                                  const SizedBox(width: 20),

                                  Expanded(child: buildIllustration()),
                                ],
                              ),
                      ),

                      const SizedBox(height: 40),

                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),

                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: Colors.purpleAccent,
                              ),
                              SizedBox(height: 18),
                              Text(
                                'Analyzing statement...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLeftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.find_in_page_rounded,
          size: 80,
          color: Colors.purpleAccent,
        ),

        const SizedBox(height: 30),

        const Text(
          'BANK',
          style: TextStyle(
            fontSize: 52,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),

        const Text(
          'STATEMENT',
          style: TextStyle(
            fontSize: 52,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),

        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.purpleAccent, Color(0xff6D5DFB)],
          ).createShader(bounds),

          child: const Text(
            'ANALYSER',
            style: TextStyle(
              fontSize: 58,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Upload your bank statement and get\nsmart insights about your spending.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 17,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 40),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purpleAccent),
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.withOpacity(0.5),
                Colors.purpleAccent.withOpacity(0.2),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),

          child: ElevatedButton.icon(
            onPressed: isLoading ? null : pickAndUploadPdf,

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            icon: const Icon(
              Icons.upload_rounded,
              color: Colors.white,
              size: 30,
            ),

            label: const Text(
              'UPLOAD PDF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'Supports PDF and CSV files',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),

        const SizedBox(height: 45),

        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            featureCard(Icons.shield_rounded, 'AI-Powered', 'Smart Analysis'),

            featureCard(Icons.pie_chart_rounded, 'Insights', 'Clear Reports'),

            featureCard(Icons.lock_rounded, 'Secure', '100% Private'),
          ],
        ),
      ],
    );
  }

  Widget buildIllustration() {
    return Center(
      child: Container(
        height: 430,
        width: 430,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.purpleAccent.withOpacity(0.18), Colors.transparent],
          ),
        ),

        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 260,
              height: 320,
              decoration: BoxDecoration(
                color: const Color(0xff1A0A38),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.2),
                    blurRadius: 30,
                  ),
                ],
              ),

              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ...List.generate(
                      5,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        buildBar(40),
                        buildBar(75),
                        buildBar(105),
                        buildBar(65),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 50,
              bottom: 70,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purpleAccent, width: 10),
                ),
              ),
            ),

            Positioned(
              right: 30,
              bottom: 30,
              child: Transform.rotate(
                angle: 0.8,
                child: Container(
                  width: 18,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBar(double height) {
    return Container(
      width: 24,
      height: height,
      decoration: BoxDecoration(
        color: Colors.purpleAccent,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
