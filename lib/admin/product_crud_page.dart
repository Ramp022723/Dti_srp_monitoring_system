import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProductCRUDPage extends StatefulWidget {
  const ProductCRUDPage({super.key});

  @override
  State<ProductCRUDPage> createState() => _ProductCRUDPageState();
}

class _ProductCRUDPageState extends State<ProductCRUDPage> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _folders = [];
  
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
      // Load all data in parallel
      final results = await Future.wait([
        AuthService.getAllProducts(),
        AuthService.getProductCategories(),
        AuthService.getProductFolders(),
      ]);

      if (results.every((result) => result['status'] == 'success')) {
        setState(() {
          // Parse products data
          final productsData = results[0]['data'] ?? {};
          _products = productsData['data']?['products'] ?? productsData['products'] ?? [];
          
          // Parse categories data
          final categoriesData = results[1]['data'] ?? {};
          _categories = categoriesData['data']?['categories'] ?? categoriesData['categories'] ?? [];
          
          // Parse folders data
          final foldersData = results[2]['data'] ?? {};
          _folders = foldersData['data']?['folders'] ?? foldersData['folders'] ?? [];
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data';
          _isLoading = false;
        });
      }
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(
            Icons.inventory,
            color: Colors.green[700],
            size: 20,
          ),
        ),
        title: Text(
          product['product_name'] ?? 'Unknown Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${product['category_name'] ?? 'N/A'}'),
            Text('Folder: ${product['folder_name'] ?? 'N/A'}'),
            Text('SRP: ₱${product['srp']?.toString() ?? 'N/A'}'),
            Text('Unit: ${product['unit'] ?? 'N/A'}'),
            if (product['created_at'] != null)
              Text('Created: ${_formatDate(product['created_at'])}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(value, product),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showProductDetails(product),
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

  List<dynamic> _getFilteredProducts() {
    return _products.where((product) {
      // Category filter
      if (_selectedCategory != 'all') {
        if (product['category_id']?.toString() != _selectedCategory) {
          return false;
        }
      }
      
      // Folder filter
      if (_selectedFolder != 'all') {
        if (product['folder_id']?.toString() != _selectedFolder) {
          return false;
        }
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final productName = product['product_name']?.toString().toLowerCase() ?? '';
        final categoryName = product['category_name']?.toString().toLowerCase() ?? '';
        final folderName = product['folder_name']?.toString().toLowerCase() ?? '';
        
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

  void _handleProductAction(String action, dynamic product) {
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

  void _showProductDetails(dynamic product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['product_name'] ?? 'Product Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', product['category_name'] ?? 'N/A'),
              _buildDetailRow('Folder', product['folder_name'] ?? 'N/A'),
              _buildDetailRow('SRP', '₱${product['srp']?.toString() ?? 'N/A'}'),
              _buildDetailRow('Unit', product['unit'] ?? 'N/A'),
              _buildDetailRow('Description', product['description'] ?? 'N/A'),
              _buildDetailRow('Created', _formatDate(product['created_at'] ?? '')),
              if (product['updated_at'] != null)
                _buildDetailRow('Updated', _formatDate(product['updated_at'])),
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
