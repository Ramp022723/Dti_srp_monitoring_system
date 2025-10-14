class AdminUser {
  final int? adminId;
  final String adminType;
  final String firstName;
  final String lastName;
  final String middleName;
  final String username;
  final String? profilePic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminUser({
    this.adminId,
    required this.adminType,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.username,
    this.profilePic,
    this.createdAt,
    this.updatedAt,
  });

  // Get full name
  String get fullName {
    return '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'.trim();
  }

  // Get admin type display name
  String get adminTypeDisplay {
    switch (adminType.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'barangay_admin':
        return 'Barangay Admin';
      case 'super_admin':
        return 'Super Admin';
      default:
        return adminType;
    }
  }

  // Get admin type color
  String get adminTypeColor {
    switch (adminType.toLowerCase()) {
      case 'admin':
        return 'primary';
      case 'barangay_admin':
        return 'success';
      case 'super_admin':
        return 'danger';
      default:
        return 'secondary';
    }
  }

  // Create from JSON
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      adminId: json['admin_id'] != null ? int.tryParse(json['admin_id'].toString()) : null,
      adminType: json['admin_type']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profilePic: json['profile_pic']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (adminId != null) 'admin_id': adminId,
      'admin_type': adminType,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'username': username,
      if (profilePic != null) 'profile_pic': profilePic,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Copy with method for updates
  AdminUser copyWith({
    int? adminId,
    String? adminType,
    String? firstName,
    String? lastName,
    String? middleName,
    String? username,
    String? profilePic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminUser(
      adminId: adminId ?? this.adminId,
      adminType: adminType ?? this.adminType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      username: username ?? this.username,
      profilePic: profilePic ?? this.profilePic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AdminUser{adminId: $adminId, adminType: $adminType, fullName: $fullName, username: $username}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminUser && other.adminId == adminId;
  }

  @override
  int get hashCode => adminId.hashCode;
}
