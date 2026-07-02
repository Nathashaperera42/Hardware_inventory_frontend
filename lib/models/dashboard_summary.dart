class DashboardSummary {
  final int totalItems;
  final int totalCategories;
  final int totalSuppliers;
  final int lowStockItems;
  final int outOfStockItems;

  DashboardSummary({
    required this.totalItems,
    required this.totalCategories,
    required this.totalSuppliers,
    required this.lowStockItems,
    required this.outOfStockItems,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        totalItems: json['totalItems'] ?? 0,
        totalCategories: json['totalCategories'] ?? 0,
        totalSuppliers: json['totalSuppliers'] ?? 0,
        lowStockItems: json['lowStockItems'] ?? 0,
        outOfStockItems: json['outOfStockItems'] ?? 0,
      );

  factory DashboardSummary.empty() => DashboardSummary(
        totalItems: 0,
        totalCategories: 0,
        totalSuppliers: 0,
        lowStockItems: 0,
        outOfStockItems: 0,
      );
}
