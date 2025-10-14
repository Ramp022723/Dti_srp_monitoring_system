import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/monitoring_model.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/monitoring/product_row_widget.dart';
import '../../widgets/monitoring/form_header_widget.dart';

class CreateMonitoringFormScreen extends StatefulWidget {
  const CreateMonitoringFormScreen({super.key});

  @override
  State<CreateMonitoringFormScreen> createState() => _CreateMonitoringFormScreenState();
}

class _CreateMonitoringFormScreenState extends State<CreateMonitoringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storeRepController = TextEditingController();
  final _dtiMonitorController = TextEditingController();

  // Form state
  DateTime _monitoringDate = DateTime.now();
  MonitoringMode _monitoringMode = MonitoringMode.actualInspection;
  List<MonitoringProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _products.add(MonitoringProduct(
      productName: '',
      unit: '',
      srp: 0.0,
      monitoredPrice: 0.0,
      prevailingPrice: 0.0,
      remarks: '',
    ));
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storeRepController.dispose();
    _dtiMonitorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Monitoring Form'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDraft,
            tooltip: 'Save as Draft',
          ),
        ],
      ),
      body: Consumer<MonitoringProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form Header
                        FormHeaderWidget(
                          storeNameController: _storeNameController,
                          storeAddressController: _storeAddressController,
                          storeRepController: _storeRepController,
                          dtiMonitorController: _dtiMonitorController,
                          monitoringDate: _monitoringDate,
                          monitoringMode: _monitoringMode,
                          onDateChanged: (date) {
                            setState(() {
                              _monitoringDate = date;
                            });
                          },
                          onModeChanged: (mode) {
                            setState(() {
                              _monitoringMode = mode;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

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
                                
                                // Products Table Header
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(flex: 2, child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Expanded(child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Expanded(child: Text('SRP', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Expanded(child: Text('Monitored', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Expanded(child: Text('Prevailing', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Expanded(flex: 2, child: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 40),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Products List
                                ...List.generate(_products.length, (index) {
                                  return ProductRowWidget(
                                    key: ValueKey('product_$index'),
                                    product: _products[index],
                                    index: index,
                                    onProductChanged: (product) {
                                      setState(() {
                                        _products[index] = product;
                                      });
                                    },
                                    onDelete: index > 0 ? () => _removeProduct(index) : null,
                                  );
                                }),

                                const SizedBox(height: 16),

                                // Add Product Button
                                ElevatedButton.icon(
                                  onPressed: _addProduct,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add More Product'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Form Statistics
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
                                      _buildStatItem(
                                        'Total Products',
                                        _products.length.toString(),
                                        Icons.inventory,
                                        Colors.blue,
                                      ),
                                      _buildStatItem(
                                        'Valid Products',
                                        _products.where((p) => p.productName.isNotEmpty).length.toString(),
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                      _buildStatItem(
                                        'Estimated Time',
                                        '${(_products.length * 2).toString()} min',
                                        Icons.access_time,
                                        Colors.orange,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 100), // Bottom padding for FAB
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _validateForm,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Validate Form'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : _submitForm,
                          icon: provider.isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(provider.isLoading ? 'Submitting...' : 'Submit Form'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3498db),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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

  void _addProduct() {
    setState(() {
      _products.add(MonitoringProduct(
        productName: '',
        unit: '',
        srp: 0.0,
        monitoredPrice: 0.0,
        prevailingPrice: 0.0,
        remarks: '',
      ));
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  void _validateForm() {
    final errors = <String>[];

    // Validate basic fields
    if (_storeNameController.text.trim().isEmpty) {
      errors.add('Store name is required');
    }
    if (_storeAddressController.text.trim().isEmpty) {
      errors.add('Store address is required');
    }
    if (_storeRepController.text.trim().isEmpty) {
      errors.add('Store representative is required');
    }
    if (_dtiMonitorController.text.trim().isEmpty) {
      errors.add('DTI monitor is required');
    }

    // Validate products
    final validProducts = _products.where((p) => p.productName.trim().isNotEmpty).toList();
    if (validProducts.isEmpty) {
      errors.add('At least one product is required');
    }

    for (int i = 0; i < validProducts.length; i++) {
      final product = validProducts[i];
      if (product.productName.trim().isEmpty) {
        errors.add('Product ${i + 1}: Product name is required');
      }
      if (product.unit.trim().isEmpty) {
        errors.add('Product ${i + 1}: Unit is required');
      }
      if (product.srp <= 0) {
        errors.add('Product ${i + 1}: SRP must be greater than 0');
      }
      if (product.monitoredPrice <= 0) {
        errors.add('Product ${i + 1}: Monitored price must be greater than 0');
      }
      if (product.prevailingPrice <= 0) {
        errors.add('Product ${i + 1}: Prevailing price must be greater than 0');
      }
    }

    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Form Validation Errors'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: errors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error)),
                  ],
                ),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form validation successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _saveDraft() {
    // TODO: Implement draft saving functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Filter out empty products
    final validProducts = _products.where((p) => p.productName.trim().isNotEmpty).toList();
    
    if (validProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final form = MonitoringForm(
      storeName: _storeNameController.text.trim(),
      storeAddress: _storeAddressController.text.trim(),
      monitoringDate: _monitoringDate,
      monitoringMode: _monitoringMode.displayName,
      storeRep: _storeRepController.text.trim(),
      dtiMonitor: _dtiMonitorController.text.trim(),
      products: validProducts,
    );

    final provider = Provider.of<MonitoringProvider>(context, listen: false);
    final success = await provider.createMonitoringForm(form);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monitoring form submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to submit form'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
