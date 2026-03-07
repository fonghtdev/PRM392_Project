import '../models/payment_method.dart';
import '../models/saved_card.dart';
import '../data/app_database.dart';

class CheckoutPaymentService {
  final AppDatabase _db = AppDatabase.instance;

  /// Get all available payment methods from database
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final database = await _db.database;
    final results = await database.query(
      'payment_methods',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );

    return results.map((row) {
      return PaymentMethod(
        id: row['id'] as String,
        name: row['name'] as String,
        description: row['description'] as String,
        icon: row['icon'] as String,
        colorClass: row['color_class'] as String,
      );
    }).toList();
  }

  /// Get saved cards for a user from database
  Future<List<SavedCard>> getSavedCards({required int userId}) async {
    final database = await _db.database;
    final results = await database.query(
      'saved_cards',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_default DESC, created_at DESC',
    );

    return results.map((row) {
      return SavedCard(
        id: row['id'].toString(),
        cardNumber: row['card_number'] as String,
        cardHolder: row['card_holder'] as String,
        expiryDate: row['expiry_date'] as String,
        cardType: row['card_type'] as String,
        isDefault: (row['is_default'] as int) == 1,
      );
    }).toList();
  }

  /// Validate and apply promo code from database
  Future<Map<String, dynamic>> applyPromoCode(String code) async {
    final database = await _db.database;
    
    try {
      final results = await database.query(
        'promo_codes',
        where: 'code = ? AND is_active = ?',
        whereArgs: [code.toUpperCase(), 1],
        limit: 1,
      );

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid promo code',
          'discount': 0.0,
        };
      }

      final promo = results.first;
      final now = DateTime.now();
      final validFrom = DateTime.parse(promo['valid_from'] as String);
      final validUntil = DateTime.parse(promo['valid_until'] as String);

      // Check validity period
      if (now.isBefore(validFrom)) {
        return {
          'success': false,
          'message': 'Promo code not yet valid',
          'discount': 0.0,
        };
      }

      if (now.isAfter(validUntil)) {
        return {
          'success': false,
          'message': 'Promo code has expired',
          'discount': 0.0,
        };
      }

      // Check usage limit
      final usageLimit = promo['usage_limit'] as int?;
      final usageCount = promo['usage_count'] as int;
      if (usageLimit != null && usageCount >= usageLimit) {
        return {
          'success': false,
          'message': 'Promo code usage limit reached',
          'discount': 0.0,
        };
      }

      // Calculate discount
      final discountAmount = promo['discount_amount'] as double;
      final discountPercent = promo['discount_percent'] as double?;
      
      return {
        'success': true,
        'message': 'Promo code applied successfully',
        'discount': discountAmount,
        'discount_percent': discountPercent,
        'min_purchase': promo['min_purchase'] as double,
        'max_discount': promo['max_discount'] as double?,
        'code_id': promo['id'] as int,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error validating promo code: $e',
        'discount': 0.0,
      };
    }
  }

  /// Calculate order total with discount
  Map<String, double> calculateTotal({
    required double subtotal,
    double discount = 0.0,
    double shippingFee = 0.0,
  }) {
    final total = subtotal + shippingFee - discount;
    
    return {
      'subtotal': subtotal,
      'discount': discount,
      'shippingFee': shippingFee,
      'total': total > 0 ? total : 0.0,
    };
  }

  /// Add a new saved card to database
  Future<int> addSavedCard({
    required int userId,
    required String cardNumber,
    required String cardHolder,
    required String expiryDate,
    required String cardType,
    bool isDefault = false,
  }) async {
    final database = await _db.database;

    // If this is default, unset other defaults
    if (isDefault) {
      await database.update(
        'saved_cards',
        {'is_default': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }

    return await database.insert('saved_cards', {
      'user_id': userId,
      'card_number': cardNumber,
      'card_holder': cardHolder,
      'expiry_date': expiryDate,
      'card_type': cardType,
      'is_default': isDefault ? 1 : 0,
    });
  }

  /// Delete a saved card
  Future<int> deleteSavedCard(int cardId) async {
    final database = await _db.database;
    return await database.delete(
      'saved_cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  /// Set a card as default
  Future<void> setDefaultCard(int userId, int cardId) async {
    final database = await _db.database;

    // Unset all defaults for this user
    await database.update(
      'saved_cards',
      {'is_default': 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Set the selected card as default
    await database.update(
      'saved_cards',
      {'is_default': 1},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  /// Increment promo code usage count
  Future<void> incrementPromoUsage(int promoId) async {
    final database = await _db.database;
    await database.rawUpdate(
      'UPDATE promo_codes SET usage_count = usage_count + 1 WHERE id = ?',
      [promoId],
    );
  }
}
