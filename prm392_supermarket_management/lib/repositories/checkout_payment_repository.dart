import '../models/payment_method.dart';
import '../models/saved_card.dart';
import '../services/checkout_payment_service.dart';

class CheckoutPaymentRepository {
  final CheckoutPaymentService _service = CheckoutPaymentService();

  Future<List<PaymentMethod>> getPaymentMethods() {
    return _service.getPaymentMethods();
  }

  Future<List<SavedCard>> getSavedCards({required int userId}) {
    return _service.getSavedCards(userId: userId);
  }

  Future<Map<String, dynamic>> applyPromoCode(String code) {
    return _service.applyPromoCode(code);
  }

  Map<String, double> calculateTotal({
    required double subtotal,
    double discount = 0.0,
    double shippingFee = 0.0,
  }) {
    return _service.calculateTotal(
      subtotal: subtotal,
      discount: discount,
      shippingFee: shippingFee,
    );
  }

  Future<int> addSavedCard({
    required int userId,
    required String cardNumber,
    required String cardHolder,
    required String expiryDate,
    required String cardType,
    bool isDefault = false,
  }) {
    return _service.addSavedCard(
      userId: userId,
      cardNumber: cardNumber,
      cardHolder: cardHolder,
      expiryDate: expiryDate,
      cardType: cardType,
      isDefault: isDefault,
    );
  }

  Future<int> deleteSavedCard(int cardId) {
    return _service.deleteSavedCard(cardId);
  }

  Future<void> setDefaultCard(int userId, int cardId) {
    return _service.setDefaultCard(userId, cardId);
  }

  Future<void> incrementPromoUsage(int promoId) {
    return _service.incrementPromoUsage(promoId);
  }
}
