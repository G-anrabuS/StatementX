import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/statement_model.dart';
import '../services/statement_service.dart';
import '../theme/app_theme.dart';
import 'transaction_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool isLoading = false;
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
      setState(() => errorMessage = 'Unable to read selected statement file.');
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
      setState(() => errorMessage = e.toString());
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
    bool isMobile,
  ) {
    return Container(
      width: isMobile ? double.infinity : 200, // Balanced tracking dimensions
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: isMobile ? 18 : 20,
            backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
            child: Icon(
              icon,
              color: AppColors.primaryGreen,
              size: isMobile ? 18 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 14,
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isMobile ? 11 : 12,
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 850;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1280,
                  maxHeight: constraints.maxHeight,
                ),
                child: Container(
                  margin: EdgeInsets.all(isMobile ? 16 : 24),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? 20
                        : 45, // Optimized layout container margins
                    vertical: isMobile ? 24 : 36,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            buildLeftSection(isMobile),
                            buildIllustration(isMobile),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              flex: 5,
                              child: buildLeftSection(isMobile),
                            ),
                            const SizedBox(width: 30),
                            Flexible(
                              flex: 4,
                              child: buildIllustration(isMobile),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildLeftSection(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            const Icon(
              Icons.analytics_rounded,
              size: 36,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: 'Statement',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  TextSpan(
                    text: 'X',
                    style: TextStyle(color: AppColors.secondaryTeal),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 14 : 24), // Dynamic optimization variables
        Column(
          crossAxisAlignment: isMobile
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              'BANK STATEMENT',
              textAlign: isMobile ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: isMobile
                    ? 26
                    : 46, // Scaled down title dynamically from 54 to 46 for safe desktop boundaries
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primaryGreen, AppColors.secondaryTeal],
              ).createShader(bounds),
              child: Text(
                'ANALYSER',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: isMobile
                      ? 30
                      : 52, // Scaled down from 60 to 52 for tight desktop window parameters
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 10 : 16),
        Text(
          'Upload your bank statement and get\nsmart insights about your spending.',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isMobile ? 13 : 16,
            height: 1.4,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [AppColors.primaryGreen, AppColors.secondaryTeal],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : pickAndUploadFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 34,
                vertical: isMobile ? 14 : 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(
              Icons.upload_file_rounded,
              color: Colors.white,
              size: 22,
            ),
            label: Text(
              'UPLOAD FILE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        const Text(
          'Supports PDF and CSV files',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        SizedBox(height: isMobile ? 16 : 24),

        if (isMobile)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: featureCard(
                  Icons.psychology_rounded,
                  'AI-Powered',
                  'Smart Run',
                  true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: featureCard(
                  Icons.bar_chart_rounded,
                  'Insights',
                  'Reports',
                  true,
                ),
              ),
            ],
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              featureCard(
                Icons.psychology_rounded,
                'AI-Powered',
                'Smart Analysis',
                false,
              ),
              featureCard(
                Icons.bar_chart_rounded,
                'Insights',
                'Clear Reports',
                false,
              ),
            ],
          ),

        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        if (isLoading) ...[
          SizedBox(height: isMobile ? 12 : 18),
          Row(
            mainAxisAlignment: isMobile
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Analyzing statement...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget buildIllustration(bool isMobile) {
    final canvasSize = isMobile
        ? 140.0
        : 280.0; // Scaled down dashboard display slightly from 340 to 280 for desktop stability

    return Center(
      child: Container(
        height: canvasSize,
        width: canvasSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primaryGreen.withOpacity(0.04),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: isMobile ? 100 : 180,
              height: isMobile ? 110 : 220,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 10 : 16),
                child: Column(
                  children: [
                    Container(
                      width: isMobile ? 50 : 90,
                      height: isMobile ? 5 : 8,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTeal.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    SizedBox(height: isMobile ? 10 : 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          isMobile ? 2 : 3,
                          (index) => Padding(
                            padding: EdgeInsets.only(bottom: isMobile ? 4 : 8),
                            child: Container(
                              height: isMobile ? 4 : 6,
                              decoration: BoxDecoration(
                                color: AppColors.bgLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        buildBar(isMobile ? 14 : 30, isMobile),
                        buildBar(isMobile ? 24 : 50, isMobile),
                        buildBar(isMobile ? 34 : 70, isMobile),
                        buildBar(isMobile ? 18 : 40, isMobile),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBar(double height, bool isMobile) {
    return Container(
      width: isMobile ? 8 : 14,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
