enum UserRole {
  admin,
  user;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.user:
        return 'User';
    }
  }

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.user:
        return 'user';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  // Permissions for roles
  bool get canManageProducts => this == UserRole.admin;
  bool get canManageUsers => this == UserRole.admin;
  bool get canViewReports => this == UserRole.admin;
  bool get canManageOrders => this == UserRole.admin;
}

class User {
  final int? id;
  final String username;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? address;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImageUrl;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.address,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      phoneNumber: map['phone_number'],
      address: map['address'],
      role: UserRole.fromString(map['role'] ?? 'user'),
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      profileImageUrl: map['profile_image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address': address,
      'role': role.value,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_image_url': profileImageUrl,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? address,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  String get initials {
    List<String> nameParts = fullName.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;

  String get displayName => fullName.isNotEmpty ? fullName : username;

  String get jobTitle {
    switch (role) {
      case UserRole.admin:
        return 'Senior Operations Manager';
      case UserRole.user:
        return 'Customer';
    }
  }

  String get statusBadge => isActive ? 'Active Staff' : 'Inactive';

  List<String> get permissions {
    if (role == UserRole.admin) {
      return [
        'Inventory Management',
        'Order Processing',
        'Refund Approval',
        'Financial Reports',
      ];
    }
    return [];
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && 
           other.id == id && 
           other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}