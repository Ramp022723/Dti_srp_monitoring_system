import 'package:flutter/material.dart';
import '../../models/monitoring_model.dart';

class RecentFormsCard extends StatelessWidget {
  final List<MonitoringForm> forms;
  final bool isLoading;

  const RecentFormsCard({
    super.key,
    required this.forms,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF3498db)),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Monitoring Forms',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                if (forms.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/monitoring_forms');
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (forms.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No monitoring forms yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first monitoring form to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: forms.map((form) => _buildFormItem(context, form)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormItem(BuildContext context, MonitoringForm form) {
    final formStats = _calculateFormStats(form);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.storeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      form.storeAddress,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
                  '${formStats['compliance_rate'].toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _getComplianceColor(formStats['compliance_rate']),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Form Details Row
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.calendar_today,
                  _formatDate(form.monitoringDate),
                  'Date',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.monitor,
                  form.monitoringMode,
                  'Mode',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.inventory,
                  '${formStats['total_products']} products',
                  'Products',
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Statistics Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Compliant',
                  formStats['compliant_products'].toString(),
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Overpriced',
                  formStats['overpriced_products'].toString(),
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Avg Dev',
                  '₱${formStats['average_deviation'].toStringAsFixed(0)}',
                  Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/form_details',
                  arguments: form,
                );
              },
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3498db),
                side: const BorderSide(color: Color(0xFF3498db)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateFormStats(MonitoringForm form) {
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
