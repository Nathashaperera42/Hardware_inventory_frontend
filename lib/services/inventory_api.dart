import '../core/api_client.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/item.dart';
import '../models/stock_balance.dart';
import '../models/stock_in_record.dart';
import '../models/stock_out_record.dart';
import '../models/dashboard_summary.dart';

/// Single typed gateway to every backend endpoint defined in the challenge.
class InventoryApi {
  final ApiClient _client = ApiClient();

  // ---------- Dashboard ----------
  Future<DashboardSummary> dashboardSummary() async {
    final data = await _client.get('/dashboard/summary');
    return DashboardSummary.fromJson(data);
  }

  // ---------- Categories ----------
  Future<List<Category>> getCategories() async {
    final data = await _client.get('/category') as List;
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Category>> searchCategories(String keyword) async {
    final data = await _client.get('/category/search', query: {'keyword': keyword}) as List;
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<Category> createCategory(Category c) async {
    final data = await _client.post('/category', c.toJson());
    return Category.fromJson(data);
  }

  Future<Category> updateCategory(int id, Category c) async {
    final data = await _client.put('/category/$id', c.toJson());
    return Category.fromJson(data);
  }

  Future<void> deleteCategory(int id) => _client.delete('/category/$id');

  // ---------- Suppliers ----------
  Future<List<Supplier>> getSuppliers() async {
    final data = await _client.get('/supplier') as List;
    return data.map((e) => Supplier.fromJson(e)).toList();
  }

  Future<Supplier> createSupplier(Supplier s) async {
    final data = await _client.post('/supplier', s.toJson());
    return Supplier.fromJson(data);
  }

  Future<Supplier> updateSupplier(int id, Supplier s) async {
    final data = await _client.put('/supplier/$id', s.toJson());
    return Supplier.fromJson(data);
  }

  Future<void> deleteSupplier(int id) => _client.delete('/supplier/$id');

  // ---------- Items ----------
  Future<List<Item>> getItems() async {
    final data = await _client.get('/item') as List;
    return data.map((e) => Item.fromJson(e)).toList();
  }

  Future<List<Item>> searchItems(String keyword) async {
    final data = await _client.get('/item/search', query: {'keyword': keyword}) as List;
    return data.map((e) => Item.fromJson(e)).toList();
  }

  Future<Item> createItem(Item i) async {
    final data = await _client.post('/item', i.toJson());
    return Item.fromJson(data);
  }

  Future<Item> updateItem(int id, Item i) async {
    final data = await _client.put('/item/$id', i.toJson());
    return Item.fromJson(data);
  }

  Future<void> deleteItem(int id) => _client.delete('/item/$id');

  // ---------- Stock ----------
  Future<void> stockIn({
    required int itemId,
    required int supplierId,
    required int quantity,
    required double costPrice,
    DateTime? stockInDate,
  }) =>
      _client.post('/stock/in', {
        'itemId': itemId,
        'supplierId': supplierId,
        'quantity': quantity,
        'costPrice': costPrice,
        if (stockInDate != null) 'stockInDate': stockInDate.toIso8601String(),
      });

  Future<void> stockOut({
    required int itemId,
    required int quantity,
    required int reason,
    DateTime? stockOutDate,
  }) =>
      _client.post('/stock/out', {
        'itemId': itemId,
        'quantity': quantity,
        'reason': reason,
        if (stockOutDate != null) 'stockOutDate': stockOutDate.toIso8601String(),
      });

  Future<List<StockBalance>> stockBalance() async {
    final data = await _client.get('/stock/balance') as List;
    return data.map((e) => StockBalance.fromJson(e)).toList();
  }

  Future<List<StockBalance>> lowStock() async {
    final data = await _client.get('/stock/low-stock') as List;
    return data.map((e) => StockBalance.fromJson(e)).toList();
  }

  Future<List<StockInRecord>> getStockInHistory() async {
    final data = await _client.get('/stock/in') as List;
    return data.map((e) => StockInRecord.fromJson(e)).toList();
  }

  Future<List<StockOutRecord>> getStockOutHistory() async {
    final data = await _client.get('/stock/out') as List;
    return data.map((e) => StockOutRecord.fromJson(e)).toList();
  }
}
