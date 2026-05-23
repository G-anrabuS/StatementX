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

  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'csv'],
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;

    if (file.bytes == null) {
      setState(() {
        errorMessage = 'Unable to read selected statement file.';
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

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionsScreen(
            transactions: response.transactions,
            bankName: response.bankName,
            statementId: response.statementId,
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

  Widget featureCard(IconData icon, String title, String subtitle) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9ECF2)),
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
            backgroundColor: const Color(0xff6D5DFB).withOpacity(0.1),
            child: Icon(icon, color: const Color(0xff6D5DFB), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? 24
                      : 55, // Adjusted mobile spacing rules cleanly
                  vertical: isMobile ? 32 : 50,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE9ECF2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // Left aligned mobile setup cleanly
                        children: [
                          buildLeftSection(isMobile),
                          const SizedBox(height: 40),
                          buildIllustration(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(flex: 5, child: buildLeftSection(isMobile)),
                          const SizedBox(width: 20),
                          Flexible(flex: 4, child: buildIllustration()),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLeftSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.find_in_page_rounded,
              size: 42,
              color: Color(0xff6D5DFB),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: 'Statement',
                    style: TextStyle(color: Color(0xFF111827)),
                  ),
                  TextSpan(
                    text: 'X',
                    style: TextStyle(color: Color(0xff6D5DFB)),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 30 : 50),
        Text(
          'BANK',
          style: TextStyle(
            fontSize: isMobile
                ? 38
                : 62, // FIXED: Scaled size smoothly based on screen dimension targets
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        Text(
          'STATEMENT',
          style: TextStyle(
            fontSize: isMobile
                ? 38
                : 62, // FIXED: Scaled size smoothly based on screen dimension targets
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xff6D5DFB), Color(0xff7C4DFF)],
          ).createShader(bounds),
          child: Text(
            'ANALYSER',
            style: TextStyle(
              fontSize: isMobile
                  ? 42
                  : 68, // FIXED: Scaled size smoothly based on screen dimension targets
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Upload your bank statement and get\nsmart insights about your spending.',
          style: TextStyle(
            color: const Color(0xFF475569),
            fontSize: isMobile ? 15 : 18, // Refined secondary messaging metrics
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xff6D5DFB), Color(0xff7C4DFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff6D5DFB).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : pickAndUploadFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 26 : 34,
                vertical: isMobile ? 18 : 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(
              Icons.upload_rounded,
              color: Colors.white,
              size: 26,
            ),
            label: Text(
              'UPLOAD FILE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 20,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Supports PDF and CSV files',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            featureCard(
              Icons.psychology_rounded,
              'AI-Powered',
              'Smart Analysis',
            ),
            featureCard(Icons.pie_chart_rounded, 'Insights', 'Clear Reports'),
            featureCard(Icons.lock_rounded, 'Secure', '100% Private'),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 24),
          Text(errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
        if (isLoading) ...[
          const SizedBox(height: 32),
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
        height:
            360, // Adjusted layout proportions slightly to look sharp on mobile screens
        width: 360,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xff6D5DFB).withOpacity(0.08),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(top: 30, right: 20, child: dotPattern()),
            Positioned(bottom: 30, left: 20, child: dotPattern()),
            Container(
              width: 230,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE9ECF2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xff6D5DFB).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          4,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        buildBar(35),
                        buildBar(55),
                        buildBar(80),
                        buildBar(45),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 50,
              bottom: 60,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xff6D5DFB), width: 8),
                ),
              ),
            ),
            Positioned(
              right: 35,
              bottom: 25,
              child: Transform.rotate(
                angle: 0.8,
                child: Container(
                  width: 14,
                  height: 65,
                  decoration: BoxDecoration(
                    color: const Color(0xff6D5DFB),
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

  Widget dotPattern() {
    return SizedBox(
      width: 60,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(
          16,
          (index) => Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xff6D5DFB).withOpacity(0.25),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBar(double height) {
    return Container(
      width: 18,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xff6D5DFB),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
