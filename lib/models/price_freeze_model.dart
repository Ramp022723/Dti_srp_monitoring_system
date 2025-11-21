import 'package:flutter/material.dart';

class PriceFreezeAlert {
  final int? alertId;
  final String title;
  final String message;
  final String affectedProducts; // 'all' or JSON array
  final String affectedCategories; // 'all' or JSON array
  final String affectedLocations; // 'all' or JSON array
  final DateTime freezeStartDate;
  final DateTime? freezeEndDate;
  final String status; // 'active', 'expired', 'cancelled'
  final int createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PriceFreezeAlert({
    this.alertId,
    required this.title,
    required this.message,
    required this.affectedProducts,
    required this.affectedCategories,
    required this.affectedLocations,
    required this.freezeStartDate,
    this.freezeEndDate,
    this.status = 'active',
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory PriceFreezeAlert.fromJson(Map<String, dynamic> json) {
    return PriceFreezeAlert(
      alertId: json['alert_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      affectedProducts: json['affected_products'] ?? 'all',
      affectedCategories: json['affected_categories'] ?? 'all',
      affectedLocations: json['affected_locations'] ?? 'all',
      freezeStartDate: DateTime.tryParse(json['freeze_start_date'] ?? '') ?? DateTime.now(),
      freezeEndDate: json['freeze_end_date'] != null
          ? DateTime.tryParse(json['freeze_end_date'])
          : null,
      status: json['status'] ?? 'active',
      createdBy: json['created_by'] ?? 0,
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_id': alertId,
      'title': title,
      'message': message,
      'affected_products': affectedProducts,
      'affected_categories': affectedCategories,
      'affected_locations': affectedLocations,
      'freeze_start_date': freezeStartDate.toIso8601String().split('T')[0],
      'freeze_end_date': freezeEndDate?.toIso8601String().split('T')[0],
      'status': status,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';

  bool get isCurrentlyActive {
    final now = DateTime.now();
    if (status != 'active') return false;
    if (now.isBefore(freezeStartDate)) return false;
    if (freezeEndDate != null && now.isAfter(freezeEndDate!)) return false;
    return true;
  }

  Color get statusColor {
    if (isCurrentlyActive) return Colors.green;
    if (isExpired) return Colors.grey;
    if (isCancelled) return Colors.red;
    return Colors.orange;
  }

  String get statusText {
    if (isCurrentlyActive) return 'Active';
    if (isExpired) return 'Expired';
    if (isCancelled) return 'Cancelled';
    if (DateTime.now().isBefore(freezeStartDate)) return 'Scheduled';
    return status;
  }

  int get daysUntilStart {
    return freezeStartDate.difference(DateTime.now()).inDays;
  }

  int? get daysUntilEnd {
    if (freezeEndDate == null) return null;
    return freezeEndDate!.difference(DateTime.now()).inDays;
  }

  String get durationText {
    if (freezeEndDate == null) return 'Indefinite';
    final days = freezeEndDate!.difference(freezeStartDate).inDays;
    if (days == 0) return 'Same day';
    if (days == 1) return '1 day';
    return '$days days';
  }
}

class PriceFreezeNotification {
  final int notificationId;
  final int alertId;
  final int userId;
  final String userType; // 'consumer' or 'retailer'
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final PriceFreezeAlert? alert;

  PriceFreezeNotification({
    required this.notificationId,
    required this.alertId,
    required this.userId,
    required this.userType,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.alert,
  });

  factory PriceFreezeNotification.fromJson(Map<String, dynamic> json) {
    return PriceFreezeNotification(
      notificationId: json['notification_id'] ?? 0,
      alertId: json['alert_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userType: json['user_type'] ?? 'consumer',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      alert: json['alert'] != null ? PriceFreezeAlert.fromJson(json['alert']) : null,
    );
  }
}

class Product {
  final int productId;
  final String productName;
  final String? brand;
  final int? categoryId;
  final String? categoryName;

  Product({
    required this.productId,
    required this.productName,
    this.brand,
    this.categoryId,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      brand: json['brand'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
    );
  }

  String get displayName {
    if (brand != null && brand!.isNotEmpty) {
      return '$productName ($brand)';
    }
    return productName;
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'brand': brand,
      'category_id': categoryId,
      'category_name': categoryName,
    };
  }
}

class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Location {
  final int locationId;
  final String barangayName;
  final String cityName;

  Location({
    required this.locationId,
    required this.barangayName,
    required this.cityName,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      locationId: json['location_id'] ?? 0,
      barangayName: json['barangay_name'] ?? '',
      cityName: json['city_name'] ?? '',
    );
  }

  String get fullName => '$barangayName, $cityName';

  Map<String, dynamic> toJson() {
    return {
      'location_id': locationId,
      'barangay_name': barangayName,
      'city_name': cityName,
    };
  }
}

class PriceFreezeStats {
  final int totalAlerts;
  final int activeAlerts;
  final int expiredAlerts;
  final int scheduledAlerts;
  final int totalNotificationsSent;
  final int totalUsersNotified;
  final int consumersNotified;
  final int retailersNotified;
  final List<Map<String, dynamic>> recentAlerts;
  final List<Map<String, dynamic>> upcomingAlerts;

  PriceFreezeStats({
    required this.totalAlerts,
    required this.activeAlerts,
    required this.expiredAlerts,
    required this.scheduledAlerts,
    required this.totalNotificationsSent,
    required this.totalUsersNotified,
    required this.consumersNotified,
    required this.retailersNotified,
    required this.recentAlerts,
    required this.upcomingAlerts,
  });

  factory PriceFreezeStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    return PriceFreezeStats(
      totalAlerts: stats['total_alerts'] ?? 0,
      activeAlerts: stats['active_alerts'] ?? 0,
      expiredAlerts: stats['expired_alerts'] ?? 0,
      scheduledAlerts: stats['scheduled_alerts'] ?? 0,
      totalNotificationsSent: stats['total_notifications_sent'] ?? 0,
      totalUsersNotified: stats['total_users_notified'] ?? 0,
      consumersNotified: stats['consumers_notified'] ?? 0,
      retailersNotified: stats['retailers_notified'] ?? 0,
      recentAlerts: List<Map<String, dynamic>>.from(stats['recent_alerts'] ?? []),
      upcomingAlerts: List<Map<String, dynamic>>.from(stats['upcoming_alerts'] ?? []),
    );
  }
}

// Alert creation request
class CreateAlertRequest {
  final String title;
  final String message;
  final String affectedProducts; // 'all' or comma-separated IDs
  final String affectedCategories; // 'all' or comma-separated IDs
  final String affectedLocations; // 'all' or comma-separated IDs
  final DateTime freezeStartDate;
  final DateTime? freezeEndDate;

  CreateAlertRequest({
    required this.title,
    required this.message,
    this.affectedProducts = 'all',
    this.affectedCategories = 'all',
    this.affectedLocations = 'all',
    required this.freezeStartDate,
    this.freezeEndDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'affected_products': affectedProducts,
      'affected_categories': affectedCategories,
      'affected_locations': affectedLocations,
      'freeze_start_date': freezeStartDate.toIso8601String().split('T')[0],
      'freeze_end_date': freezeEndDate?.toIso8601String().split('T')[0],
    };
  }
}

// Alert filters
class AlertFilters {
  String? status;
  DateTime? dateFrom;
  DateTime? dateTo;
  String? search;

  AlertFilters({
    this.status,
    this.dateFrom,
    this.dateTo,
    this.search,
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    
    if (status != null && status!.isNotEmpty) params['status'] = status!;
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    if (dateFrom != null) {
      params['date_from'] = dateFrom!.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      params['date_to'] = dateTo!.toIso8601String().split('T')[0];
    }
    
    return params;
  }

  void clear() {
    status = null;
    dateFrom = null;
    dateTo = null;
    search = null;
  }

  bool get hasActiveFilters {
    return status != null ||
           search != null && search!.isNotEmpty ||
           dateFrom != null ||
           dateTo != null;
  }
}
