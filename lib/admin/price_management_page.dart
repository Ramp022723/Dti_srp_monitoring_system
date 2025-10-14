import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/product_api_service.dart';

class PriceManagementPage extends StatefulWidget {
  const PriceManagementPage({super.key});

  @override
  State<PriceManagementPage> createState() => _PriceManagementPageState();
}

class _PriceManagementPageState extends State<PriceManagementPage> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Using the product price management API
      final result = await AuthService.getAllProducts();
      
      if (result['status'] == 'success') {
        setState(() {
          // The API returns {status, message, data: {success, message, data: {products, categories}}}
          final apiData = result['data'] ?? {};
          _products = apiData['data']?['products'] ?? apiData['products'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading products: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text(
            'Price Management',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.orange[600],
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadProducts,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildProductsContent(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsContent() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Products Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products to manage their prices',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    final productName = product['product_name'] ?? 'Unnamed Product';
    final srp = product['srp'] ?? product['price'] ?? '0.00';
    final category = product['category'] ?? 'Uncategorized';
    final productId = product['product_id'] ?? product['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2,
                color: Colors.orange[600],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SRP: ₱$srp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            // Edit Button
            IconButton(
              onPressed: () {
                _showUpdatePriceDialog(product);
              },
              icon: Icon(Icons.edit, color: Colors.orange[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdatePriceDialog(dynamic product) {
    final priceController = TextEditingController(
      text: (product['srp'] ?? product['price'] ?? '0.00').toString(),
    );
    final productId = product['product_id'] ?? product['id'];
    final productName = product['product_name'] ?? 'Product';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Price - $productName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'New Price (SRP)',
                hintText: 'Enter new price',
                border: OutlineInputBorder(),
                prefixText: '₱ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (priceController.text.isNotEmpty) {
                Navigator.pop(context);
                await _updatePrice(productId, priceController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePrice(dynamic productId, String newPrice) async {
    try {
      final result = await AuthService.updateProductPrices(
        productId: int.parse(productId.toString()),
        srp: double.parse(newPrice),
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price updated successfully'), backgroundColor: Colors.green),
        );
        _loadProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update price'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

