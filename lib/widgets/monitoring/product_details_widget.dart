import 'package:flutter/material.dart';
import '../../models/monitoring_model.dart';

class ProductDetailsWidget extends StatelessWidget {
  final MonitoringProduct product;

  const ProductDetailsWidget({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.priceStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: product.priceStatusColor.withOpacity(0.3),
                      ),
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
                ],
              ),

              const SizedBox(height: 12),

              // Price Information Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildPriceItem(
                            'SRP',
                            '₱${product.srp.toStringAsFixed(2)}',
                            Icons.price_check,
                            Colors.blue,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: _buildPriceItem(
                            'Monitored Price',
                            '₱${product.monitoredPrice.toStringAsFixed(2)}',
                            Icons.visibility,
                            Colors.green,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: _buildPriceItem(
                            'Prevailing Price',
                            '₱${product.prevailingPrice.toStringAsFixed(2)}',
                            Icons.trending_up,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Deviation Information
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: product.priceStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: product.priceStatusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price Deviation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: product.priceStatusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₱${product.priceDeviation.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: product.priceStatusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Percentage',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: product.priceStatusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${product.priceDeviationPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: product.priceStatusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Product Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Unit',
                      product.unit,
                      Icons.straighten,
                    ),
                  ),
                  if (product.remarks.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailItem(
                        'Remarks',
                        product.remarks,
                        Icons.note,
                      ),
                    ),
                  ],
                ],
              ),

              // Price Analysis
              const SizedBox(height: 12),
              _buildPriceAnalysis(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceItem(String label, String value, IconData icon, Color color) {
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAnalysis() {
    String analysisText;
    Color analysisColor;
    IconData analysisIcon;

    if (product.isCompliant) {
      analysisText = 'This product is priced within the SRP guidelines. Excellent compliance!';
      analysisColor = Colors.green;
      analysisIcon = Icons.check_circle;
    } else if (product.priceDeviationPercentage <= 10) {
      analysisText = 'Minor price deviation detected. Monitor closely for any further increases.';
      analysisColor = Colors.orange;
      analysisIcon = Icons.warning;
    } else {
      analysisText = 'Significant price violation detected. Immediate action required.';
      analysisColor = Colors.red;
      analysisIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: analysisColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: analysisColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(analysisIcon, color: analysisColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Analysis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: analysisColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  analysisText,
                  style: TextStyle(
                    color: analysisColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
