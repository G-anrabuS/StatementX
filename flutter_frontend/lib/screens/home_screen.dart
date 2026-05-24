import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Section keys for scrolling behavior
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _securityKey = GlobalKey();

  bool _isDarkMode = false; // Toggle placeholder state

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

  void _navigateToUploader() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : bgSlate,
      drawer: isMobile ? _buildMobileDrawer(brandBlue) : null,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: _buildHeader(isMobile, brandBlue, textNavy),
      ),
      body: SingleChildScrollView(
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
      ),
    );
  }

  // APP BAR / HEADER WIDGET
  Widget _buildHeader(bool isMobile, Color brandBlue, Color textNavy) {
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
          _buildHeaderNavLink('How It Works', () => _scrollToSection(_securityKey)),
          _buildHeaderNavLink('Security', () => _scrollToSection(_securityKey)),
          _buildHeaderNavLink('About', () => _scrollToSection(_heroKey)),
          const SizedBox(width: 8),
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

  // MOBILE DRAWER
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
            _buildDrawerItem(Icons.psychology_rounded, 'How It Works', () {
              Navigator.pop(context);
              _scrollToSection(_securityKey);
            }),
            _buildDrawerItem(Icons.security_rounded, 'Security', () {
              Navigator.pop(context);
              _scrollToSection(_securityKey);
            }),
            _buildDrawerItem(Icons.info_rounded, 'About', () {
              Navigator.pop(context);
              _scrollToSection(_heroKey);
            }),
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToUploader();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
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

  // HERO: LEFT HALF (TEXT / CALL-TO-ACTIONS)
  Widget _buildHeroLeft(bool isMobile, Color brandBlue, Color brandTeal, Color textNavy, Color textMuted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Pill Badge "Smart. Secure. Simple."
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

        // Hero Titles
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

        // Subtitle
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

        // Action Buttons Grid
        isMobile
            ? Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _navigateToUploader,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _navigateToUploader,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandBlue,
                        side: BorderSide(color: brandBlue.withOpacity(0.4), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _navigateToUploader,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 140,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _navigateToUploader,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandBlue,
                        side: BorderSide(color: brandBlue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        SizedBox(height: isMobile ? 20 : 32),

        // Subtext Security Alert
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

  // HERO: RIGHT HALF (3D-LIKE VECTOR ILLUSTRATION DESIGN)
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
            // 1. Soft Glow Backdrop
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

            // 2. Base "Bank Statement" Sheet (Slightly angled/skewed)
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
                    
                    // Donut Chart Vector Representation
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
                    
                    // Micro Bar Graph Mockup
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

            // 3. Floating Credit Card (Placed overlapping the statement card)
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

            // 4. Floating Checkmark Security Shield (Bottom right offset)
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

  // FEATURES: CARD BUILDER WIDGET
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
          // Circular Icon Frame
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

  // SECURITY: WORKS EVERYWHERE BANNER
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

  // FOOTER WIDGET
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
                        Icon(Icons.account_balance_rounded, color: const Color(0xFF4F46E5), size: 18),
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
                        Icon(Icons.account_balance_rounded, color: const Color(0xFF4F46E5), size: 18),
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
}