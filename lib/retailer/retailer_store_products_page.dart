import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'dart:async';


class RetailerStoreProductsPage extends StatefulWidget {
  const RetailerStoreProductsPage({Key? key}) : super(key: key);

  @override
  State<RetailerStoreProductsPage> createState() => _RetailerStoreProductsPageState();
}

class _RetailerStoreProductsPageState extends State<RetailerStoreProductsPage> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isLoadingFeedback = false;
  List<dynamic> _storeProducts = [];
  List<dynamic> _allProducts = [];
  List<dynamic> _feedbackReports = [];
  String? _error;
  String _selectedProductId = '';
  bool _isAddingProduct = false;
  
  // Real-time update variables
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  // Color scheme matching the PHP version
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryBlue = Color(0xFF1D4ED8);
  static const Color lightBlue = Color(0xFFDBEAFE);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color successGreen = Color(0xFF28A745);
  static const Color dangerRed = Color(0xFFDC3545);
  static const Color warningOrange = Color(0xFFFD7E14);
  static const Color infoCyan = Color(0xFF17A2B8);
  static const Color gray = Color(0xFF6C757D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _refreshData();
    }
  }

  void _initializeData() {
    _loadStoreProducts();
    _loadAllProducts();
    _loadFeedbackReports();
  }

  void _startPeriodicRefresh() {
    // Refresh every 30 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.wait([
        _loadStoreProducts(),
        _loadAllProducts(),
        _loadFeedbackReports(),
      ]);
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Retailer HTTP result mapper
  void _showHttpResultSnack(
    Map<String, dynamic> result, {
    String? fallbackSuccess,
    String? fallbackError,
  }) {
    if (!mounted) return;
    final dynamic rawStatus = result['http_status'];
    final int? httpStatus = rawStatus is int ? rawStatus : null;
    final String? code = result['code'] as String?;
    final bool isSuccess = (result['status'] == 'success') || httpStatus == 200 || code == 'HTTP_200';

    String message = (result['message'] as String?) ??
        (isSuccess ? (fallbackSuccess ?? 'Action completed successfully')
                   : (fallbackError ?? 'Action failed'));

    Color bg = Colors.green;
    if (!isSuccess) {
      final int? status = httpStatus ?? _codeToStatus(code);
      switch (status) {
        case 400:
          message = 'Bad Request: The request is invalid or unsupported.';
          bg = Colors.red;
          break;
        case 404:
          message = 'API endpoint not found. Please check the server configuration.';
          bg = Colors.red;
          break;
        case 500:
          message = 'Internal server error. Please try again later.';
          bg = Colors.red;
          break;
        default:
          final label = status != null ? '$status' : (code ?? 'UNKNOWN');
          message = 'Server error: $label';
          bg = Colors.red;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bg, duration: const Duration(seconds: 4)),
    );
  }

  int? _codeToStatus(String? code) {
    if (code == null) return null;
    switch (code) {
      case 'HTTP_200':
        return 200;
      case 'HTTP_400':
        return 400;
      case 'HTTP_404':
        return 404;
      case 'HTTP_500':
        return 500;
      default:
        return null;
    }
  }

  Future<void> _loadStoreProducts({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await AuthService.loadRetailerStoreProducts(includeAllProducts: true);
      if (result['status'] == 'success') {
        setState(() {
          final data = result['data'] as Map<String, dynamic>? ?? {};
          _storeProducts = (data['products'] as List<dynamic>? ) ?? [];
          if (showLoading) _isLoading = false;
        });
      } else {
        // Show UI but warn via SnackBar (admin parity)
        setState(() {
          _storeProducts = [];
          if (showLoading) _isLoading = false;
          _error = null;
        });
        if (showLoading) {
          _showHttpResultSnack(result, fallbackError: 'Failed to load store products');
        }
      }
    } catch (e) {
      setState(() {
        _storeProducts = [];
        if (showLoading) _isLoading = false;
        _error = null;
      });
      if (showLoading) {
        _showHttpResultSnack({'status': 'error', 'message': 'Connection error: $e'});
      }
    }
  }

  Future<void> _loadAllProducts() async {
    try {
      print('🔄 Loading all products for adding to store...');
      // Reuse the same listing response: all_products returned when include_all_products=true
      final result = await AuthService.loadRetailerStoreProducts(includeAllProducts: true);
      print('📊 Load All Products Result: ${result['status']}');
      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final allProducts = (data['all_products'] as List<dynamic>? ) ?? [];
        print('✅ Loaded ${allProducts.length} products available for adding');
        setState(() {
          _allProducts = allProducts;
        });
      } else {
        print('❌ Failed to load all products: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error loading all products: $e');
    }
  }

  Future<void> _loadFeedbackReports() async {
    setState(() {
      _isLoadingFeedback = true;
    });

    try {
      // This would need to be implemented in AuthService
      // For now, we'll use mock data
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _feedbackReports = []; // Mock empty feedback reports
        _isLoadingFeedback = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFeedback = false;
      });
    }
  }

  Future<void> _addProductToStore() async {
    print('🔄 Attempting to add product to store...');
    print('📦 Selected Product ID: $_selectedProductId');
    
    if (_selectedProductId.isEmpty) {
      print('❌ No product selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAddingProduct = true;
    });

    try {
      print('🔄 Calling AuthService.addRetailerStoreProduct...');
      print('📦 Product ID: ${int.parse(_selectedProductId)}');
      print('💰 Price: 0.0');
      
      final result = await AuthService.addRetailerStoreProduct(
        productId: int.parse(_selectedProductId),
        price: 0.0, // Default price, can be updated later
      );

      print('📊 Add Product Result: ${result['status']}');
      print('📊 Add Product Message: ${result['message']}');
      print('📊 Add Product Full Response: $result');

      if (result['status'] == 'success') {
        print('✅ Product added successfully!');
        _showHttpResultSnack({'status': 'success', 'message': 'Product added to store successfully', 'http_status': 200, 'code': 'HTTP_200'});
        Navigator.pop(context);
        // Refresh data immediately after successful add
        await _refreshData();
      } else {
        print('❌ Failed to add product: ${result['message']}');
        _showHttpResultSnack(result, fallbackError: 'Failed to add product');
      }
    } catch (e) {
      print('❌ Exception while adding product: $e');
      _showHttpResultSnack({'status': 'error', 'message': 'Error adding product: $e'});
    } finally {
      if (mounted) {
        setState(() {
          _isAddingProduct = false;
        });
      }
    }
  }

  Future<void> _removeProductFromStore(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Product'),
        content: const Text('Are you sure you want to remove this product from your store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await AuthService.removeRetailerStoreProduct(productId: productId);
        
        if (result['status'] == 'success') {
          _showHttpResultSnack({'status': 'success', 'message': 'Product removed from store successfully', 'http_status': 200, 'code': 'HTTP_200'});
          // Refresh data immediately after successful remove
          await _refreshData();
        } else {
          _showHttpResultSnack(result, fallbackError: 'Failed to remove product');
        }
      } catch (e) {
        _showHttpResultSnack({'status': 'error', 'message': 'Error removing product: $e'});
      }
    }
  }

  Color _getViolationColor(String violationLevel) {
    switch (violationLevel) {
      case 'critical_violation':
        return dangerRed;
      case 'minor_violation':
        return warningOrange;
      case 'below_srp':
        return successGreen;
      default:
        return gray;
    }
  }

  Color _getViolationBackgroundColor(String violationLevel) {
    switch (violationLevel) {
      case 'critical_violation':
        return Colors.red.shade50;
      case 'minor_violation':
        return Colors.orange.shade50;
      case 'below_srp':
        return Colors.green.shade50;
      default:
        return bgLight;
    }
  }

  String _getViolationText(String violationLevel) {
    switch (violationLevel) {
      case 'critical_violation':
        return 'Critical Violation';
      case 'minor_violation':
        return 'Minor Violation';
      case 'below_srp':
        return 'Below SRP';
      default:
        return 'Compliant';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        // Navigate back to dashboard instead of login page
        Navigator.pushReplacementNamed(context, '/retailer-dashboard');
      },
      child: Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          title: Text(
            'Store Product List',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/retailer-dashboard');
            },
          ),
          actions: [
            IconButton(
              icon: _isRefreshing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshData,
              tooltip: 'Refresh',
            ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductModal(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Products',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textLight),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStoreProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStoreProducts();
        await _loadFeedbackReports();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Products Section
            _buildStoreProductsSection(),
            const SizedBox(height: 24),
            
            // Feedback Reports Section
            _buildFeedbackReportsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreProductsSection() {
    return Container(
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: borderLight)),
            ),
            child: Row(
              children: [
                Icon(Icons.store, color: primaryBlue),
                const SizedBox(width: 12),
                Text(
                  'Your Store Products',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_storeProducts.length} products',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: textLight,
                  ),
                ),
              ],
            ),
          ),
          
          // Products List
          if (_storeProducts.isEmpty)
            _buildEmptyState()
          else
            _buildProductsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No products added yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add SRP products to your store to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddProductModal(),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _storeProducts.length,
      separatorBuilder: (context, index) => Divider(color: borderLight, height: 1),
      itemBuilder: (context, index) {
        final product = _storeProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final violationLevel = product['violation_level'] ?? 'compliant';
    final violationColor = _getViolationColor(violationLevel);
    final violationBgColor = _getViolationBackgroundColor(violationLevel);
    final violationText = _getViolationText(violationLevel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: violationBgColor,
        border: Border(left: BorderSide(color: violationColor, width: 4)),
      ),
      child: Row(
        children: [
          // Product Image and Violation Indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product['profile_pic'] != null && product['profile_pic'].toString().isNotEmpty
                  ? Image.network(
                      'https://dtisrpmonitoring.bccbsis.com/uploads/profile_pics/${product['profile_pic']}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: bgLight,
                          child: Icon(
                            Icons.inventory_2,
                            color: textLight,
                            size: 24,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: bgLight,
                      child: Icon(
                        Icons.inventory_2,
                        color: textLight,
                        size: 24,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  product['product_name'] ?? 'Unknown Product',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Category and Brand
                Row(
                  children: [
                    if (product['category_name'] != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product['category_name'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (product['brand'] != null)
                      Text(
                        product['brand'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textLight,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Price Information
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SRP: ₱${_formatPrice(product['srp'] ?? 0)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textLight,
                            ),
                          ),
                          Text(
                            'Your Price: ₱${_formatPrice(product['monitored_price'] ?? 0)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: violationColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Violation Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: violationColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        violationText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Price Deviation
                if (product['price_deviation_percentage'] != null && 
                    product['price_deviation_percentage'] != 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${product['price_deviation_percentage'] > 0 ? '+' : ''}${_formatPercentage(product['price_deviation_percentage'])}% ${product['price_deviation_percentage'] > 0 ? 'above' : 'below'} SRP',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: violationColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Remove Button
          IconButton(
            onPressed: () => _removeProductFromStore(product['product_id'] ?? product['retail_price_id'] ?? 0),
            icon: const Icon(Icons.delete_outline),
            color: dangerRed,
            tooltip: 'Remove Product',
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackReportsSection() {
    return Container(
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: borderLight)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: warningOrange),
                const SizedBox(width: 12),
                Text(
                  'Admin Feedback Reports',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const Spacer(),
                if (_feedbackReports.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: warningOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_feedbackReports.length} Active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Feedback Content
          if (_isLoadingFeedback)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_feedbackReports.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: successGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active SRP Violations',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: successGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your product prices are currently compliant with SRP guidelines. Keep up the good work!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            _buildFeedbackReportsList(),
        ],
      ),
    );
  }

  Widget _buildFeedbackReportsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _feedbackReports.length,
      separatorBuilder: (context, index) => Divider(color: borderLight, height: 1),
      itemBuilder: (context, index) {
        final report = _feedbackReports[index];
        return _buildFeedbackReportCard(report);
      },
    );
  }

  Widget _buildFeedbackReportCard(Map<String, dynamic> report) {
    // This would be implemented when feedback reports API is available
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Feedback report implementation pending',
        style: GoogleFonts.inter(color: textLight),
      ),
    );
  }

  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddProductModal(),
    );
  }

  Widget _buildAddProductModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add SRP Product to Store',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: textLight,
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Product',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_allProducts.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('No products available'),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _allProducts.length,
                        itemBuilder: (context, index) {
                          final product = _allProducts[index];
                          final isSelected = _selectedProductId == product['product_id'].toString();
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? primaryBlue : borderLight,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: isSelected ? lightBlue : bgWhite,
                            ),
                            child: ListTile(
                              title: Text(
                                product['product_name'] ?? 'Unknown Product',
                                style: GoogleFonts.inter(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              subtitle: product['brand'] != null
                                  ? Text(
                                      product['brand'],
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: textLight,
                                      ),
                                    )
                                  : null,
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: primaryBlue)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedProductId = product['product_id'].toString();
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Footer actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgLight,
              border: Border(top: BorderSide(color: borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textLight,
                      side: BorderSide(color: borderLight),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAddingProduct ? null : _addProductToStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isAddingProduct
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Add Product'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    final numPrice = price is num ? price : double.tryParse(price.toString()) ?? 0;
    return numPrice.toStringAsFixed(2);
  }

  String _formatPercentage(dynamic percentage) {
    if (percentage == null) return '0.0';
    final numPercentage = percentage is num ? percentage : double.tryParse(percentage.toString()) ?? 0;
    return numPercentage.toStringAsFixed(1);
  }
}
