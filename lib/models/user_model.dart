class User {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? email;
  final String adminType;
  final String? profilePicture;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.email,
    required this.adminType,
    this.profilePicture,
    this.createdAt,
    this.updatedAt,
  });
  
  // Factory constructor from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['admin_id'] ?? json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      email: json['email'],
      adminType: json['admin_type'] ?? 'admin',
      profilePicture: json['profile_pic'] ?? json['profile_picture'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'admin_id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'email': email,
      'admin_type': adminType,
      'profile_pic': profilePicture,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  // Get full name
  String get fullName {
    final middle = middleName?.isNotEmpty == true ? ' $middleName' : '';
    return '$firstName$middle $lastName';
  }
  
  // Get display name (first name + last name)
  String get displayName {
    return '$firstName $lastName';
  }
  
  // Get initials
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return '$firstInitial$lastInitial'.toUpperCase();
  }
  
  // Get admin type display name
  String get adminTypeDisplay {
    switch (adminType) {
      case 'admin':
        return 'Admin';
      case 'barangay_admin':
        return 'Barangay Admin';
      case 'consumer':
        return 'Consumer';
      case 'retailer':
        return 'Retailer';
      default:
        return adminType.replaceAll('_', ' ').split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
        ).join(' ');
    }
  }
  
  // Check if user is admin
  bool get isAdmin => adminType == 'admin';
  
  // Check if user is barangay admin
  bool get isBarangayAdmin => adminType == 'barangay_admin';
  
  // Check if user is consumer
  bool get isConsumer => adminType == 'consumer';
  
  // Check if user is retailer
  bool get isRetailer => adminType == 'retailer';
  
  // Get profile picture URL
  String? get profilePictureUrl {
    if (profilePicture == null || profilePicture!.isEmpty) {
      return null;
    }
    
    // If it's already a full URL, return as is
    if (profilePicture!.startsWith('http')) {
      return profilePicture;
    }
    
    // Otherwise, construct the full URL
    return 'https://dtisrpmonitoring.bccbsis.com/uploads/profile_pics/$profilePicture';
  }
  
  // Copy with method
  User copyWith({
    int? id,
    String? username,
    String? firstName,
    String? lastName,
    String? middleName,
    String? email,
    String? adminType,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      email: email ?? this.email,
      adminType: adminType ?? this.adminType,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'User(id: $id, username: $username, fullName: $fullName, adminType: $adminType)';
  }
}
