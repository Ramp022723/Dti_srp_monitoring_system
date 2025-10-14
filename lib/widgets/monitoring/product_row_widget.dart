import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/monitoring_model.dart';

class ProductRowWidget extends StatefulWidget {
  final MonitoringProduct product;
  final int index;
  final Function(MonitoringProduct) onProductChanged;
  final VoidCallback? onDelete;

  const ProductRowWidget({
    super.key,
    required this.product,
    required this.index,
    required this.onProductChanged,
    this.onDelete,
  });

  @override
  State<ProductRowWidget> createState() => _ProductRowWidgetState();
}

class _ProductRowWidgetState extends State<ProductRowWidget> {
  late TextEditingController _productNameController;
  late TextEditingController _unitController;
  late TextEditingController _srpController;
  late TextEditingController _monitoredPriceController;
  late TextEditingController _prevailingPriceController;
  late TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.product.productName);
    _unitController = TextEditingController(text: widget.product.unit);
    _srpController = TextEditingController(text: widget.product.srp.toString());
    _monitoredPriceController = TextEditingController(text: widget.product.monitoredPrice.toString());
    _prevailingPriceController = TextEditingController(text: widget.product.prevailingPrice.toString());
    _remarksController = TextEditingController(text: widget.product.remarks);

    // Add listeners to update the product when text changes
    _productNameController.addListener(_updateProduct);
    _unitController.addListener(_updateProduct);
    _srpController.addListener(_updateProduct);
    _monitoredPriceController.addListener(_updateProduct);
    _prevailingPriceController.addListener(_updateProduct);
    _remarksController.addListener(_updateProduct);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _unitController.dispose();
    _srpController.dispose();
    _monitoredPriceController.dispose();
    _prevailingPriceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _updateProduct() {
    final updatedProduct = widget.product.copyWith(
      productName: _productNameController.text,
      unit: _unitController.text,
      srp: double.tryParse(_srpController.text) ?? 0.0,
      monitoredPrice: double.tryParse(_monitoredPriceController.text) ?? 0.0,
      prevailingPrice: double.tryParse(_prevailingPriceController.text) ?? 0.0,
      remarks: _remarksController.text,
    );
    widget.onProductChanged(updatedProduct);
  }

  @override
  Widget build(BuildContext context) {
    final currentProduct = MonitoringProduct(
      productName: _productNameController.text,
      unit: _unitController.text,
      srp: double.tryParse(_srpController.text) ?? 0.0,
      monitoredPrice: double.tryParse(_monitoredPriceController.text) ?? 0.0,
      prevailingPrice: double.tryParse(_prevailingPriceController.text) ?? 0.0,
      remarks: _remarksController.text,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Row number and delete button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498db),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.onDelete != null)
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove Product',
                  iconSize: 20,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Product inputs in a more mobile-friendly layout
          Column(
            children: [
              // Product Name (full width)
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Unit and SRP in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'kg, pcs, etc.',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _srpController,
                      decoration: const InputDecoration(
                        labelText: 'SRP',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixText: '₱ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Monitored Price and Prevailing Price in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _monitoredPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Monitored Price',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixText: '₱ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prevailingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Prevailing Price',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixText: '₱ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks (Optional)',
                  hintText: 'Enter any remarks or notes',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),

              // Price Analysis Card
              if (currentProduct.srp > 0 && currentProduct.monitoredPrice > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: currentProduct.priceStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: currentProduct.priceStatusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Price Analysis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentProduct.priceStatusColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currentProduct.priceStatusText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentProduct.priceStatusColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Deviation: ₱${currentProduct.priceDeviation.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            '${currentProduct.priceDeviationPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
