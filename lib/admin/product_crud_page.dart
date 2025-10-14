import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/product_api_service.dart';
import '../models/product_model.dart';

class ProductCRUDPage extends StatefulWidget {
  const ProductCRUDPage({super.key});

  @override
  State<ProductCRUDPage> createState() => _ProductCRUDPageState();
}

class _ProductCRUDPageState extends State<ProductCRUDPage> {
  bool _isLoading = false;
  String? _error;
  List<Product> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _folders = [];
  final _api = ProductApiService();
  
  // Filter states
  String _selectedCategory = 'all';
  String _selectedFolder = 'all';
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load products from production API; categories/folders via AuthService for now
      final results = await Future.wait([
        _api.getProducts(limit: 50),
        AuthService.getProductCategories(),
        AuthService.getProductFolders(),
      ]);

      final products = results[0] as List<Product>;
      final categoriesData = (results[1] as Map<String, dynamic>)['data'] ?? {};
      final foldersData = (results[2] as Map<String, dynamic>)['data'] ?? {};

      setState(() {
        _products = products;
        _categories = categoriesData['data']?['categories'] ?? categoriesData['categories'] ?? [];
        _folders = foldersData['data']?['folders'] ?? foldersData['folders'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
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
        appBar: AppBar(
          title: const Text('Product Management'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, '/admin-dashboard'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildMainContent(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateProductDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Filters
        _buildFilters(),
        
        // Products List
        Expanded(
          child: _buildProductsList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                ..._categories.map((category) => DropdownMenuItem(
                  value: category['id'].toString(),
                  child: Text(category['name'] ?? 'Unknown'),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'all';
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFolder,
              decoration: const InputDecoration(
                labelText: 'Folder',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Folders')),
                ..._folders.map((folder) => DropdownMenuItem(
                  value: folder['id'].toString(),
                  child: Text(folder['name'] ?? 'Unknown'),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFolder = value ?? 'all';
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Products',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final filteredProducts = _getFilteredProducts();
    
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final image = product.imageUrl;
    final priceChipColor = (product.priceDifference ?? 0) > 0
        ? Colors.red[50]
        : Colors.green[50];
    final priceTextColor = (product.priceDifference ?? 0) > 0
        ? Colors.red[700]
        : Colors.green[700];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: image != null && image.isNotEmpty
                  ? Image.network(
                      'https://dtisrpmonitoring.bccbsis.com/$image',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: Colors.grey[400]),
                    )
                  : Icon(Icons.inventory_2, color: Colors.grey[400]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.productName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleProductAction(value, product),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(children: [Icon(Icons.visibility), SizedBox(width: 8), Text('View Details')]),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [Icon(Icons.delete), SizedBox(width: 8), Text('Delete')]),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _chip(Icons.category, product.categoryName ?? 'Uncategorized'),
                      if (product.folderName != null && product.folderName!.isNotEmpty)
                        _chip(Icons.folder, product.folderName!),
                      _chip(Icons.scale, product.unit ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: priceChipColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.price_change, size: 16, color: priceTextColor),
                            const SizedBox(width: 6),
                            Text(
                              'SRP ₱${product.srp.toStringAsFixed(2)}',
                              style: TextStyle(color: priceTextColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.prevailingPrice != null && product.prevailingPrice! > 0)
                        Text(
                          'Prevailing ₱${product.prevailingPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  List<Product> _getFilteredProducts() {
    return _products.where((product) {
      // Category filter
      if (_selectedCategory != 'all') {
        if (product.categoryId?.toString() != _selectedCategory) {
          return false;
        }
      }
      
      // Folder filter
      if (_selectedFolder != 'all') {
        if (product.folderId?.toString() != _selectedFolder) {
          return false;
        }
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final productName = product.productName.toLowerCase();
        final categoryName = (product.categoryName ?? '').toLowerCase();
        final folderName = (product.folderName ?? '').toLowerCase();
        
        if (!productName.contains(query) && 
            !categoryName.contains(query) && 
            !folderName.contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      // Trigger rebuild with new filters
    });
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'view':
        _showProductDetails(product);
        break;
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'delete':
        _deleteProduct(product);
        break;
    }
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.productName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', product.categoryName ?? 'N/A'),
              _buildDetailRow('Folder', product.folderName ?? 'N/A'),
              _buildDetailRow('SRP', '₱${product.srp.toStringAsFixed(2)}'),
              _buildDetailRow('Prevailing', product.prevailingPrice == null ? 'N/A' : '₱${product.prevailingPrice!.toStringAsFixed(2)}'),
              _buildDetailRow('Unit', product.unit ?? 'N/A'),
              _buildDetailRow('Created', product.createdAt == null ? 'N/A' : _formatDate(product.createdAt!.toIso8601String())),
              if (product.updatedAt != null)
                _buildDetailRow('Updated', _formatDate(product.updatedAt!.toIso8601String())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showCreateProductDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateProductDialog(
        categories: _categories,
        folders: _folders,
        onProductCreated: _loadData,
      ),
    );
  }

  void _showEditProductDialog(dynamic product) {
    showDialog(
      context: context,
      builder: (context) => _EditProductDialog(
        product: product,
        categories: _categories,
        folders: _folders,
        onProductUpdated: _loadData,
      ),
    );
  }

  Future<void> _deleteProduct(dynamic product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product['product_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await AuthService.removeProduct(
          productId: int.parse(product['id'].toString()),
        );
        
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete product'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Create Product Dialog
class _CreateProductDialog extends StatefulWidget {
  final List<dynamic> categories;
  final List<dynamic> folders;
  final VoidCallback onProductCreated;

  const _CreateProductDialog({
    required this.categories,
    required this.folders,
    required this.onProductCreated,
  });

  @override
  State<_CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<_CreateProductDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCategoryId;
  int? _selectedFolderId;
  final _productNameController = TextEditingController();
  final _srpController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Product'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter product name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories.map((category) => DropdownMenuItem<int>(
                  value: category['id'] as int,
                  child: Text(category['name'] ?? 'Unknown'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedFolderId,
                decoration: const InputDecoration(labelText: 'Folder (Optional)'),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('No Folder')),
                  ...widget.folders.map((folder) => DropdownMenuItem<int>(
                    value: folder['id'] as int,
                    child: Text(folder['name'] ?? 'Unknown'),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFolderId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _srpController,
                decoration: const InputDecoration(labelText: 'SRP (Suggested Retail Price)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter SRP';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unit (e.g., kg, piece, liter)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter unit' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.createNewProduct(
        productName: _productNameController.text,
        brand: 'Unknown', // Default brand
        manufacturer: 'Unknown', // Default manufacturer
        categoryId: _selectedCategoryId!,
        srp: double.parse(_srpController.text),
        unit: _unitController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onProductCreated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Edit Product Dialog
class _EditProductDialog extends StatefulWidget {
  final dynamic product;
  final List<dynamic> categories;
  final List<dynamic> folders;
  final VoidCallback onProductUpdated;

  const _EditProductDialog({
    required this.product,
    required this.categories,
    required this.folders,
    required this.onProductUpdated,
  });

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _srpController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;
  int? _selectedCategoryId;
  int? _selectedFolderId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.product['product_name'] ?? '');
    _srpController = TextEditingController(text: widget.product['srp']?.toString() ?? '');
    _unitController = TextEditingController(text: widget.product['unit'] ?? '');
    _descriptionController = TextEditingController(text: widget.product['description'] ?? '');
    _selectedCategoryId = widget.product['category_id'];
    _selectedFolderId = widget.product['folder_id'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Product'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter product name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories.map((category) => DropdownMenuItem<int>(
                  value: category['id'] as int,
                  child: Text(category['name'] ?? 'Unknown'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedFolderId,
                decoration: const InputDecoration(labelText: 'Folder (Optional)'),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('No Folder')),
                  ...widget.folders.map((folder) => DropdownMenuItem<int>(
                    value: folder['id'] as int,
                    child: Text(folder['name'] ?? 'Unknown'),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFolderId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _srpController,
                decoration: const InputDecoration(labelText: 'SRP (Suggested Retail Price)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter SRP';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unit (e.g., kg, piece, liter)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter unit' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.updateProductDetails(
        productId: int.parse(widget.product['id'].toString()),
        productName: _productNameController.text,
        categoryId: _selectedCategoryId!,
        srp: double.parse(_srpController.text),
        unit: _unitController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onProductUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
