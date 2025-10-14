import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/monitoring/stats_overview_card.dart';
import '../../widgets/monitoring/recent_forms_card.dart';
import '../../widgets/monitoring/quick_actions_card.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<MonitoringProvider>(context, listen: false);
    await provider.fetchMonitoringStats();
    await provider.fetchMonitoringForms(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price & Supply Monitoring'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Consumer<MonitoringProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stats == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Data',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadInitialData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3498db), Color(0xFF2980b9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome to Price & Supply Monitoring',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Monitor and track product pricing compliance across retail stores',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistics Overview
                  StatsOverviewCard(stats: provider.stats),

                  const SizedBox(height: 24),

                  // Quick Actions
                  const QuickActionsCard(),

                  const SizedBox(height: 24),

                  // Recent Forms
                  RecentFormsCard(
                    forms: provider.monitoringForms.take(5).toList(),
                    isLoading: provider.isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Store Performance (if available)
                  if (provider.stores.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.store, color: Color(0xFF3498db)),
                                const SizedBox(width: 8),
                                Text(
                                  'Store Performance',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...provider.stores.take(3).map((store) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getComplianceColor(store.averageCompliance),
                                child: Text(
                                  '${store.averageCompliance.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(store.name),
                              subtitle: Text(
                                '${store.monitoringCount} monitoring sessions',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: store.lastMonitoring != null
                                  ? Text(
                                      _formatDate(store.lastMonitoring!),
                                      style: TextStyle(color: Colors.grey[600]),
                                    )
                                  : const Text('No recent monitoring'),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Bottom padding for FAB
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/monitoring/create-form');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Monitoring Form'),
        backgroundColor: const Color(0xFF3498db),
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getComplianceColor(double compliance) {
    if (compliance >= 80) return Colors.green;
    if (compliance >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

