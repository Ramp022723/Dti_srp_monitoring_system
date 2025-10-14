import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/monitoring_model.dart';
import '../../widgets/monitoring/product_details_widget.dart';
import '../../widgets/monitoring/form_summary_widget.dart';

class FormDetailsScreen extends StatelessWidget {
  final MonitoringForm form;

  const FormDetailsScreen({
    super.key,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Details - ${form.storeName}'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareForm(context),
            tooltip: 'Share Form',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printForm(context),
            tooltip: 'Print Form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Summary
            FormSummaryWidget(form: form),

            const SizedBox(height: 16),

            // Products Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory, color: Color(0xFF3498db)),
                        const SizedBox(width: 8),
                        Text(
                          'Basic Necessities and Prime Commodities',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Products Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                        columns: const [
                          DataColumn(label: Text('Product Name')),
                          DataColumn(label: Text('Unit')),
                          DataColumn(label: Text('SRP')),
                          DataColumn(label: Text('Monitored Price')),
                          DataColumn(label: Text('Prevailing Price')),
                          DataColumn(label: Text('Deviation')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Remarks')),
                        ],
                        rows: form.products.map((product) {
                          return DataRow(
                            cells: [
                              DataCell(Text(product.productName)),
                              DataCell(Text(product.unit)),
                              DataCell(Text('₱${product.srp.toStringAsFixed(2)}')),
                              DataCell(Text('₱${product.monitoredPrice.toStringAsFixed(2)}')),
                              DataCell(Text('₱${product.prevailingPrice.toStringAsFixed(2)}')),
                              DataCell(Text(
                                '₱${product.priceDeviation.toStringAsFixed(2)}\n(${product.priceDeviationPercentage.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  color: product.priceDeviationColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              )),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: product.priceStatusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: product.priceStatusColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    product.priceStatusText,
                                    style: TextStyle(
                                      color: product.priceStatusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(product.remarks)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Products Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProductStat(
                            'Total Products',
                            form.products.length.toString(),
                            Icons.inventory,
                            Colors.blue,
                          ),
                          _buildProductStat(
                            'Compliant',
                            form.products.where((p) => p.isCompliant).length.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildProductStat(
                            'Overpriced',
                            form.products.where((p) => p.isOverpriced).length.toString(),
                            Icons.warning,
                            Colors.orange,
                          ),
                          _buildProductStat(
                            'Avg Deviation',
                            '₱${_calculateAverageDeviation().toStringAsFixed(2)}',
                            Icons.trending_up,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Individual Product Details
            ...form.products.map((product) => ProductDetailsWidget(product: product)),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/edit_form',
                        arguments: form,
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Form'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3498db),
                      side: const BorderSide(color: Color(0xFF3498db)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportForm(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498db),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
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
    );
  }

  double _calculateAverageDeviation() {
    if (form.products.isEmpty) return 0.0;
    final totalDeviation = form.products
        .map((p) => p.priceDeviation)
        .reduce((a, b) => a + b);
    return totalDeviation / form.products.length;
  }

  void _shareForm(BuildContext context) {
    final formData = _generateFormSummary();
    Clipboard.setData(ClipboardData(text: formData));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form details copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printForm(BuildContext context) {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportForm(BuildContext context) {
    // TODO: Implement PDF export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _generateFormSummary() {
    final buffer = StringBuffer();
    buffer.writeln('MONITORING FORM SUMMARY');
    buffer.writeln('======================');
    buffer.writeln('Store Name: ${form.storeName}');
    buffer.writeln('Store Address: ${form.storeAddress}');
    buffer.writeln('Monitoring Date: ${_formatDate(form.monitoringDate)}');
    buffer.writeln('Monitoring Mode: ${form.monitoringMode}');
    buffer.writeln('Store Representative: ${form.storeRep}');
    buffer.writeln('DTI Monitor: ${form.dtiMonitor}');
    buffer.writeln('');
    buffer.writeln('PRODUCTS MONITORED:');
    buffer.writeln('==================');
    
    for (int i = 0; i < form.products.length; i++) {
      final product = form.products[i];
      buffer.writeln('${i + 1}. ${product.productName}');
      buffer.writeln('   Unit: ${product.unit}');
      buffer.writeln('   SRP: ₱${product.srp.toStringAsFixed(2)}');
      buffer.writeln('   Monitored Price: ₱${product.monitoredPrice.toStringAsFixed(2)}');
      buffer.writeln('   Prevailing Price: ₱${product.prevailingPrice.toStringAsFixed(2)}');
      buffer.writeln('   Deviation: ₱${product.priceDeviation.toStringAsFixed(2)} (${product.priceDeviationPercentage.toStringAsFixed(1)}%)');
      buffer.writeln('   Status: ${product.priceStatusText}');
      if (product.remarks.isNotEmpty) {
        buffer.writeln('   Remarks: ${product.remarks}');
      }
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
