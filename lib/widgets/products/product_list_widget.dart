import 'package:flutter/material.dart';
import '../../models/product_model.dart';

class ProductListWidget extends StatelessWidget {
  final List<Product> products;
  final Set<int> selectedIds;
  final Function(Product) onProductTap;
  final Function(Product) onProductLongPress;
  final Function(int, bool) onSelectionChanged;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoading;

  const ProductListWidget({
    super.key,
    required this.products,
    required this.selectedIds,
    required this.onProductTap,
    required this.onProductLongPress,
    required this.onSelectionChanged,
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or add a new product',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!isLoading &&
            hasMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final product = products[index];
          final isSelected = selectedIds.contains(product.productId);

          return _buildProductCard(context, product, isSelected);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => selectedIds.isEmpty ? onProductTap(product) : onSelectionChanged(product.productId, !isSelected),
        onLongPress: () => onProductLongPress(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  if (selectedIds.isNotEmpty)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => onSelectionChanged(product.productId, value ?? false),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.brand != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.brand!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.priceStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: product.priceStatusColor),
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

              const SizedBox(height: 16),

              // Price Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPriceItem('SRP', product.srp, Colors.blue),
                    ),
                    if (product.monitoredPrice != null) ...[
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      Expanded(
                        child: _buildPriceItem('Monitored', product.monitoredPrice!, Colors.green),
                      ),
                    ],
                    if (product.prevailingPrice != null) ...[
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      Expanded(
                        child: _buildPriceItem('Prevailing', product.prevailingPrice!, Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),

              // Additional Info
              if (product.categoryName != null || product.folderName != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (product.categoryName != null)
                      Chip(
                        avatar: const Icon(Icons.category, size: 16),
                        label: Text(product.categoryName!),
                        backgroundColor: const Color(0xFFEFF6FF),
                        labelStyle: const TextStyle(color: Color(0xFF3B82F6)),
                      ),
                    if (product.folderName != null)
                      Chip(
                        avatar: const Icon(Icons.folder, size: 16),
                        label: Text(product.folderName!),
                        backgroundColor: const Color(0xFFFEF3C7),
                        labelStyle: const TextStyle(color: Color(0xFFD97706)),
                      ),
                    if (product.unit != null)
                      Chip(
                        avatar: const Icon(Icons.straighten, size: 16),
                        label: Text(product.unit!),
                        backgroundColor: Colors.grey[200],
                      ),
                  ],
                ),
              ],

              // Price Deviation Indicator
              if (product.monitoredPrice != null && product.priceDeviation != 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: product.priceStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: product.priceStatusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deviation: ₱${product.priceDeviation.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: product.priceStatusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${product.priceDeviationPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: product.priceStatusColor,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildPriceItem(String label, double price, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₱${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
