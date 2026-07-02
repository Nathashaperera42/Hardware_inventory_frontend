class StockInRecord {
  final int stockInId;
  final int itemId;
  final String? itemName;
  final int supplierId;
  final String? supplierName;
  final int quantity;
  final double costPrice;
  final DateTime stockInDate;

  StockInRecord({
    required this.stockInId,
    required this.itemId,
    this.itemName,
    required this.supplierId,
    this.supplierName,
    required this.quantity,
    required this.costPrice,
    required this.stockInDate,
  });

  double get total => quantity * costPrice;

  factory StockInRecord.fromJson(Map<String, dynamic> json) => StockInRecord(
        stockInId: json['stockInId'] ?? 0,
        itemId: json['itemId'] ?? 0,
        itemName: json['itemName'],
        supplierId: json['supplierId'] ?? 0,
        supplierName: json['supplierName'],
        quantity: json['quantity'] ?? 0,
        costPrice: (json['costPrice'] ?? 0).toDouble(),
        stockInDate: json['stockInDate'] != null
            ? DateTime.parse(json['stockInDate'])
            : DateTime.now(),
      );
}
