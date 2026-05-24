import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import '../models/insights_model.dart';
import '../models/statement_model.dart';
import 'upload_screen.dart';
import 'transaction_screen.dart';
import 'insights_screen.dart';
import 'visualization_screen.dart';
import 'chat_bot_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/statement_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Teammate's scrolling controllers & keys
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _securityKey = GlobalKey();
  bool _isDarkMode = false;

  // Dynamic data states
  String? currentStatementId;
  String? currentBankName;
  bool _isLoading = true;
  StatementInsights? _insights;
  List<StatementMetadata> _statements = [];
  bool _isUserLoggedIn = false;
  StreamSubscription? _authSubscription;
  bool _hasRedirectedToUpload = false;

  @override
  void initState() {
    super.initState();
    
    // Listen for Google Auth changes (for Web GIS button support)
    _authSubscription = AuthService.onUserChanged.listen((user) async {
      if (user != null) {
        // Allow brief time for backend sync stream in main.dart to complete
        await Future.delayed(const Duration(milliseconds: 500));
        _refreshData();
      }
    });

    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final bool loggedIn = await AuthService.isLoggedIn();
      setState(() {
        _isUserLoggedIn = loggedIn;
      });

      if (loggedIn) {
        try {
          final statements = await StatementService.listStatements();
          
          StatementMetadata? latest;
          StatementInsights? insights;
          if (statements.isNotEmpty) {
            latest = statements.first;
            insights = await StatementService.getStatementInsights(latest.statementId);
          }
          
          setState(() {
            _statements = statements;
            currentStatementId = latest?.statementId;
            currentBankName = latest?.bankName;
            _insights = insights;
            _isLoading = false;
          });
          
          // ALWAYS redirect to the PDF upload page upon sign-in completion
          if (!_hasRedirectedToUpload) {
            _hasRedirectedToUpload = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // If a login dialog or overlay is open, safely dismiss it first
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              _navigateToUploader();
            });
          }
          return;
        } catch (err) {
          final errMsg = err.toString();
          if (errMsg.contains('401') || errMsg.contains('unauthorized') || errMsg.contains('credentials') || errMsg.contains('authenticated')) {
            print('Authentication token is stale or invalid. Clearing session.');
            await AuthService.logout();
            _hasRedirectedToUpload = false; // Reset redirect flag
            setState(() {
              _isUserLoggedIn = false;
              _statements = [];
              currentStatementId = null;
              currentBankName = null;
              _insights = null;
              _isLoading = false;
            });
            return;
          }
          rethrow;
        }
      }
      
      setState(() {
        _statements = [];
        currentStatementId = null;
        currentBankName = null;
        _insights = null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error refreshing home data: $e');
      setState(() {
        _statements = [];
        currentStatementId = null;
        currentBankName = null;
        _insights = null;
        _isLoading = false;
      });
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToUploader() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
    _refreshData();
  }

  void _showNoStatementWarning(String screenName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please upload a bank statement first to open $screenName.'),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: 'UPLOAD',
          textColor: Colors.white,
          onPressed: _navigateToUploader,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 850;

    // Palette configured directly for high visual match to the template image
    const Color brandBlue = Color(0xFF4F46E5);
    const Color brandTeal = Color(0xFF06B6D4);
    const Color bgSlate = Color(0xFFF8FAFC);
    const Color textNavy = Color(0xFF0F172A);
    const Color textMuted = Color(0xFF475569);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // RESOLUTION STRATEGY:
    // If user has no statements, show the Teammate's landing page.
    // If user has statements, show the Dashboard UI.
    
    final bool showDashboard = currentStatementId != null;

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : (showDashboard ? AppColors.bgLight : bgSlate),
      drawer: isMobile ? _buildMobileDrawer(brandBlue) : null,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: showDashboard 
          ? _buildDashboardHeader() 
          : _buildLandingHeader(isMobile, brandBlue, textNavy),
      ),
      body: showDashboard 
        ? _buildDashboardBody(isMobile) 
        : _buildLandingBody(isMobile, brandBlue, brandTeal, textNavy, textMuted, bgSlate),
    );
  }

  // --- LANDING PAGE WIDGETS (TEAMMATE'S CODE) ---

  Widget _buildLandingHeader(bool isMobile, Color brandBlue, Color textNavy) {
    return AppBar(
      backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: _isDarkMode ? Colors.white : textNavy),
      leading: isMobile
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, size: 28),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: brandBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.account_balance_rounded, color: brandBlue, size: 24),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            'Bank Statement Analyzer',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : textNavy,
              fontSize: isMobile ? 17 : 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (!isMobile) ...[
          _buildHeaderNavLink('Home', () => _scrollToSection(_heroKey)),
          _buildHeaderNavLink('Features', () => _scrollToSection(_featuresKey)),
          _buildHeaderNavLink('Security', () => _scrollToSection(_securityKey)),
          const SizedBox(width: 8),
          if (!_isUserLoggedIn) ...[
            TextButton(
              onPressed: _showLoginDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                foregroundColor: brandBlue,
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: _showLoginDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
        IconButton(
          icon: Icon(
            _isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
            color: _isDarkMode ? Colors.yellow : textNavy.withOpacity(0.7),
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildLandingBody(bool isMobile, Color brandBlue, Color brandTeal, Color textNavy, Color textMuted, Color bgSlate) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // 1. HERO SECTION
          Container(
            key: _heroKey,
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 32 : 64,
              horizontal: isMobile ? 18 : 36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isMobile
                    ? Column(
                        children: [
                          _buildHeroLeft(isMobile, brandBlue, brandTeal, textNavy, textMuted),
                          const SizedBox(height: 36),
                          _buildHeroRight(isMobile),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildHeroLeft(isMobile, brandBlue, brandTeal, textNavy, textMuted),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 5,
                            child: _buildHeroRight(isMobile),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. FEATURES SECTION
          Container(
            key: _featuresKey,
            width: double.infinity,
            color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 48 : 80,
              horizontal: isMobile ? 18 : 36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Text(
                      'Powerful Features',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : textNavy,
                        fontSize: isMobile ? 26 : 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: brandBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 48),
                    isMobile
                        ? Column(
                            children: [
                              _buildFeatureCard(
                                icon: Icons.pie_chart_rounded,
                                iconColor: const Color(0xFF8B5CF6),
                                title: 'Smart Analysis',
                                desc: 'Automatically analyzes your statement and provides meaningful insights.',
                              ),
                              const SizedBox(height: 20),
                              _buildFeatureCard(
                                icon: Icons.bar_chart_rounded,
                                iconColor: const Color(0xFF10B981),
                                title: 'Expense Breakdown',
                                desc: 'Categorizes your expenses and shows where your money is going.',
                              ),
                              const SizedBox(height: 20),
                              _buildFeatureCard(
                                icon: Icons.shield_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                title: 'Secure & Private',
                                desc: 'We use bank-level security to keep your data safe and private.',
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildFeatureCard(
                                  icon: Icons.pie_chart_rounded,
                                  iconColor: const Color(0xFF8B5CF6),
                                  title: 'Smart Analysis',
                                  desc: 'Automatically analyzes your statement and provides meaningful insights.',
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildFeatureCard(
                                  icon: Icons.bar_chart_rounded,
                                  iconColor: const Color(0xFF10B981),
                                  title: 'Expense Breakdown',
                                  desc: 'Categorizes your expenses and shows where your money is going.',
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildFeatureCard(
                                  icon: Icons.shield_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  title: 'Secure & Private',
                                  desc: 'We use bank-level security to keep your data safe and private.',
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),

          // 3. WORKS EVERYWHERE (SECURITY) SECTION
          Container(
            key: _securityKey,
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 48 : 64,
              horizontal: isMobile ? 18 : 36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _buildWorksEverywhereBanner(isMobile, brandBlue),
              ),
            ),
          ),

          // 4. FOOTER SECTION
          _buildFooter(isMobile, textNavy, textMuted),
        ],
      ),
    );
  }

  // --- DASHBOARD WIDGETS (MY CODE) ---

  PreferredSizeWidget _buildDashboardHeader() {
    return AppBar(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      centerTitle: true,
      leading: PopupMenuButton<String>(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary, size: 24),
        tooltip: 'Quick Navigation Menu',
        onSelected: (value) => _handleNavigation(value),
        itemBuilder: (BuildContext context) => _buildMenuOptions(),
      ),
      title: RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          children: [
            TextSpan(text: 'Statement', style: TextStyle(color: AppColors.textPrimary)),
            TextSpan(text: 'X', style: TextStyle(color: AppColors.secondaryTeal)),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
          onPressed: _refreshData,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildDashboardBody(bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial Analytics Control Hub',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Active Ledger: ${currentBankName ?? "No statements loaded"}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              _buildKpiRibbon(isMobile),
              const SizedBox(height: 24),

              const Text(
                'Execution Shortcuts',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildShortcutGrid(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRibbon(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 1 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isMobile ? 3.5 : 2.2,
      children: [
        _buildKpiCard('TOTAL DEPOSITS', '₹${_insights?.totalIncome.toStringAsFixed(0) ?? "0"}', Icons.arrow_upward_rounded, AppColors.primaryGreen),
        _buildKpiCard('TOTAL OUTFLOWS', '₹${_insights?.totalExpense.toStringAsFixed(0) ?? "0"}', Icons.arrow_downward_rounded, const Color(0xFFC62828)),
        _buildKpiCard('NET SAVINGS SURPLUS', '₹${_insights?.netSavings.toStringAsFixed(0) ?? "0"}', Icons.account_balance_wallet_rounded, AppColors.secondaryTeal),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: accentColor.withOpacity(0.08),
            child: Icon(icon, color: accentColor, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildShortcutGrid(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.1,
      children: [
        _buildShortcutCard('Upload Parser', 'Import statement files', Icons.upload_file_rounded, AppColors.primaryGreen, 'upload'),
        _buildShortcutCard('Transactions', 'Review complete ledgers', Icons.receipt_long_rounded, Colors.blueAccent, 'transaction'),
        _buildShortcutCard('Insights Summary', 'Spend breakdowns & anomalies', Icons.insights_rounded, Colors.orangeAccent, 'insights'),
        _buildShortcutCard('AI Semantic Chat', 'Query documents cleanly', Icons.chat_bubble_outline_rounded, AppColors.secondaryTeal, 'chatbot'),
      ],
    );
  }

  Widget _buildShortcutCard(String title, String desc, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => _handleNavigation(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS & SHARED WIDGETS ---

  Widget _buildHeaderNavLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        foregroundColor: _isDarkMode ? Colors.white70 : const Color(0xFF475569),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
      ),
    );
  }

  Widget _buildMobileDrawer(Color brandBlue) {
    return Drawer(
      backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            ListTile(
              leading: Icon(Icons.account_balance_rounded, color: brandBlue),
              title: Text(
                'Analyzer Menu',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            _buildDrawerItem(Icons.home_rounded, 'Home', () {
              Navigator.pop(context);
              _scrollToSection(_heroKey);
            }),
            _buildDrawerItem(Icons.widgets_rounded, 'Features', () {
              Navigator.pop(context);
              _scrollToSection(_featuresKey);
            }),
            _buildDrawerItem(Icons.security_rounded, 'Security', () {
              Navigator.pop(context);
              _scrollToSection(_securityKey);
            }),
            const Divider(indent: 16, endIndent: 16),
            if (_isUserLoggedIn) ...[
              _buildDrawerItem(Icons.upload_file_rounded, 'Upload Statement', () {
                Navigator.pop(context);
                _navigateToUploader();
              }),
              _buildDrawerItem(Icons.logout_rounded, 'Sign Out', () {
                Navigator.pop(context);
                _handleLogout();
              }),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showLoginDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Login / Sign Up',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _isDarkMode ? Colors.white70 : const Color(0xFF475569)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.white70 : const Color(0xFF475569),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildHeroLeft(bool isMobile, Color brandBlue, Color brandTeal, Color textNavy, Color textMuted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: brandBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: brandBlue.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, color: brandBlue, size: 15),
              const SizedBox(width: 6),
              Text(
                'Smart. Secure. Simple.',
                style: TextStyle(
                  color: brandBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 18 : 28),
        Text(
          'Bank Statement',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : textNavy,
            fontSize: isMobile ? 32 : 56,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [brandBlue, brandTeal],
          ).createShader(bounds),
          child: Text(
            'Analyzer',
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 36 : 64,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Text(
          'Upload your bank statement and get instant insights about your income, expenses, savings and overall financial health.',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : textMuted,
            fontSize: isMobile ? 14 : 17,
            height: 1.5,
          ),
        ),
        SizedBox(height: isMobile ? 24 : 36),
        SizedBox(
          width: isMobile ? double.infinity : 260,
          height: 52,
          child: ElevatedButton(
            onPressed: _isUserLoggedIn ? _navigateToUploader : _showLoginDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Analyze your statement now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 20 : 32),
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: brandBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              'Your data is 100% secure and private',
              style: TextStyle(
                color: _isDarkMode ? Colors.white60 : textMuted.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroRight(bool isMobile) {
    final scale = isMobile ? 0.75 : 1.0;
    return Center(
      child: Container(
        height: 380 * scale,
        width: 380 * scale,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 280 * scale,
              width: 280 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4F46E5).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(0.04)
                ..rotateX(0.04)
                ..rotateZ(-0.06),
              alignment: Alignment.center,
              child: Container(
                height: 260 * scale,
                width: 190 * scale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BANK STATEMENT',
                      style: TextStyle(
                        fontSize: 9.5 * scale,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(height: 5 * scale, width: 80 * scale, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 6),
                    Container(height: 5 * scale, width: 50 * scale, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 68 * scale,
                            height: 68 * scale,
                            child: const CircularProgressIndicator(
                              value: 0.7,
                              strokeWidth: 10,
                              backgroundColor: Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                            ),
                          ),
                          Text(
                            '70%',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(height: 20 * scale, width: 8 * scale, decoration: BoxDecoration(color: const Color(0xFF67E8F9), borderRadius: BorderRadius.circular(2))),
                        Container(height: 35 * scale, width: 8 * scale, decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(2))),
                        Container(height: 15 * scale, width: 8 * scale, decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(2))),
                        Container(height: 25 * scale, width: 8 * scale, decoration: BoxDecoration(color: const Color(0xFF818CF8), borderRadius: BorderRadius.circular(2))),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              left: -48 * scale,
              bottom: 40 * scale,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(-0.1)
                  ..rotateX(0.05)
                  ..rotateZ(0.12),
                alignment: Alignment.center,
                child: Container(
                  height: 95 * scale,
                  width: 145 * scale,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 16 * scale,
                            width: 22 * scale,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCD34D),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Icon(Icons.wifi, color: Colors.white.withOpacity(0.8), size: 14 * scale),
                        ],
                      ),
                      Text(
                        '••••  ••••  ••••  8829',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10 * scale,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'STATEMENT X',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 7 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '12/29',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 7 * scale,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -30 * scale,
              bottom: 24 * scale,
              child: Transform(
                transform: Matrix4.identity()..rotateZ(-0.05),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: const Color(0xFF10B981),
                      size: 26 * scale,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: iconColor.withOpacity(0.09),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isDarkMode ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorksEverywhereBanner(bool isMobile, Color brandBlue) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 28 : 36,
        horizontal: isMobile ? 24 : 48,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEEF2F6),
            brandBlue.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: brandBlue,
                  child: const Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Works Everywhere',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'One code. Multiple platforms. Seamless experience on Android and Web.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDeviceBadge(Icons.android_rounded),
                    const SizedBox(width: 12),
                    _buildDeviceBadge(Icons.language_rounded),
                  ],
                )
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: brandBlue,
                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Works Everywhere',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'One code. Multiple platforms. Seamless experience on Android and Web.',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildDeviceBadge(Icons.android_rounded),
                    const SizedBox(width: 14),
                    _buildDeviceBadge(Icons.language_rounded),
                  ],
                )
              ],
            ),
    );
  }

  Widget _buildDeviceBadge(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1.5),
          )
        ],
      ),
      child: Icon(icon, color: const Color(0xFF475569), size: 20),
    );
  }

  Widget _buildFooter(bool isMobile, Color textNavy, Color textMuted) {
    return Container(
      width: double.infinity,
      color: _isDarkMode ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile
              ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_rounded, color: Color(0xFF4F46E5), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Bank Statement Analyzer',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white70 : textNavy,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '© 2024 All rights reserved.',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white38 : textMuted.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    )
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, color: Color(0xFF4F46E5), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Bank Statement Analyzer',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white70 : textNavy,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                      ],
                    ),
                    Text(
                      '© 2024 All rights reserved.',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white38 : textMuted.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }

  // --- MENU & NAVIGATION ---

  List<PopupMenuEntry<String>> _buildMenuOptions() {
    return [
      _buildMenuItem('home', 'Home Dashboard', Icons.home_rounded, AppColors.textSecondary),
      _buildMenuItem('upload', 'PDF / CSV Upload', Icons.upload_file_rounded, AppColors.primaryGreen),
      _buildMenuItem('transaction', 'Transactions Ledger', Icons.receipt_long_rounded, Colors.blueAccent),
      _buildMenuItem('insights', 'Financial Insights', Icons.insights_rounded, Colors.orangeAccent),
      _buildMenuItem('visualization', 'Analytics Dashboard', Icons.bar_chart_rounded, Colors.indigoAccent),
      _buildMenuItem('chatbot', 'AI Semantic Chat', Icons.chat_bubble_outline_rounded, AppColors.secondaryTeal),
      const PopupMenuDivider(),
      _buildMenuItem('logout', 'Sign Out', Icons.logout_rounded, Colors.redAccent),
    ];
  }

  PopupMenuItem<String> _buildMenuItem(String value, String text, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  void _handleNavigation(String route) async {
    switch (route) {
      case 'home':
        break;
      case 'upload':
        _navigateToUploader();
        break;
      case 'transaction':
        if (currentStatementId != null) {
          setState(() => _isLoading = true);
          try {
            final details = await StatementService.getStatement(currentStatementId!);
            if (mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionsScreen(
                transactions: details.transactions, 
                bankName: currentBankName ?? 'Bank', 
                statementId: currentStatementId
              )));
            }
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        } else {
          _showNoStatementWarning('Transactions');
        }
        break;
      case 'insights':
        if (currentStatementId != null && _insights != null) {
          setState(() => _isLoading = true);
          try {
            final details = await StatementService.getStatement(currentStatementId!);
            if (mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => InsightsScreen(
                statementId: currentStatementId!, 
                bankName: currentBankName ?? 'Bank', 
                insights: _insights!, 
                totalTransactions: details.totalTransactions
              )));
            }
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        } else {
          _showNoStatementWarning('Insights');
        }
        break;
      case 'visualization':
        if (currentStatementId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => VisualizationScreen(statementId: currentStatementId!)));
        } else {
          _showNoStatementWarning('Analytics Dashboard');
        }
        break;
      case 'chatbot':
        if (currentStatementId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatBotScreen(statementId: currentStatementId!)));
        } else {
          _showNoStatementWarning('AI Semantic Chat');
        }
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    _hasRedirectedToUpload = false;
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDirectLoginMobile() async {
    setState(() => _isLoading = true);
    final user = await AuthService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (user != null) {
      _refreshData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final isDark = _isDarkMode;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 16,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF4F46E5),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to StatementX',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Access your premium bank statement insights, AI semantic chat, and visual financial indicators by signing in below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark ? Colors.white60 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Unified Sign In Section
                if (kIsWeb) ...[
                  // Official Google-branded button for Web (GIS)
                  Container(
                    width: 250,
                    height: 50,
                    alignment: Alignment.center,
                    child: web.renderButton(),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleDirectLoginMobile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF475569),
                      elevation: 2,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Custom Google G-Logo using standard CustomPainter for accuracy
                        CustomPaint(
                          size: const Size(20, 20),
                          painter: GoogleLogoPainter(),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                Text(
                  'Secured by Google Identity Services',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double r = w / 2;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Red Arc (Top Left & Top)
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(r, r)
      ..lineTo(r - r * 0.7071, r - r * 0.7071)
      ..arcTo(Rect.fromCircle(center: Offset(r, r), radius: r), -2.356, 2.356, false)
      ..lineTo(r, r)
      ..close();
    canvas.drawPath(redPath, paint);

    // Yellow Arc (Bottom Left & Left)
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(r, r)
      ..lineTo(r - r * 0.7071, r + r * 0.7071)
      ..arcTo(Rect.fromCircle(center: Offset(r, r), radius: r), -3.927, 1.571, false)
      ..lineTo(r - r * 0.7071, r - r * 0.7071)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green Arc (Bottom & Bottom Right)
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(r, r)
      ..lineTo(r + r * 0.95, r + r * 0.3)
      ..arcTo(Rect.fromCircle(center: Offset(r, r), radius: r), 0.3, 2.05, false)
      ..lineTo(r - r * 0.7071, r + r * 0.7071)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Blue Section (Right & bar)
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(r, r)
      ..lineTo(r + r, r)
      ..arcTo(Rect.fromCircle(center: Offset(r, r), radius: r), 0, 0.3, false)
      ..lineTo(r + r * 0.95, r + r * 0.3)
      ..lineTo(r + r * 0.3, r + r * 0.3)
      ..lineTo(r + r * 0.3, r - r * 0.2)
      ..lineTo(r + r, r - r * 0.2)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Inner cutout to make it a G ring
    final Paint cutoutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(r, r), r * 0.6, cutoutPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
