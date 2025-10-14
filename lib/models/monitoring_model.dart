import 'package:flutter/material.dart';

class MonitoringForm {
  final int? id;
  final String storeName;
  final String storeAddress;
  final DateTime monitoringDate;
  final String monitoringMode;
  final String storeRep;
  final String dtiMonitor;
  final DateTime? createdAt;
  final List<MonitoringProduct> products;

  MonitoringForm({
    this.id,
    required this.storeName,
    required this.storeAddress,
    required this.monitoringDate,
    required this.monitoringMode,
    required this.storeRep,
    required this.dtiMonitor,
    this.createdAt,
    this.products = const [],
  });

  factory MonitoringForm.fromJson(Map<String, dynamic> json) {
    return MonitoringForm(
      id: json['id'],
      storeName: json['store_name'] ?? '',
      storeAddress: json['store_address'] ?? '',
      monitoringDate: DateTime.tryParse(json['monitoring_date'] ?? '') ?? DateTime.now(),
      monitoringMode: json['monitoring_mode'] ?? '',
      storeRep: json['store_rep'] ?? '',
      dtiMonitor: json['dti_monitor'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      products: json['products'] != null 
          ? (json['products'] as List).map((p) => MonitoringProduct.fromJson(p)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_name': storeName,
      'store_address': storeAddress,
      'monitoring_date': monitoringDate.toIso8601String().split('T')[0],
      'monitoring_mode': monitoringMode,
      'store_rep': storeRep,
      'dti_monitor': dtiMonitor,
      'created_at': createdAt?.toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
    };
  }

  MonitoringForm copyWith({
    int? id,
    String? storeName,
    String? storeAddress,
    DateTime? monitoringDate,
    String? monitoringMode,
    String? storeRep,
    String? dtiMonitor,
    DateTime? createdAt,
    List<MonitoringProduct>? products,
  }) {
    return MonitoringForm(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      monitoringDate: monitoringDate ?? this.monitoringDate,
      monitoringMode: monitoringMode ?? this.monitoringMode,
      storeRep: storeRep ?? this.storeRep,
      dtiMonitor: dtiMonitor ?? this.dtiMonitor,
      createdAt: createdAt ?? this.createdAt,
      products: products ?? this.products,
    );
  }
}

class MonitoringProduct {
  final int? id;
  final int? monitoringFormId;
  final String productName;
  final String unit;
  final double srp;
  final double monitoredPrice;
  final double prevailingPrice;
  final String remarks;

  MonitoringProduct({
    this.id,
    this.monitoringFormId,
    required this.productName,
    required this.unit,
    required this.srp,
    required this.monitoredPrice,
    required this.prevailingPrice,
    this.remarks = '',
  });

  factory MonitoringProduct.fromJson(Map<String, dynamic> json) {
    return MonitoringProduct(
      id: json['id'],
      monitoringFormId: json['monitoring_form_id'],
      productName: json['product_name'] ?? '',
      unit: json['unit'] ?? '',
      srp: (json['srp'] ?? 0.0).toDouble(),
      monitoredPrice: (json['monitored_price'] ?? 0.0).toDouble(),
      prevailingPrice: (json['prevailing_price'] ?? 0.0).toDouble(),
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monitoring_form_id': monitoringFormId,
      'product_name': productName,
      'unit': unit,
      'srp': srp,
      'monitored_price': monitoredPrice,
      'prevailing_price': prevailingPrice,
      'remarks': remarks,
    };
  }

  MonitoringProduct copyWith({
    int? id,
    int? monitoringFormId,
    String? productName,
    String? unit,
    double? srp,
    double? monitoredPrice,
    double? prevailingPrice,
    String? remarks,
  }) {
    return MonitoringProduct(
      id: id ?? this.id,
      monitoringFormId: monitoringFormId ?? this.monitoringFormId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      srp: srp ?? this.srp,
      monitoredPrice: monitoredPrice ?? this.monitoredPrice,
      prevailingPrice: prevailingPrice ?? this.prevailingPrice,
      remarks: remarks ?? this.remarks,
    );
  }

  // Calculate price deviation
  double get priceDeviation => monitoredPrice - srp;
  double get priceDeviationPercentage => srp > 0 ? (priceDeviation / srp) * 100 : 0;
  
  // Check if price is compliant
  bool get isCompliant => priceDeviation <= 0;
  bool get isOverpriced => priceDeviation > 0;
  bool get isUnderpriced => priceDeviation < 0;

  // Get price status color
  Color get priceStatusColor {
    if (isCompliant) return Colors.green;
    if (priceDeviationPercentage <= 10) return Colors.orange;
    return Colors.red;
  }
  
  // Alias for priceStatusColor
  Color get priceDeviationColor => priceStatusColor;

  String get priceStatusText {
    if (isCompliant) return 'Compliant';
    if (priceDeviationPercentage <= 10) return 'Minor Overprice';
    return 'Major Overprice';
  }
}

class MonitoringStats {
  final int totalForms;
  final int totalProducts;
  final int compliantProducts;
  final int overpricedProducts;
  final double averageDeviation;
  final List<Map<String, dynamic>> topViolations;
  final List<Map<String, dynamic>> storeStats;

  MonitoringStats({
    required this.totalForms,
    required this.totalProducts,
    required this.compliantProducts,
    required this.overpricedProducts,
    required this.averageDeviation,
    required this.topViolations,
    required this.storeStats,
  });

  factory MonitoringStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    return MonitoringStats(
      totalForms: stats['total_forms'] ?? 0,
      totalProducts: stats['total_products'] ?? 0,
      compliantProducts: stats['compliant_products'] ?? 0,
      overpricedProducts: stats['overpriced_products'] ?? 0,
      averageDeviation: (stats['average_deviation'] ?? 0.0).toDouble(),
      topViolations: List<Map<String, dynamic>>.from(stats['top_violations'] ?? []),
      storeStats: List<Map<String, dynamic>>.from(stats['store_stats'] ?? []),
    );
  }

  double get complianceRate => totalProducts > 0 ? (compliantProducts / totalProducts) * 100 : 0;
  double get violationRate => totalProducts > 0 ? (overpricedProducts / totalProducts) * 100 : 0;
}

class Store {
  final int id;
  final String name;
  final String address;
  final int monitoringCount;
  final double averageCompliance;
  final DateTime? lastMonitoring;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.monitoringCount,
    required this.averageCompliance,
    this.lastMonitoring,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      monitoringCount: json['monitoring_count'] ?? 0,
      averageCompliance: (json['average_compliance'] ?? 0.0).toDouble(),
      lastMonitoring: json['last_monitoring'] != null 
          ? DateTime.tryParse(json['last_monitoring']) 
          : null,
    );
  }
}

// Monitoring modes enum
enum MonitoringMode {
  actualInspection('Actual Inspection'),
  email('Email'),
  phoneInterview('Phone Interview'),
  onlineMonitoring('Online Monitoring');

  const MonitoringMode(this.displayName);
  final String displayName;

  static MonitoringMode fromString(String value) {
    return MonitoringMode.values.firstWhere(
      (mode) => mode.displayName == value,
      orElse: () => MonitoringMode.actualInspection,
    );
  }
}
