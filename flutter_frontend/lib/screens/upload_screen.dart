import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

    String? currentPassword;
    bool isFinished = false;

    // This loop keeps the workflow active until successfully parsed or explicitly cancelled
    while (!isFinished) {
      try {
        final response = await StatementService.uploadStatement(
          file.name,
          file.bytes!,
          password: currentPassword, // Passes null on the first loop attempt
        );

        if (!mounted) return;
        isFinished = true; // Breaks execution loop safely on success

        // Safe screen routing to the transaction layout ledger
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
      } on FormatException catch (ex) {
        // CRITICAL FIX: Intercept password requirements cleanly
        if (ex.message == 'PASSWORD_REQUIRED' ||
            ex.message == 'INVALID_PASSWORD') {
          setState(() {
            isLoading = false;
            errorMessage =
                null; // Clear any old errors to allow a clean retry state
          });

          // Fire open the interactive password text field dialog modal
          final userPasswordInput = await _showPasswordDialog(
            isRetry: ex.message == 'INVALID_PASSWORD',
          );

          // Terminate gracefully if the user exits out or submits empty spaces
          if (userPasswordInput == null || userPasswordInput.trim().isEmpty) {
            setState(() {
              errorMessage = 'Parsing canceled: Password required.';
              isLoading = false;
            });
            isFinished = true; // Break loop explicitly
            return;
          }

          // Cache the captured string input and restart the loading layout state for the next loop run
          currentPassword = userPasswordInput;
          setState(() => isLoading = true);

          // Continue loop immediately with the newly acquired password context
          continue;
        } else {
          setState(() => errorMessage = ex.message);
          isFinished = true;
        }
      } catch (e) {
        // Fallback generic catch statement handling system crashes or server drops
        // Clean up text if it contains raw instance wrappers
        String errorText = e.toString();
        if (errorText.contains('PASSWORD_REQUIRED') ||
            errorText.contains('INVALID_PASSWORD')) {
          // Fallback parsing manual extraction override if exception type leaked into generic catch
          setState(() => isLoading = false);
          final userPasswordInput = await _showPasswordDialog(
            isRetry: errorText.contains('INVALID_PASSWORD'),
          );
          if (userPasswordInput == null || userPasswordInput.trim().isEmpty) {
            setState(
              () => errorMessage = 'Parsing canceled: Password required.',
            );
            isFinished = true;
            return;
          }
          currentPassword = userPasswordInput;
          setState(() => isLoading = true);
          continue;
        }

        setState(
          () => errorMessage = errorText.replaceFirst('Exception: ', ''),
        );
        isFinished = true;
      } finally {
        if (isFinished && mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  Future<String?> _showPasswordDialog({bool isRetry = false}) async {
    String enteredPassword = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // User must submit or explicitly cancel
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isRetry ? 'Incorrect Password' : 'Password Protected PDF',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRetry
                    ? 'The password entered was invalid. Please try again:'
                    : 'This statement file is encrypted. Enter the password to unlock it:',
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Document Password',
                  hintText: 'Enter PDF password',
                  border: const OutlineInputBorder(),
                  errorText: isRetry ? 'Invalid password' : null,
                ),
                onChanged: (value) => enteredPassword = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, null), // Returns null on Cancel
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, enteredPassword),
              child: const Text('UNLOCK'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 850;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: AppColors.primaryColor,
                size: 24,
              ),
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
                    style: TextStyle(color: AppColors.secondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1100,
                  maxHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 48,
                    vertical: isMobile ? 24 : 48,
                  ),
                  child: isMobile
                      ? SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              buildLeftSection(isMobile),
                              const SizedBox(height: 40),
                              buildIllustration(isMobile),
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              flex: 5,
                              child: buildLeftSection(isMobile),
                            ),
                            const SizedBox(width: 48),
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
        Column(
          crossAxisAlignment: isMobile
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              'BANK STATEMENT',
              textAlign: isMobile ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: isMobile ? 26 : 46,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.secondaryColor],
              ).createShader(bounds),
              child: Text(
                'ANALYSER',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: isMobile ? 30 : 52,
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
              colors: [AppColors.primaryColor, AppColors.secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.15),
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
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        if (isLoading) ...[
          SizedBox(height: isMobile ? 16 : 24),
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
                    AppColors.primaryColor,
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
    final canvasSize = isMobile ? 140.0 : 280.0;

    return Center(
      child: Container(
        height: canvasSize,
        width: canvasSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primaryColor.withOpacity(0.04),
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
                        color: AppColors.secondaryColor.withOpacity(0.25),
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
        color: AppColors.primaryColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
