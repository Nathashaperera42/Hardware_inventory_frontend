class Category {
  final int categoryId;
  final String categoryName;
  final String? description;
  final bool isActive;
  final DateTime? createdDate;

  Category({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.isActive = true,
    this.createdDate,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        categoryId: json['categoryId'] ?? 0,
        categoryName: json['categoryName'] ?? '',
        description: json['description'],
        isActive: json['isActive'] ?? true,
        createdDate: json['createdDate'] != null
            ? DateTime.tryParse(json['createdDate'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'categoryName': categoryName,
        'description': description,
        'isActive': isActive,
      };
}
