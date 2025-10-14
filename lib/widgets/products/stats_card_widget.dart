import 'package:flutter/material.dart';
import '../../models/product_model.dart';

class StatsCardWidget extends StatelessWidget {
  final PriceAnalytics? analytics;
  final Map<String, dynamic> localStats;

  const StatsCardWidget({
    super.key,
    required this.analytics,
    required this.localStats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Products',
                  analytics?.totalProducts.toString() ?? localStats['total'].toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Compliant',
                  analytics?.compliantProducts.toString() ?? localStats['compliant'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Overpriced',
                  analytics?.overpricedProducts.toString() ?? localStats['overpriced'].toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Compliance Rate',
                  '${(analytics?.complianceRate ?? localStats['compliance_rate']).toStringAsFixed(1)}%',
                  Icons.analytics,
                  _getComplianceColor(analytics?.complianceRate ?? localStats['compliance_rate']),
                ),
              ),
            ],
          ),
          
          // Detailed Analytics Card (if available)
          if (analytics != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(
                          'Price Analytics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAnalyticsItem(
                          'Avg SRP',
                          '₱${analytics!.averageSRP.toStringAsFixed(2)}',
                          Colors.blue,
                        ),
                        _buildAnalyticsItem(
                          'Avg Monitored',
                          '₱${analytics!.averageMonitoredPrice.toStringAsFixed(2)}',
                          Colors.green,
                        ),
                        _buildAnalyticsItem(
                          'Avg Deviation',
                          '₱${analytics!.averageDeviation.toStringAsFixed(2)}',
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getComplianceColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }
}
