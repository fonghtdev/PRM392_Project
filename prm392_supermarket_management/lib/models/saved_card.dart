class SavedCard {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cardType;
  final bool isDefault;

  SavedCard({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cardType,
    this.isDefault = false,
  });

  // Get masked card number (e.g., "**** **** **** 4242")
  String get maskedNumber {
    if (cardNumber.length < 4) return cardNumber;
    final lastFour = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $lastFour';
  }

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'] as String,
      cardNumber: json['cardNumber'] as String,
      cardHolder: json['cardHolder'] as String,
      expiryDate: json['expiryDate'] as String,
      cardType: json['cardType'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'expiryDate': expiryDate,
      'cardType': cardType,
      'isDefault': isDefault,
    };
  }
}
