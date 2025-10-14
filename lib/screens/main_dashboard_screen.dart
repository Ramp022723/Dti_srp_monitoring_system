import 'package:flutter/material.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E40AF),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'DTI Price Monitoring',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E40AF),
                      Color(0xFF3B82F6),
                      Color(0xFF60A5FA),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.admin_panel_settings,
                        size: 60,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Dashboard Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Color(0xFF3B82F6),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Select a module to get started',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section Title
                const Text(
                  'Management Modules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 16),

                // Module Cards Grid
                _buildModuleCard(
                  context,
                  title: 'Price & Supply Monitoring',
                  description: 'Create and manage price monitoring forms',
                  icon: Icons.assignment,
                  color: const Color(0xFF3B82F6),
                  route: '/monitoring',
                  features: [
                    'Monitoring Forms',
                    'Product Tracking',
                    'Compliance Reports',
                    'Statistics',
                  ],
                ),

                _buildModuleCard(
                  context,
                  title: 'Product Price Management',
                  description: 'Manage products, SRP, and price analytics',
                  icon: Icons.inventory_2,
                  color: const Color(0xFF10B981),
                  route: '/products',
                  features: [
                    'Product CRUD',
                    'SRP History',
                    'Price Analytics',
                    'Folder Management',
                  ],
                ),

                _buildModuleCard(
                  context,
                  title: 'Retailer Store Management',
                  description: 'Monitor retailer compliance and violations',
                  icon: Icons.store,
                  color: const Color(0xFFF59E0B),
                  route: '/retailers',
                  features: [
                    'Retailer Monitoring',
                    'Price Violations',
                    'Compliance Tracking',
                    'Alert Management',
                  ],
                ),

                _buildModuleCard(
                  context,
                  title: 'Price Freeze Management',
                  description: 'Create and manage price freeze alerts',
                  icon: Icons.ac_unit,
                  color: const Color(0xFF8B5CF6),
                  route: '/price-freeze',
                  features: [
                    'Freeze Alerts',
                    'Notifications',
                    'Scheduling',
                    'Statistics',
                  ],
                ),

                _buildModuleCard(
                  context,
                  title: 'Product Folder Management',
                  description: 'Organize products in folders',
                  icon: Icons.folder,
                  color: const Color(0xFFEC4899),
                  route: '/folders',
                  features: [
                    'Folder Structure',
                    'Product Organization',
                    'Bulk Operations',
                    'Search & Filter',
                  ],
                ),

                const SizedBox(height: 32),

                // Footer Info
                Card(
                  color: const Color(0xFFEFF6FF),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.security,
                          color: Color(0xFF3B82F6),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Admin Access',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have full administrative privileges for all modules',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String route,
    required List<String> features,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features
                    .map((feature) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

