class StockOutRecord {
  final int stockOutId;
  final int itemId;
  final String? itemName;
  final int quantity;
  final String reason;
  final DateTime stockOutDate;

  StockOutRecord({
    required this.stockOutId,
    required this.itemId,
    this.itemName,
    required this.quantity,
    required this.reason,
    required this.stockOutDate,
  });

  factory StockOutRecord.fromJson(Map<String, dynamic> json) => StockOutRecord(
        stockOutId: json['stockOutId'] ?? 0,
        itemId: json['itemId'] ?? 0,
        itemName: json['itemName'],
        quantity: json['quantity'] ?? 0,
        reason: json['reason'] ?? '',
        stockOutDate: json['stockOutDate'] != null
            ? DateTime.parse(json['stockOutDate'])
            : DateTime.now(),
      );
}
