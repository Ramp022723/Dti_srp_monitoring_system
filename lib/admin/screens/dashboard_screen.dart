import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/recent_activity_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.userDisplayName,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Here\'s what\'s happening with your system today.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppConstants.largePadding),
              
              // Statistics Cards
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.defaultPadding,
                mainAxisSpacing: AppConstants.defaultPadding,
                childAspectRatio: 1.5,
                children: const [
                  StatCard(
                    title: 'Total Consumers',
                    value: '1,234',
                    icon: Icons.people,
                    color: AppTheme.primaryColor,
                    change: '+5.2%',
                    changeType: ChangeType.positive,
                  ),
                  StatCard(
                    title: 'Total Retailers',
                    value: '456',
                    icon: Icons.store,
                    color: AppTheme.successColor,
                    change: '+3.1%',
                    changeType: ChangeType.positive,
                  ),
                  StatCard(
                    title: 'Total Products',
                    value: '7,890',
                    icon: Icons.inventory,
                    color: AppTheme.warningColor,
                    change: '-1.2%',
                    changeType: ChangeType.negative,
                  ),
                  StatCard(
                    title: 'Active Alerts',
                    value: '12',
                    icon: Icons.warning,
                    color: AppTheme.errorColor,
                    change: '+2',
                    changeType: ChangeType.neutral,
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.largePadding),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.defaultPadding,
                mainAxisSpacing: AppConstants.defaultPadding,
                childAspectRatio: 1.2,
                children: [
                  QuickActionCard(
                    title: 'Manage Users',
                    icon: Icons.people_outline,
                    color: AppTheme.primaryColor,
                    onTap: () {
                      // Navigate to user management
                    },
                  ),
                  QuickActionCard(
                    title: 'Manage Products',
                    icon: Icons.inventory_outlined,
                    color: AppTheme.successColor,
                    onTap: () {
                      // Navigate to product management
                    },
                  ),
                  QuickActionCard(
                    title: 'View Complaints',
                    icon: Icons.report_problem_outlined,
                    color: AppTheme.warningColor,
                    onTap: () {
                      // Navigate to complaint management
                    },
                  ),
                  QuickActionCard(
                    title: 'Generate Report',
                    icon: Icons.assessment_outlined,
                    color: AppTheme.infoColor,
                    onTap: () {
                      _generateReport();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.largePadding),
              
              // Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              Card(
                child: Column(
                  children: const [
                    RecentActivityItem(
                      icon: Icons.person_add,
                      title: 'New consumer registered',
                      subtitle: 'John Doe joined the platform',
                      time: '5 minutes ago',
                      color: AppTheme.primaryColor,
                    ),
                    Divider(height: 1),
                    RecentActivityItem(
                      icon: Icons.store,
                      title: 'New retailer added',
                      subtitle: 'ABC Store registered',
                      time: '2 hours ago',
                      color: AppTheme.successColor,
                    ),
                    Divider(height: 1),
                    RecentActivityItem(
                      icon: Icons.inventory,
                      title: 'New product added',
                      subtitle: 'Product XYZ was added',
                      time: '1 day ago',
                      color: AppTheme.warningColor,
                    ),
                    Divider(height: 1),
                    RecentActivityItem(
                      icon: Icons.report_problem,
                      title: 'Complaint received',
                      subtitle: 'Product quality issue reported',
                      time: '2 days ago',
                      color: AppTheme.errorColor,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.largePadding),
              
              // Price Freeze Alerts
              Text(
                'Price Freeze Alerts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.warning,
                              color: AppTheme.warningColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Price Alert',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Price freeze alert for Product XYZ',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightTextMuted,
                                  ),
                                ),
                                Text(
                                  'Dec 1, 2024',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightTextMuted,
                                  ),
                                ),
                                Text(
                                  'Dec 31, 2024',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
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
              
              const SizedBox(height: AppConstants.largePadding),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _refreshData() async {
    // TODO: Implement data refresh
    await Future.delayed(const Duration(seconds: 1));
  }
  
  void _generateReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: const Text('This will generate a comprehensive system report. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement report generation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report generation started...'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
