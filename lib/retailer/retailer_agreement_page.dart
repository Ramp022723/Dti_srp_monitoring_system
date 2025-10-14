import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'dart:async';

class RetailerAgreementPage extends StatefulWidget {
  const RetailerAgreementPage({Key? key}) : super(key: key);

  @override
  State<RetailerAgreementPage> createState() => _RetailerAgreementPageState();
}

class _RetailerAgreementPageState extends State<RetailerAgreementPage> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<dynamic> _agreements = [];
  String? _error;
  Map<int, String> _acceptanceStatus = {};
  
  // Real-time update variables
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  // Color scheme matching the PHP version
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryBlue = Color(0xFF1D4ED8);
  static const Color lightBlue = Color(0xFFDBEAFE);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningOrange = Color(0xFFFD7E14);
  static const Color dangerRed = Color(0xFFDC3545);
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
    _loadAgreements();
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
      await _loadAgreements(showLoading: false);
    } catch (e) {
      print('Error refreshing agreements: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadAgreements({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await AuthService.loadRetailerAgreements();
      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _agreements = (data['agreements'] as List<dynamic>? ) ?? [];
          if (showLoading) _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load agreements';
          if (showLoading) _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        if (showLoading) _isLoading = false;
      });
    }
  }

  Future<void> _updateAgreementStatus(int agreementId, String status) async {
    try {
      final result = await AuthService.updateRetailerAgreementStatus(
        agreementId: agreementId,
        acceptanceStatus: status,
      );
      
      if (result['status'] == 'success') {
        setState(() {
          _acceptanceStatus[agreementId] = status;
        });
        
        // Refresh data immediately after successful update
        await _refreshData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Agreement status updated to: $status'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update agreement status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating agreement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(String status, String endDate) {
    final currentDate = DateTime.now();
    final endDateTime = DateTime.tryParse(endDate) ?? currentDate;
    
    if (status == 'active' && endDateTime.isAfter(currentDate)) {
      return 'Active';
    } else if (endDateTime.isBefore(currentDate)) {
      return 'Expired';
    } else {
      return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status, String endDate) {
    final currentDate = DateTime.now();
    final endDateTime = DateTime.tryParse(endDate) ?? currentDate;
    
    if (status == 'active' && endDateTime.isAfter(currentDate)) {
      return successGreen;
    } else if (endDateTime.isBefore(currentDate)) {
      return dangerRed;
    } else {
      return gray;
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
            'Retailer Agreements',
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
          : _error != null
              ? _buildErrorWidget()
              : _agreements.isEmpty
                  ? _buildEmptyState()
                  : _buildAgreementsList(),
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
              'Error Loading Agreements',
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
              onPressed: _loadAgreements,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Agreements Found',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You don\'t have any agreements yet. Contact the administrator to create an agreement for your business.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: textLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home),
              label: const Text('Go to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementsList() {
    return RefreshIndicator(
      onRefresh: _loadAgreements,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Retailer Agreements',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View and manage your business agreements with DTI',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Agreements Grid
            Text(
              'My Agreements',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _agreements.length,
              itemBuilder: (context, index) {
                final agreement = _agreements[index];
                return _buildAgreementCard(agreement);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementCard(Map<String, dynamic> agreement) {
    final agreementId = agreement['agreement_id'] as int;
    final status = agreement['status'] as String? ?? '';
    final endDate = agreement['end_date'] as String? ?? '';
    final statusText = _getStatusText(status, endDate);
    final statusColor = _getStatusColor(status, endDate);
    
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAgreementModal(agreement),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                color: primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Agreement #$agreementId',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                color: textLight,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  agreement['store_name'] ?? 'Unknown Store',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: textLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Date range
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(agreement['start_date']),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(agreement['end_date']),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Agreement preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getAgreementPreview(agreement['agreement_text'] ?? ''),
                    style: GoogleFonts.courierPrime(
                      fontSize: 12,
                      color: textDark,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Footer with actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Created: ${_formatDate(agreement['created_at'])}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textLight,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _showAgreementModal(agreement),
                          icon: const Icon(Icons.visibility, size: 20),
                          color: primaryBlue,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _downloadAgreement(agreementId),
                          icon: const Icon(Icons.download, size: 20),
                          color: successGreen,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAgreementModal(Map<String, dynamic> agreement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAgreementModal(agreement),
    );
  }

  Widget _buildAgreementModal(Map<String, dynamic> agreement) {
    final agreementId = agreement['agreement_id'] as int;
    final status = agreement['status'] as String? ?? '';
    final endDate = agreement['end_date'] as String? ?? '';
    final statusText = _getStatusText(status, endDate);
    final statusColor = _getStatusColor(status, endDate);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.description, color: primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Agreement #$agreementId',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store and Status
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Store Name',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              agreement['store_name'] ?? 'Unknown Store',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Status',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Date range
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(agreement['start_date']),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(agreement['end_date']),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Agreement text
                  Text(
                    'Agreement Terms',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      agreement['agreement_text'] ?? 'No agreement text available',
                      style: GoogleFonts.courierPrime(
                        fontSize: 14,
                        color: textDark,
                        height: 1.6,
                      ),
                    ),
                  ),
                  
                  // Agreement photo if available
                  if (agreement['agreement_photo'] != null && agreement['agreement_photo'].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Agreement Photo',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderLight),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '${AuthService.baseUrl}/uploads/${agreement['agreement_photo']}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: bgLight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: textLight,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Photo not available',
                                    style: GoogleFonts.inter(
                                      color: textLight,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Acceptance form
                  Text(
                    'Agreement Response',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('I Agree'),
                          value: 'agreed',
                          groupValue: _acceptanceStatus[agreementId],
                          onChanged: (value) {
                            if (value != null) {
                              _updateAgreementStatus(agreementId, value);
                            }
                          },
                          activeColor: successGreen,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('I Disagree'),
                          value: 'disagreed',
                          groupValue: _acceptanceStatus[agreementId],
                          onChanged: (value) {
                            if (value != null) {
                              _updateAgreementStatus(agreementId, value);
                            }
                          },
                          activeColor: dangerRed,
                        ),
                      ),
                    ],
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
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadAgreement(agreementId),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: BorderSide(color: primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _downloadAgreement(int agreementId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading agreement #$agreementId...'),
        backgroundColor: primaryBlue,
      ),
    );
    // TODO: Implement actual download functionality
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _getAgreementPreview(String agreementText) {
    if (agreementText.isEmpty) return 'No agreement text available';
    
    final preview = agreementText.length > 200 
        ? '${agreementText.substring(0, 200)}...'
        : agreementText;
    
    return preview;
  }
}
