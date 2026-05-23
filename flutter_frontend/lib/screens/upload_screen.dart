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
      errorMessage = null;
    });

    try {
      final response = await StatementService.uploadStatement(
        file.name,
        file.bytes!,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionsScreen(
            transactions: response.transactions,
          ),
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

  Widget featureCard(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE9ECF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                const Color(0xff6D5DFB).withOpacity(0.1),
            child: Icon(
              icon,
              color: const Color(0xff6D5DFB),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  '',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
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
    final isMobile =
        MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 1280),

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 55,
                  vertical: 50,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFE9ECF2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
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
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            flex: 5,
                            child: buildLeftSection(),
                          ),

                          const SizedBox(width: 20),

                          Flexible(
                            flex: 4,
                            child: buildIllustration(),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLeftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.find_in_page_rounded,
              size: 42,
              color: const Color(0xff6D5DFB),
            ),

            const SizedBox(width: 10),

            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: 'Statement',
                    style: TextStyle(
                      color: Color(0xFF111827),
                    ),
                  ),
                  TextSpan(
                    text: 'X',
                    style: TextStyle(
                      color: Color(0xff6D5DFB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 50),

        const Text(
          'BANK',
          style: TextStyle(
            fontSize: 62,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),

        const Text(
          'STATEMENT',
          style: TextStyle(
            fontSize: 62,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),

        ShaderMask(
          shaderCallback: (bounds) =>
              const LinearGradient(
            colors: [
              Color(0xff6D5DFB),
              Color(0xff7C4DFF),
            ],
          ).createShader(bounds),

          child: const Text(
            'ANALYSER',
            style: TextStyle(
              fontSize: 68,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          'Upload your bank statement and get\nsmart insights about your spending.',
          style: TextStyle(
            color: Color(0xFF475569),
            fontSize: 18,
            height: 1.7,
          ),
        ),

        const SizedBox(height: 40),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xff6D5DFB),
                Color(0xff7C4DFF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xff6D5DFB)
                        .withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: ElevatedButton.icon(
            onPressed:
                isLoading ? null : pickAndUploadPdf,

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 34,
                vertical: 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
            ),

            icon: const Icon(
              Icons.upload_rounded,
              color: Colors.white,
              size: 26,
            ),

            label: const Text(
              'UPLOAD PDF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Supports PDF and CSV files',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 40),

        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            featureCard(
              Icons.psychology_rounded,
              'AI-Powered',
              'Smart Analysis',
            ),

            featureCard(
              Icons.pie_chart_rounded,
              'Insights',
              'Clear Reports',
            ),

            featureCard(
              Icons.lock_rounded,
              'Secure',
              '100% Private',
            ),
          ],
        ),

        if (errorMessage != null) ...[
          const SizedBox(height: 24),

          Text(
            errorMessage!,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
        ],

        if (isLoading) ...[
          const SizedBox(height: 40),

          const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(
                'Analyzing statement...',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget buildIllustration() {
    return Center(
      child: Container(
        height: 420,
        width: 420,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xff6D5DFB)
                  .withOpacity(0.08),
              Colors.transparent,
            ],
          ),
        ),

        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 40,
              right: 20,
              child: dotPattern(),
            ),

            Positioned(
              bottom: 40,
              left: 20,
              child: dotPattern(),
            ),

            Container(
              width: 250,
              height: 310,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFE9ECF2),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 140,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xff6D5DFB)
                            .withOpacity(0.4),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 28),

                    ...List.generate(
                      5,
                      (index) => Padding(
                        padding:
                            const EdgeInsets.only(
                                bottom: 14),
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE5E7EB,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                                    10),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceEvenly,
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        buildBar(40),
                        buildBar(65),
                        buildBar(95),
                        buildBar(55),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 45,
              bottom: 70,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xff6D5DFB),
                    width: 10,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 25,
              bottom: 28,
              child: Transform.rotate(
                angle: 0.8,
                child: Container(
                  width: 16,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xff6D5DFB),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dotPattern() {
    return SizedBox(
      width: 70,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(
          20,
          (index) => Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color:
                  const Color(0xff6D5DFB)
                      .withOpacity(0.25),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBar(double height) {
    return Container(
      width: 22,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xff6D5DFB),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

