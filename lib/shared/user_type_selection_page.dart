import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserTypeSelectionPage extends StatefulWidget {
  const UserTypeSelectionPage({super.key});

  @override
  State<UserTypeSelectionPage> createState() => _UserTypeSelectionPageState();
}

class _UserTypeSelectionPageState extends State<UserTypeSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _navigateToLogin(String userType) {
    String route;
    switch (userType) {
      case 'admin':
        route = '/admin-login';
        break;
      case 'consumer':
        route = '/consumer-login';
        break;
      case 'retailer':
        route = '/retailer-login';
        break;
      default:
        route = '/login'; // Fallback to generic login
        break;
    }
    
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildUserTypeCards(),
                    const SizedBox(height: 40),
                    _buildRegisterSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.login,
            size: 50,
            color: Colors.white,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text(
          'Choose Your Account Type',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'Select the type of account you want to log in with',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildUserTypeCards() {
    final userTypes = [
      {
        'type': 'admin',
        'title': 'Administrator',
        'subtitle': 'Manage the system and oversee operations',
        'icon': Icons.admin_panel_settings,
        'color': const Color(0xFFE53E3E),
        'gradient': const [Color(0xFFE53E3E), Color(0xFFC53030)],
      },
      {
        'type': 'consumer',
        'title': 'Consumer',
        'subtitle': 'Browse products and make purchases',
        'icon': Icons.shopping_cart,
        'color': const Color(0xFF38A169),
        'gradient': const [Color(0xFF38A169), Color(0xFF2F855A)],
      },
      {
        'type': 'retailer',
        'title': 'Retailer',
        'subtitle': 'Manage your store and sell products',
        'icon': Icons.store,
        'color': const Color(0xFF3182CE),
        'gradient': const [Color(0xFF3182CE), Color(0xFF2C5282)],
      },
    ];

    return Column(
      children: userTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final userType = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildUserTypeCard(
            userType: userType,
            delay: Duration(milliseconds: 200 + (index * 200)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserTypeCard({
    required Map<String, dynamic> userType,
    required Duration delay,
  }) {
    return GestureDetector(
      onTap: () => _navigateToLogin(userType['type']),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: userType['gradient'],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: userType['color'].withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  userType['icon'],
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userType['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userType['subtitle'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ).animate().slideX(
      begin: -0.3,
      duration: 600.ms,
      curve: Curves.easeOutCubic,
      delay: delay,
    ).fadeIn(
      duration: 600.ms,
      delay: delay,
    );
  }

  Widget _buildRegisterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add,
            size: 40,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          Text(
            'Don\'t have an account?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new account to get started',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: Text(
              'Register Now',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: 800.ms,
      duration: 600.ms,
    ).slideY(
      begin: 0.3,
      delay: 800.ms,
      duration: 600.ms,
      curve: Curves.easeOutCubic,
    );
  }
}
