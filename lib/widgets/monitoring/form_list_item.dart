import 'package:flutter/material.dart';
import '../../models/monitoring_model.dart';

class FormListItem extends StatelessWidget {
  final MonitoringForm form;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FormListItem({
    super.key,
    required this.form,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formStats = _calculateFormStats();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            form.storeAddress,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                          case 'share':
                            _shareForm(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(Icons.more_vert),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Form Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailChip(
                        Icons.calendar_today,
                        _formatDate(form.monitoringDate),
                        'Date',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailChip(
                        Icons.monitor,
                        form.monitoringMode,
                        'Mode',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailChip(
                        Icons.inventory,
                        '${form.products.length} products',
                        'Products',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Statistics Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Compliant',
                          formStats['compliant_products'].toString(),
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Overpriced',
                          formStats['overpriced_products'].toString(),
                          Colors.orange,
                          Icons.warning,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Compliance',
                          '${formStats['compliance_rate'].toStringAsFixed(0)}%',
                          _getComplianceColor(formStats['compliance_rate']),
                          Icons.analytics,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footer Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Representative: ${form.storeRep}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'DTI Monitor: ${form.dtiMonitor}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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

                // Price Deviation Summary
                if (formStats['average_deviation'] != 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: formStats['average_deviation'] > 0 
                          ? Colors.red[50] 
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: formStats['average_deviation'] > 0 
                            ? Colors.red[200]! 
                            : Colors.green[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          formStats['average_deviation'] > 0 
                              ? Icons.trending_up 
                              : Icons.trending_down,
                          size: 16,
                          color: formStats['average_deviation'] > 0 
                              ? Colors.red[600] 
                              : Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Avg Deviation: ₱${formStats['average_deviation'].abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: formStats['average_deviation'] > 0 
                                ? Colors.red[600] 
                                : Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.blue[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.8),
          ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _shareForm(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
