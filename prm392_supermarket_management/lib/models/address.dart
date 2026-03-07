class Address {
  final int? id;
  final int userId;
  final String recipientName;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final bool isDefault;
  final DateTime createdAt;

  const Address({
    this.id,
    required this.userId,
    required this.recipientName,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    this.state,
    this.postalCode,
    this.country = 'VN',
    this.isDefault = false,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      recipientName: json['recipient_name'] as String,
      phone: json['phone'] as String,
      line1: json['line1'] as String,
      line2: json['line2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String? ?? 'VN',
      isDefault: (json['is_default'] as int) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipient_name': recipientName,
      'phone': phone,
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'recipient_name': recipientName,
      'phone': phone,
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fullAddress {
    final parts = <String>[
      line1,
      if (line2?.isNotEmpty == true) line2!,
      city,
      if (state?.isNotEmpty == true) state!,
      if (postalCode?.isNotEmpty == true) postalCode!,
      country,
    ];
    return parts.join(', ');
  }

  String get shortAddress => '$line1, $city';

  Address copyWith({
    int? id,
    int? userId,
    String? recipientName,
    String? phone,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => fullAddress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}