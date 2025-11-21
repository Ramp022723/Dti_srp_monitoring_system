import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/browse_products_widget.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int currentSlide = 0;
  bool isMenuOpen = false;
  late PageController _pageController;

  final List<String> backgroundImages = [
    'assets/beautiful-street-market-sunset.jpg',
    'assets/family-shopping-with-face-mask.jpg',
    'assets/vegetables-market-counter.jpg',
    'assets/bg4.jpg',
    'assets/bg5.jpg',
  ];

  final List<Map<String, dynamic>> features = [
    {
      'icon': Icons.people,
      'title': "Connect Locally",
      'description': "Connect with consumers and retailers in Bago City"
    },
    {
      'icon': Icons.trending_up,
      'title': "Official Prices",
      'description': "View official suggested retail prices"
    },
    {
      'icon': Icons.security,
      'title': "Shop Safely",
      'description': "Shop with confidence and security"
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        nextSlide();
        _startAutoSlide();
      }
    });
  }

  void nextSlide() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
    );
  }

  void prevSlide() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
    );
  }

  void _showBrowseProducts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Browse Products',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: const BrowseProductsWidget(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the status bar height
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Carousel
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: backgroundImages.length,
              onPageChanged: (index) {
                setState(() {
                  currentSlide = index;
                });
              },
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Image.asset(
                      backgroundImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Carousel Controls
          Positioned(
            left: 16,
            top: MediaQuery.of(context).size.height / 2,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white.withOpacity(0.2),
              onPressed: prevSlide,
              child: const Icon(Icons.chevron_left, color: Colors.white),
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white.withOpacity(0.2),
              onPressed: nextSlide,
              child: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),

          // Slide Indicators
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(backgroundImages.length, (index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentSlide
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Header - Fixed positioning with SafeArea
          Positioned(
            top: statusBarHeight, // Use status bar height instead of 0
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // DTI Logo
                        Image.asset(
                          'assets/DTI_LOGO.png',
                          width: 48,
                          height: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DTI Tracking and Consumer Portal System',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue[600],
                                ),
                              ),
                              Text(
                                'Department of Trade and Industry',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isMenuOpen ? Icons.close : Icons.menu,
                            color: Colors.blue[600],
                          ),
                          onPressed: () {
                            setState(() {
                              isMenuOpen = !isMenuOpen;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isMenuOpen)
                    Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info, color: Colors.blue),
                          title: const Text('About'),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('About'),
                                content: Text('DTI Tracking and Consumer Portal System\nDepartment of Trade and Industry'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.mail, color: Colors.blue),
                          title: const Text('Contact'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Contact us at dti@example.com')),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                          title: const Text('Browse Products'),
                          onTap: () {
                            setState(() {
                              isMenuOpen = false;
                            });
                            _showBrowseProducts(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.login, color: Colors.blue),
                          title: const Text('Login'),
                          onTap: () {
                            Navigator.pushNamed(context, '/user-type-selection');
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Main Content - Adjusted top padding
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: statusBarHeight + 80), // Adjusted padding
              child: Column(
                children: [
                  // Hero Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100]?.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Official DTI Platform',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Connect with Locals in\nBago City',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Use our platform to connect with local consumers and retailers in your locality. '
                          'View official suggested retail prices and shop with confidence.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue[600],
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 4,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/user-type-selection');
                              },
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('About DTI Portal'),
                                    content: const Text(
                                      'DTI Tracking and Consumer Portal System helps connect consumers and retailers in Bago City, Negros Occidental. '
                                      'View official suggested retail prices, shop with confidence, and connect with your local community.'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                'Learn More',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Browse Products Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            _showBrowseProducts(context);
                          },
                          icon: const Icon(Icons.shopping_bag),
                          label: Text(
                            'Browse Products',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Features Grid
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: features.map((feature) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    feature['icon'],
                                    color: Colors.blue[600],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        feature['title'],
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Text(
                                        feature['description'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Stats Section
                  Card(
                    margin: const EdgeInsets.all(24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Trusted by the Community',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '500+',
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                  Text(
                                    'Registered Retailers',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '2000+',
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                  Text(
                                    'Active Consumers',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quick Access
                  Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue[600]!,
                          Colors.blue[700]!,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Ready to Join?',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start connecting with your local community today',
                          style: GoogleFonts.poppins(
                            color: Colors.blue[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue[600],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            'Sign Up Now',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white.withOpacity(0.95),
                    child: Column(
                      children: [
                        Text(
                          '© 2024 Department of Trade and Industry - Philippines',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Bago City, Negros Occidental',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Elements - Adjusted for status bar
          Positioned(
            top: statusBarHeight + 120,
            right: 32,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ).animate().moveY(duration: 2000.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            top: statusBarHeight + 400,
            left: 24,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue[300]?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ).animate().scale(duration: 1500.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: 120,
            right: 48,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ).animate().fade(duration: 1000.ms, curve: Curves.easeInOut),
          ),
          if (isMenuOpen)
            Positioned(
              top: statusBarHeight + 60, // adjust as needed
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Container(
                  width: 220,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info, color: Colors.blue),
                        title: const Text('About'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('About'),
                              content: Text('DTI Tracking and Consumer Portal System\nDepartment of Trade and Industry'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.mail, color: Colors.blue),
                        title: const Text('Contact'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Contact us at dti@example.com')),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                        title: const Text('Browse Products'),
                        onTap: () {
                          setState(() {
                            isMenuOpen = false;
                          });
                          _showBrowseProducts(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.login, color: Colors.blue),
                        title: const Text('Login'),
                        onTap: () {
                          Navigator.pushNamed(context, '/user-type-selection');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}