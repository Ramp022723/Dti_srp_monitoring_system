import 'package:flutter/material.dart';
import '../../models/monitoring_model.dart';

class FormSummaryWidget extends StatelessWidget {
  final MonitoringForm form;

  const FormSummaryWidget({
    super.key,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    final formStats = _calculateFormStats();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Color(0xFF3498db)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Form Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getComplianceColor(formStats['compliance_rate']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getComplianceColor(formStats['compliance_rate']).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${formStats['compliance_rate'].toStringAsFixed(0)}% Compliant',
                    style: TextStyle(
                      color: _getComplianceColor(formStats['compliance_rate']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Store Information
            _buildInfoSection('Store Information', [
              _buildInfoItem('Store Name', form.storeName),
              _buildInfoItem('Address', form.storeAddress),
              _buildInfoItem('Representative', form.storeRep),
            ]),

            const SizedBox(height: 16),

            // Monitoring Details
            _buildInfoSection('Monitoring Details', [
              _buildInfoItem('Date', _formatDate(form.monitoringDate)),
              _buildInfoItem('Mode', form.monitoringMode),
              _buildInfoItem('DTI Monitor', form.dtiMonitor),
            ]),

            const SizedBox(height: 16),

            // Statistics Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Monitoring Statistics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Total Products',
                          formStats['total_products'].toString(),
                          Icons.inventory,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Compliant',
                          formStats['compliant_products'].toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Overpriced',
                          formStats['overpriced_products'].toString(),
                          Icons.warning,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Compliance Rate',
                          '${formStats['compliance_rate'].toStringAsFixed(1)}%',
                          Icons.pie_chart,
                          _getComplianceColor(formStats['compliance_rate']),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Avg Deviation',
                          '₱${formStats['average_deviation'].toStringAsFixed(2)}',
                          Icons.trending_up,
                          formStats['average_deviation'] > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Compliance Status
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getComplianceColor(formStats['compliance_rate']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getComplianceColor(formStats['compliance_rate']).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getComplianceIcon(formStats['compliance_rate']),
                    color: _getComplianceColor(formStats['compliance_rate']),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getComplianceTitle(formStats['compliance_rate']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getComplianceColor(formStats['compliance_rate']),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getComplianceMessage(formStats['compliance_rate']),
                          style: TextStyle(
                            color: _getComplianceColor(formStats['compliance_rate']).withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF34495e),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateFormStats() {
    final products = form.products;
    final totalProducts = products.length;
    final compliantProducts = products.where((p) => p.isCompliant).length;
    final overpricedProducts = products.where((p) => p.isOverpriced).length;
    final averageDeviation = totalProducts > 0 
        ? products.map((p) => p.priceDeviation).reduce((a, b) => a + b) / totalProducts 
        : 0.0;
    final complianceRate = totalProducts > 0 ? (compliantProducts / totalProducts) * 100 : 0;

    return {
      'total_products': totalProducts,
      'compliant_products': compliantProducts,
      'overpriced_products': overpricedProducts,
      'compliance_rate': complianceRate,
      'average_deviation': averageDeviation,
    };
  }

  Color _getComplianceColor(double compliance) {
    if (compliance >= 80) return Colors.green;
    if (compliance >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getComplianceIcon(double compliance) {
    if (compliance >= 80) return Icons.check_circle;
    if (compliance >= 60) return Icons.warning;
    return Icons.error;
  }

  String _getComplianceTitle(double compliance) {
    if (compliance >= 80) return 'Excellent Compliance';
    if (compliance >= 60) return 'Moderate Compliance';
    return 'Poor Compliance';
  }

  String _getComplianceMessage(double compliance) {
    if (compliance >= 80) {
      return 'Store shows excellent price compliance. Keep up the good work!';
    } else if (compliance >= 60) {
      return 'Store has moderate compliance. Some price monitoring needed.';
    } else {
      return 'Store needs immediate attention for price compliance issues.';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
