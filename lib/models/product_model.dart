import 'package:flutter/material.dart';

class Product {
  final int productId;
  final String productName;
  final String? brand;
  final String? manufacturer;
  final double srp;
  final double? monitoredPrice;
  final double? prevailingPrice;
  final String? unit;
  final String? profilePic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? categoryName;
  final int? categoryId;
  final String? folderName;
  final String? folderPath;
  final int? folderId;
  final int? mainFolderId;
  final int? subFolderId;

  Product({
    required this.productId,
    required this.productName,
    this.brand,
    this.manufacturer,
    required this.srp,
    this.monitoredPrice,
    this.prevailingPrice,
    this.unit,
    this.profilePic,
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.categoryId,
    this.folderName,
    this.folderPath,
    this.folderId,
    this.mainFolderId,
    this.subFolderId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      brand: json['brand'],
      manufacturer: json['manufacturer'],
      srp: (json['srp'] ?? 0).toDouble(),
      monitoredPrice: json['monitored_price'] != null ? (json['monitored_price'] as num).toDouble() : null,
      prevailingPrice: json['prevailing_price'] != null ? (json['prevailing_price'] as num).toDouble() : null,
      unit: json['unit'],
      profilePic: json['profile_pic'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      categoryName: json['category_name'],
      categoryId: json['category_id'],
      folderName: json['folder_name'],
      folderPath: json['folder_path'],
      folderId: json['folder_id'],
      mainFolderId: json['main_folder_id'],
      subFolderId: json['sub_folder_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'brand': brand,
      'manufacturer': manufacturer,
      'srp': srp,
      'monitored_price': monitoredPrice,
      'prevailing_price': prevailingPrice,
      'unit': unit,
      'profile_pic': profilePic,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'category_name': categoryName,
      'category_id': categoryId,
      'folder_name': folderName,
      'folder_path': folderPath,
      'folder_id': folderId,
      'main_folder_id': mainFolderId,
      'sub_folder_id': subFolderId,
    };
  }

  // Price analysis methods
  double get priceDeviation {
    if (monitoredPrice == null) return 0.0;
    return monitoredPrice! - srp;
  }

  double get priceDeviationPercentage {
    if (srp == 0 || monitoredPrice == null) return 0.0;
    return (priceDeviation / srp) * 100;
  }

  bool get isOverpriced => priceDeviation > 0;
  bool get isUnderpriced => priceDeviation < 0;
  bool get isCompliant => priceDeviation <= 0;

  Color get priceStatusColor {
    if (isCompliant) return Colors.green;
    if (priceDeviationPercentage <= 10) return Colors.orange;
    return Colors.red;
  }

  String get priceStatusText {
    if (isCompliant) return 'Compliant';
    if (priceDeviationPercentage <= 10) return 'Minor Overprice';
    return 'Major Overprice';
  }

  Product copyWith({
    int? productId,
    String? productName,
    String? brand,
    String? manufacturer,
    double? srp,
    double? monitoredPrice,
    double? prevailingPrice,
    String? unit,
    String? profilePic,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    int? categoryId,
    String? folderName,
    String? folderPath,
    int? folderId,
    int? mainFolderId,
    int? subFolderId,
  }) {
    return Product(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      manufacturer: manufacturer ?? this.manufacturer,
      srp: srp ?? this.srp,
      monitoredPrice: monitoredPrice ?? this.monitoredPrice,
      prevailingPrice: prevailingPrice ?? this.prevailingPrice,
      unit: unit ?? this.unit,
      profilePic: profilePic ?? this.profilePic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      folderName: folderName ?? this.folderName,
      folderPath: folderPath ?? this.folderPath,
      folderId: folderId ?? this.folderId,
      mainFolderId: mainFolderId ?? this.mainFolderId,
      subFolderId: subFolderId ?? this.subFolderId,
    );
  }
}

class Category {
  final int id;
  final String name;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productCount: json['product_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_count': productCount,
    };
  }
}

class Folder {
  final int id;
  final String name;
  final String? description;
  final String? color;
  final int? parentId;
  final int? level;
  final String? path;
  final int productCount;
  final int childCount;
  final List<Folder> children;

  Folder({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.parentId,
    this.level,
    this.path,
    this.productCount = 0,
    this.childCount = 0,
    this.children = const [],
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'],
      parentId: json['parent_id'],
      level: json['level'],
      path: json['path'],
      productCount: json['product_count'] ?? 0,
      childCount: json['child_count'] ?? 0,
      children: json['children'] != null
          ? (json['children'] as List).map((e) => Folder.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'parent_id': parentId,
      'level': level,
      'path': path,
      'product_count': productCount,
      'child_count': childCount,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}

class SRPHistory {
  final int srpId;
  final int productId;
  final double srpPrice;
  final DateTime dateEffective;
  final DateTime dateUpdated;

  SRPHistory({
    required this.srpId,
    required this.productId,
    required this.srpPrice,
    required this.dateEffective,
    required this.dateUpdated,
  });

  factory SRPHistory.fromJson(Map<String, dynamic> json) {
    return SRPHistory(
      srpId: json['srp_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      srpPrice: (json['srp_price'] ?? 0).toDouble(),
      dateEffective: DateTime.tryParse(json['date_effective'] ?? '') ?? DateTime.now(),
      dateUpdated: DateTime.tryParse(json['date_updated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'srp_id': srpId,
      'product_id': productId,
      'srp_price': srpPrice,
      'date_effective': dateEffective.toIso8601String().split('T')[0],
      'date_updated': dateUpdated.toIso8601String(),
    };
  }
}

class PriceAnalytics {
  final int totalProducts;
  final int compliantProducts;
  final int overpricedProducts;
  final int underpricedProducts;
  final double averageSRP;
  final double averageMonitoredPrice;
  final double averageDeviation;
  final double complianceRate;
  final double violationRate;
  final List<Map<String, dynamic>> topOverpriced;
  final List<Map<String, dynamic>> categoryBreakdown;

  PriceAnalytics({
    required this.totalProducts,
    required this.compliantProducts,
    required this.overpricedProducts,
    required this.underpricedProducts,
    required this.averageSRP,
    required this.averageMonitoredPrice,
    required this.averageDeviation,
    required this.complianceRate,
    required this.violationRate,
    required this.topOverpriced,
    required this.categoryBreakdown,
  });

  factory PriceAnalytics.fromJson(Map<String, dynamic> json) {
    final analytics = json['analytics'] ?? {};
    return PriceAnalytics(
      totalProducts: analytics['total_products'] ?? 0,
      compliantProducts: analytics['compliant_products'] ?? 0,
      overpricedProducts: analytics['overpriced_products'] ?? 0,
      underpricedProducts: analytics['underpriced_products'] ?? 0,
      averageSRP: (analytics['average_srp'] ?? 0).toDouble(),
      averageMonitoredPrice: (analytics['average_monitored_price'] ?? 0).toDouble(),
      averageDeviation: (analytics['average_deviation'] ?? 0).toDouble(),
      complianceRate: (analytics['compliance_rate'] ?? 0).toDouble(),
      violationRate: (analytics['violation_rate'] ?? 0).toDouble(),
      topOverpriced: List<Map<String, dynamic>>.from(analytics['top_overpriced'] ?? []),
      categoryBreakdown: List<Map<String, dynamic>>.from(analytics['category_breakdown'] ?? []),
    );
  }
}

// Product filters
class ProductFilters {
  String? search;
  int? categoryId;
  double? priceMin;
  double? priceMax;
  int? folderId;
  int? mainFolderId;
  int? subFolderId;
  String sortBy;
  String sortOrder;

  ProductFilters({
    this.search,
    this.categoryId,
    this.priceMin,
    this.priceMax,
    this.folderId,
    this.mainFolderId,
    this.subFolderId,
    this.sortBy = 'product_name',
    this.sortOrder = 'ASC',
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    if (categoryId != null) params['category'] = categoryId.toString();
    if (priceMin != null) params['price_min'] = priceMin.toString();
    if (priceMax != null) params['price_max'] = priceMax.toString();
    if (folderId != null) params['folder'] = folderId.toString();
    if (mainFolderId != null) params['main_folder'] = mainFolderId.toString();
    if (subFolderId != null) params['sub_folder'] = subFolderId.toString();
    params['sort'] = sortBy;
    params['order'] = sortOrder;
    
    return params;
  }

  void clear() {
    search = null;
    categoryId = null;
    priceMin = null;
    priceMax = null;
    folderId = null;
    mainFolderId = null;
    subFolderId = null;
    sortBy = 'product_name';
    sortOrder = 'ASC';
  }

  bool get hasActiveFilters {
    return search != null && search!.isNotEmpty ||
           categoryId != null ||
           priceMin != null ||
           priceMax != null ||
           folderId != null ||
           mainFolderId != null ||
           subFolderId != null;
  }
}
