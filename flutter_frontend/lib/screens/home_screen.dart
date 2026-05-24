import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/insights_model.dart';
import '../models/statement_model.dart';
import 'upload_screen.dart';
import 'transaction_screen.dart';
import 'insights_screen.dart';
import 'visualization_screen.dart';
import 'chat_bot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? currentStatementId = "demo_statement_id"; 
  String? currentBankName = "StatementX Analytics Bank";

  final List<Transaction> mockTransactions = [
    Transaction(date: '2026-05-10', narration: 'Amazon Seller Pay', debit: 0.0, credit: 15000.0, balance: 45000.0, category: 'Income'),
    Transaction(date: '2026-05-12', narration: 'Zomato Premium Food', debit: 450.0, credit: 0.0, balance: 44550.0, category: 'Food'),
    Transaction(date: '2026-05-14', narration: 'Netflix Subscription', debit: 649.0, credit: 0.0, balance: 43901.0, category: 'Entertainment'),
    Transaction(date: '2026-05-15', narration: 'Uber India Ride', debit: 320.0, credit: 0.0, balance: 43581.0, category: 'Travel'),
  ];

  final List<Map<String, String>> mockNotifications = [
    {'title': 'Statement Parsed Successfully', 'desc': 'Your StatementX Analytics Bank ledger is fully categorized.', 'time': 'Just now'},
    {'title': 'Anomaly Flagged', 'desc': 'A recurring subscription change was detected in Entertainment.', 'time': '2 hours ago'},
  ];

  void _showNoStatementWarning(String screenName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please upload a bank statement first to open $screenName.'),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: 'UPLOAD',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
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
        actions: const [
          // Search and notification bell buttons have been completely removed from here
          SizedBox(width: 12),
        ],
      ),
      body: Center(
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
        _buildKpiCard('TOTAL DEPOSITS', '₹15,000', Icons.arrow_upward_rounded, AppColors.primaryGreen),
        _buildKpiCard('TOTAL OUTFLOWS', '₹1,419', Icons.arrow_downward_rounded, const Color(0xFFC62828)),
        _buildKpiCard('NET SAVINGS SURPLUS', '₹13,581', Icons.account_balance_wallet_rounded, AppColors.secondaryTeal),
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

  List<PopupMenuEntry<String>> _buildMenuOptions() {
    return [
      _buildMenuItem('home', 'Home Dashboard', Icons.home_rounded, AppColors.textSecondary),
      _buildMenuItem('upload', 'PDF / CSV Upload', Icons.upload_file_rounded, AppColors.primaryGreen),
      _buildMenuItem('transaction', 'Transactions Ledger', Icons.receipt_long_rounded, Colors.blueAccent),
      _buildMenuItem('insights', 'Financial Insights', Icons.insights_rounded, Colors.orangeAccent),
      _buildMenuItem('visualization', 'Analytics Dashboard', Icons.bar_chart_rounded, Colors.indigoAccent),
      _buildMenuItem('chatbot', 'AI Semantic Chat', Icons.chat_bubble_outline_rounded, AppColors.secondaryTeal),
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

  void _handleNavigation(String route) {
    switch (route) {
      case 'home':
        break;
      case 'upload':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
        break;
      case 'transaction':
        if (currentStatementId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionsScreen(transactions: mockTransactions, bankName: currentBankName ?? 'Bank', statementId: currentStatementId)));
        } else {
          _showNoStatementWarning('Transactions');
        }
        break;
      case 'insights':
        if (currentStatementId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => InsightsScreen(statementId: currentStatementId!, bankName: currentBankName ?? 'Bank', insights: StatementInsights(totalIncome: 15000.0, totalExpense: 1419.0, netSavings: 13581.0, savingRate: 0.90, categoryBreakdown: {'Income': 15000.0, 'Food': 450.0, 'Entertainment': 649.0, 'Travel': 320.0}, subscriptions: [], anomalies: [], highestSpendingCategory: 'Entertainment'), totalTransactions: mockTransactions.length)));
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
    }
  }
}