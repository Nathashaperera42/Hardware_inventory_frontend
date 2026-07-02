class StockBalance {
  final int itemId;
  final String itemCode;
  final String itemName;
  final String categoryName;
  final int totalStockIn;
  final int totalStockOut;
  final int currentBalance;
  final int reorderLevel;
  final String stockStatus;

  StockBalance({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.categoryName,
    required this.totalStockIn,
    required this.totalStockOut,
    required this.currentBalance,
    required this.reorderLevel,
    required this.stockStatus,
  });

  factory StockBalance.fromJson(Map<String, dynamic> json) => StockBalance(
        itemId: json['itemId'] ?? 0,
        itemCode: json['itemCode'] ?? '',
        itemName: json['itemName'] ?? '',
        categoryName: json['categoryName'] ?? '',
        totalStockIn: json['totalStockIn'] ?? 0,
        totalStockOut: json['totalStockOut'] ?? 0,
        currentBalance: json['currentBalance'] ?? 0,
        reorderLevel: json['reorderLevel'] ?? 0,
        stockStatus: json['stockStatus'] ?? '',
      );
}
