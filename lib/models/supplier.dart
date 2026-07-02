class Supplier {
  final int supplierId;
  final String supplierName;
  final String? contactNumber;
  final String? email;
  final String? address;
  final bool isActive;
  final DateTime? createdDate;

  Supplier({
    required this.supplierId,
    required this.supplierName,
    this.contactNumber,
    this.email,
    this.address,
    this.isActive = true,
    this.createdDate,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        supplierId: json['supplierId'] ?? 0,
        supplierName: json['supplierName'] ?? '',
        contactNumber: json['contactNumber'],
        email: json['email'],
        address: json['address'],
        isActive: json['isActive'] ?? true,
        createdDate: json['createdDate'] != null
            ? DateTime.tryParse(json['createdDate'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'supplierName': supplierName,
        'contactNumber': contactNumber,
        'email': email,
        'address': address,
        'isActive': isActive,
      };
}
