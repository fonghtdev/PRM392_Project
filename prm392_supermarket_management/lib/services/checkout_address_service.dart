import '../models/address.dart';
import '../data/app_database.dart';

class CheckoutAddressService {
  /// Lấy tất cả địa chỉ của user từ database
  Future<List<Address>> getUserAddresses(int userId) async {
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'addresses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_default DESC, created_at DESC', // Default address lên đầu
    );

    return List.generate(maps.length, (i) {
      return Address.fromJson(maps[i]);
    });
  }

  /// Lấy địa chỉ mặc định của user
  Future<Address?> getDefaultAddress(int userId) async {
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'addresses',
      where: 'user_id = ? AND is_default = 1',
      whereArgs: [userId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Address.fromJson(maps.first);
  }

  /// Thêm địa chỉ mới vào database
  Future<Address> addAddress(Address address) async {
    final db = await AppDatabase.instance.database;
    
    // Nếu là default, reset các địa chỉ khác
    if (address.isDefault) {
      await db.update(
        'addresses',
        {'is_default': 0},
        where: 'user_id = ?',
        whereArgs: [address.userId],
      );
    }

    final id = await db.insert('addresses', address.toDatabase());
    return address.copyWith(id: id);
  }

  /// Cập nhật địa chỉ
  Future<bool> updateAddress(Address address) async {
    final db = await AppDatabase.instance.database;
    
    // Nếu set làm default, reset các địa chỉ khác
    if (address.isDefault) {
      await db.update(
        'addresses',
        {'is_default': 0},
        where: 'user_id = ? AND id != ?',
        whereArgs: [address.userId, address.id],
      );
    }

    final count = await db.update(
      'addresses',
      address.toDatabase(),
      where: 'id = ?',
      whereArgs: [address.id],
    );

    return count > 0;
  }

  /// Xóa địa chỉ
  Future<bool> deleteAddress(int addressId) async {
    final db = await AppDatabase.instance.database;
    
    final count = await db.delete(
      'addresses',
      where: 'id = ?',
      whereArgs: [addressId],
    );

    return count > 0;
  }

  /// Set địa chỉ làm mặc định
  Future<bool> setDefaultAddress(int userId, int addressId) async {
    final db = await AppDatabase.instance.database;
    
    // Reset tất cả địa chỉ khác
    await db.update(
      'addresses',
      {'is_default': 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Set địa chỉ được chọn làm default
    final count = await db.update(
      'addresses',
      {'is_default': 1},
      where: 'id = ?',
      whereArgs: [addressId],
    );

    return count > 0;
  }

  /// Tính thời gian giao hàng dự kiến (có thể tùy chỉnh logic)
  Future<String> calculateDelivery(Address address) async {
    // Logic đơn giản: tính theo khoảng cách hoặc khu vực
    // Có thể cải tiến bằng cách tích hợp API shipping
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Ví dụ: giao nhanh trong nội thành
    final fastCities = ['Ho Chi Minh', 'Hanoi', 'Da Nang'];
    if (fastCities.contains(address.city)) {
      return '2-3 Business Days';
    }
    
    return '3-5 Business Days';
  }
}
