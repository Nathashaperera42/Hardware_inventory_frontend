class Item {
  final int itemId;
  final String itemCode;
  final String? barcode;
  final String itemName;
  final int categoryId;
  final String? categoryName;
  final int supplierId;
  final String? supplierName;
  final double costPrice;
  final double sellingPrice;
  final int reorderLevel;
  final bool isActive;

  Item({
    required this.itemId,
    required this.itemCode,
    this.barcode,
    required this.itemName,
    required this.categoryId,
    this.categoryName,
    required this.supplierId,
    this.supplierName,
    required this.costPrice,
    required this.sellingPrice,
    required this.reorderLevel,
    this.isActive = true,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        itemId: json['itemId'] ?? 0,
        itemCode: json['itemCode'] ?? '',
        barcode: json['barcode'],
        itemName: json['itemName'] ?? '',
        categoryId: json['categoryId'] ?? 0,
        categoryName: json['categoryName'],
        supplierId: json['supplierId'] ?? 0,
        supplierName: json['supplierName'],
        costPrice: (json['costPrice'] ?? 0).toDouble(),
        sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
        reorderLevel: json['reorderLevel'] ?? 0,
        isActive: json['isActive'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'itemCode': itemCode,
        'barcode': barcode,
        'itemName': itemName,
        'categoryId': categoryId,
        'supplierId': supplierId,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'reorderLevel': reorderLevel,
        'isActive': isActive,
      };
}
