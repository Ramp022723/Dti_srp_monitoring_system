import 'package:flutter/material.dart';

class Retailer {
  final int retailerId;
  final String username;
  final String storeName;
  final int? locationId;
  final String? locationName;
  final String? address;
  final String? contactNumber;
  final String? email;
  final DateTime? registeredDate;
  final int productCount;
  final double complianceRate;
  final int violationCount;

  Retailer({
    required this.retailerId,
    required this.username,
    required this.storeName,
    this.locationId,
    this.locationName,
    this.address,
    this.contactNumber,
    this.email,
    this.registeredDate,
    this.productCount = 0,
    this.complianceRate = 0.0,
    this.violationCount = 0,
  });

  factory Retailer.fromJson(Map<String, dynamic> json) {
    return Retailer(
      retailerId: json['retailer_id'] ?? json['retailer_register_id'] ?? 0,
      username: json['username'] ?? json['retailer_username'] ?? '',
      storeName: json['store_name'] ?? '',
      locationId: json['location_id'],
      locationName: json['location_name'],
      address: json['address'],
      contactNumber: json['contact_number'],
      email: json['email'],
      registeredDate: json['registered_date'] != null
          ? DateTime.tryParse(json['registered_date'])
          : null,
      productCount: json['product_count'] ?? 0,
      complianceRate: (json['compliance_rate'] ?? 0.0).toDouble(),
      violationCount: json['violation_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'retailer_id': retailerId,
      'username': username,
      'store_name': storeName,
      'location_id': locationId,
      'location_name': locationName,
      'address': address,
      'contact_number': contactNumber,
      'email': email,
      'registered_date': registeredDate?.toIso8601String(),
      'product_count': productCount,
      'compliance_rate': complianceRate,
      'violation_count': violationCount,
    };
  }

  Color get complianceColor {
    if (complianceRate >= 90) return Colors.green;
    if (complianceRate >= 75) return Colors.orange;
    return Colors.red;
  }

  String get complianceStatus {
    if (complianceRate >= 90) return 'Excellent';
    if (complianceRate >= 75) return 'Good';
    if (complianceRate >= 60) return 'Fair';
    return 'Poor';
  }
}

class RetailerProduct {
  final int retailPriceId;
  final int productId;
  final int retailerId;
  final String productName;
  final String? brand;
  final String? manufacturer;
  final double srp;
  final double? monitoredPrice;
  final double? prevailingPrice;
  final double currentRetailPrice;
  final String? unit;
  final String? profilePic;
  final String? categoryName;
  final int? categoryId;
  final String retailerUsername;
  final String storeName;
  final int? locationId;
  final DateTime dateRecorded;
  final String? mainFolderName;
  final String? subFolderName;
  final int? mainFolderId;
  final int? subFolderId;
  final double mrp;
  final double effectiveMrp;
  final String mrpStatus;
  final String violationLevel;

  RetailerProduct({
    required this.retailPriceId,
    required this.productId,
    required this.retailerId,
    required this.productName,
    this.brand,
    this.manufacturer,
    required this.srp,
    this.monitoredPrice,
    this.prevailingPrice,
    required this.currentRetailPrice,
    this.unit,
    this.profilePic,
    this.categoryName,
    this.categoryId,
    required this.retailerUsername,
    required this.storeName,
    this.locationId,
    required this.dateRecorded,
    this.mainFolderName,
    this.subFolderName,
    this.mainFolderId,
    this.subFolderId,
    required this.mrp,
    required this.effectiveMrp,
    required this.mrpStatus,
    required this.violationLevel,
  });

  factory RetailerProduct.fromJson(Map<String, dynamic> json) {
    return RetailerProduct(
      retailPriceId: json['retail_price_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      retailerId: json['retailer_register_id'] ?? 0,
      productName: json['product_name'] ?? '',
      brand: json['brand'],
      manufacturer: json['manufacturer'],
      srp: (json['srp'] ?? 0).toDouble(),
      monitoredPrice: json['monitored_price'] != null
          ? (json['monitored_price'] as num).toDouble()
          : null,
      prevailingPrice: json['prevailing_price'] != null
          ? (json['prevailing_price'] as num).toDouble()
          : null,
      currentRetailPrice: (json['current_retail_price'] ?? 0).toDouble(),
      unit: json['unit'],
      profilePic: json['profile_pic'],
      categoryName: json['category_name'],
      categoryId: json['category_id'],
      retailerUsername: json['retailer_username'] ?? '',
      storeName: json['store_name'] ?? '',
      locationId: json['location_id'],
      dateRecorded: DateTime.tryParse(json['date_recorded'] ?? '') ?? DateTime.now(),
      mainFolderName: json['main_folder_name'],
      subFolderName: json['sub_folder_name'],
      mainFolderId: json['main_folder_id'],
      subFolderId: json['sub_folder_id'],
      mrp: (json['mrp'] ?? 0).toDouble(),
      effectiveMrp: (json['effective_mrp'] ?? 0).toDouble(),
      mrpStatus: json['mrp_status'] ?? 'within_mrp',
      violationLevel: json['violation_level'] ?? 'compliant',
    );
  }

  // Price analysis
  double get priceDeviation => currentRetailPrice - effectiveMrp;
  
  double get priceDeviationPercentage {
    if (effectiveMrp == 0) return 0.0;
    return (priceDeviation / effectiveMrp) * 100;
  }

  bool get isAboveMrp => mrpStatus == 'above_mrp';
  bool get isBelowMrp => mrpStatus == 'below_mrp';
  bool get isWithinMrp => mrpStatus == 'within_mrp';
  
  bool get isCompliant => violationLevel == 'compliant';
  bool get isMinorViolation => violationLevel == 'minor_violation';
  bool get isCriticalViolation => violationLevel == 'critical_violation';

  Color get violationColor {
    switch (violationLevel) {
      case 'critical_violation':
        return Colors.red;
      case 'minor_violation':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String get violationText {
    switch (violationLevel) {
      case 'critical_violation':
        return 'Critical Violation';
      case 'minor_violation':
        return 'Minor Violation';
      default:
        return 'Compliant';
    }
  }

  IconData get violationIcon {
    switch (violationLevel) {
      case 'critical_violation':
        return Icons.error;
      case 'minor_violation':
        return Icons.warning;
      default:
        return Icons.check_circle;
    }
  }
}

class ViolationAlert {
  final int alertId;
  final int retailPriceId;
  final int productId;
  final int retailerId;
  final String violationType;
  final double currentPrice;
  final double mrpThreshold;
  final double deviationPercentage;
  final String severity;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? productName;
  final String? retailerName;
  final String? storeName;

  ViolationAlert({
    required this.alertId,
    required this.retailPriceId,
    required this.productId,
    required this.retailerId,
    required this.violationType,
    required this.currentPrice,
    required this.mrpThreshold,
    required this.deviationPercentage,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.productName,
    this.retailerName,
    this.storeName,
  });

  factory ViolationAlert.fromJson(Map<String, dynamic> json) {
    return ViolationAlert(
      alertId: json['alert_id'] ?? 0,
      retailPriceId: json['retail_price_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      retailerId: json['retailer_register_id'] ?? 0,
      violationType: json['violation_type'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      mrpThreshold: (json['mrp_threshold'] ?? 0).toDouble(),
      deviationPercentage: (json['deviation_percentage'] ?? 0).toDouble(),
      severity: json['severity'] ?? 'low',
      status: json['status'] ?? 'open',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at']) : null,
      productName: json['product_name'],
      retailerName: json['retailer_name'],
      storeName: json['store_name'],
    );
  }

  Color get severityColor {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.yellow;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'investigating':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  bool get isOpen => status == 'open';
  bool get isResolved => status == 'resolved';
  bool get isInvestigating => status == 'investigating';
}

class RetailerStats {
  final int totalRetailers;
  final int totalProducts;
  final int compliantProducts;
  final int violatingProducts;
  final double overallComplianceRate;
  final double averageDeviation;
  final int criticalViolations;
  final int minorViolations;
  final List<Map<String, dynamic>> topViolators;
  final List<Map<String, dynamic>> topCompliant;

  RetailerStats({
    required this.totalRetailers,
    required this.totalProducts,
    required this.compliantProducts,
    required this.violatingProducts,
    required this.overallComplianceRate,
    required this.averageDeviation,
    required this.criticalViolations,
    required this.minorViolations,
    required this.topViolators,
    required this.topCompliant,
  });

  factory RetailerStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    return RetailerStats(
      totalRetailers: stats['total_retailers'] ?? 0,
      totalProducts: stats['total_products'] ?? 0,
      compliantProducts: stats['compliant_products'] ?? 0,
      violatingProducts: stats['violating_products'] ?? 0,
      overallComplianceRate: (stats['overall_compliance_rate'] ?? 0.0).toDouble(),
      averageDeviation: (stats['average_deviation'] ?? 0.0).toDouble(),
      criticalViolations: stats['critical_violations'] ?? 0,
      minorViolations: stats['minor_violations'] ?? 0,
      topViolators: List<Map<String, dynamic>>.from(stats['top_violators'] ?? []),
      topCompliant: List<Map<String, dynamic>>.from(stats['top_compliant'] ?? []),
    );
  }

  double get violationRate => totalProducts > 0 ? (violatingProducts / totalProducts) * 100 : 0;
}

// Filters
class RetailerFilters {
  String? retailerSearch;
  String? productSearch;
  String? anomalyFilter; // 'above_mrp', 'below_mrp', 'critical'
  int? retailerId;
  int? mainFolderId;
  int? subFolderId;
  String sortBy;
  String sortOrder;

  RetailerFilters({
    this.retailerSearch,
    this.productSearch,
    this.anomalyFilter,
    this.retailerId,
    this.mainFolderId,
    this.subFolderId,
    this.sortBy = 'retailer_username',
    this.sortOrder = 'ASC',
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    
    if (retailerSearch != null && retailerSearch!.isNotEmpty) {
      params['retailer_filter'] = retailerSearch!;
    }
    if (productSearch != null && productSearch!.isNotEmpty) {
      params['product_filter'] = productSearch!;
    }
    if (anomalyFilter != null && anomalyFilter!.isNotEmpty) {
      params['anomaly_filter'] = anomalyFilter!;
    }
    if (retailerId != null) params['retailer_id'] = retailerId.toString();
    if (mainFolderId != null) params['main_folder_id'] = mainFolderId.toString();
    if (subFolderId != null) params['sub_folder_id'] = subFolderId.toString();
    params['sort_by'] = sortBy;
    params['sort_order'] = sortOrder;
    
    return params;
  }

  void clear() {
    retailerSearch = null;
    productSearch = null;
    anomalyFilter = null;
    retailerId = null;
    mainFolderId = null;
    subFolderId = null;
    sortBy = 'retailer_username';
    sortOrder = 'ASC';
  }

  bool get hasActiveFilters {
    return retailerSearch != null && retailerSearch!.isNotEmpty ||
           productSearch != null && productSearch!.isNotEmpty ||
           anomalyFilter != null && anomalyFilter!.isNotEmpty ||
           retailerId != null ||
           mainFolderId != null ||
           subFolderId != null;
  }
}
