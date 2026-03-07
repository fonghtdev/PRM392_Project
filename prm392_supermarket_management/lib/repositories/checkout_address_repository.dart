import '../models/address.dart';
import '../services/checkout_address_service.dart';

class CheckoutAddressRepository {
  final CheckoutAddressService _service = CheckoutAddressService();

  /// Lấy tất cả địa chỉ đã lưu của user từ database
  /// [userId] mặc định = 1 (user demo), trong thực tế lấy từ auth service
  Future<List<Address>> getSavedAddresses({int userId = 1}) async {
    return await _service.getUserAddresses(userId);
  }

  /// Lấy thời gian giao hàng dự kiến
  Future<String> getEstimatedDelivery({Address? address, int userId = 1}) async {
    // Nếu không truyền address, lấy default address
    address ??= await _service.getDefaultAddress(userId);
    
    if (address == null) {
      return '3-5 Business Days'; // Mặc định
    }
    
    return await _service.calculateDelivery(address);
  }

  /// Chọn địa chỉ (set làm default)
  Future<bool> selectAddress(int addressId, {int userId = 1}) async {
    return await _service.setDefaultAddress(userId, addressId);
  }

  /// Xóa địa chỉ
  Future<bool> deleteAddress(int addressId) async {
    return await _service.deleteAddress(addressId);
  }

  /// Thêm địa chỉ mới
  Future<Address> addNewAddress(Address address) async {
    return await _service.addAddress(address);
  }

  /// Cập nhật địa chỉ
  Future<bool> updateAddress(Address address) async {
    return await _service.updateAddress(address);
  }
}
