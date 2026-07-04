import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/stock_balance.dart';
import '../services/inventory_api.dart';
import '../widgets/feedback.dart';

const _pageSize = 8;

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});
  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _api = InventoryApi();

  // list state
  List<Item> _all = [];
  List<StockBalance> _balances = [];
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  int? _filterCategoryId;
  int? _filterSupplierId;
  int _page = 0;

  // form state
  bool _showForm = false;
  Item? _editing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getItems(),
        _api.stockBalance(),
        _api.getCategories(),
        _api.getSuppliers(),
      ]);
      _all = results[0] as List<Item>;
      _balances = results[1] as List<StockBalance>;
      _categories = results[2] as List<Category>;
      _suppliers = results[3] as List<Supplier>;
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<int, int> get _balanceMap =>
      {for (final b in _balances) b.itemId: b.currentBalance};

  List<Item> get _filtered {
    final kw = _searchCtrl.text.trim().toLowerCase();
    return _all.where((i) {
      if (_filterCategoryId != null && i.categoryId != _filterCategoryId) {
        return false;
      }
      if (_filterSupplierId != null && i.supplierId != _filterSupplierId) {
        return false;
      }
      if (kw.isNotEmpty &&
          !i.itemName.toLowerCase().contains(kw) &&
          !i.itemCode.toLowerCase().contains(kw) &&
          !(i.barcode ?? '').toLowerCase().contains(kw)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _reset() {
    setState(() {
      _searchCtrl.clear();
      _filterCategoryId = null;
      _filterSupplierId = null;
      _page = 0;
    });
  }

  void _openForm([Item? item]) => setState(() {
        _editing = item;
        _showForm = true;
      });

  void _closeForm() => setState(() {
        _showForm = false;
        _editing = null;
      });

  Future<void> _delete(Item i) async {
    final ok = await confirmDelete(context, 'Delete "${i.itemName}"?');
    if (ok != true) return;
    try {
      await _api.deleteItem(i.itemId);
      if (mounted) showSnack(context, 'Item deleted.');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _ItemFormPage(
        api: _api,
        existing: _editing,
        categories: _categories,
        suppliers: _suppliers,
        onBack: () {
          _closeForm();
          _load();
        },
      );
    }

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _buildList();
  }

  Widget _buildList() {
    final filtered = _filtered;
    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 99999);
    final safePage = _page.clamp(0, totalPages - 1);
    final pageItems = filtered
        .skip(safePage * _pageSize)
        .take(_pageSize)
        .toList();
    final balMap = _balanceMap;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            const Expanded(
              child: Text('Item List',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Item'),
            ),
          ]),
          const SizedBox(height: 16),

          // Filters row — responsive
          LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth > 680;
            final search = TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by Item Code, Barcode or Name...',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (_) => setState(() => _page = 0),
            );
            final catDrop = DropdownButtonFormField<int?>(
              initialValue: _filterCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ..._categories.map((c) => DropdownMenuItem(
                    value: c.categoryId, child: Text(c.categoryName))),
              ],
              onChanged: (v) => setState(() {
                _filterCategoryId = v;
                _page = 0;
              }),
            );
            final supDrop = DropdownButtonFormField<int?>(
              initialValue: _filterSupplierId,
              decoration: const InputDecoration(labelText: 'Supplier'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ..._suppliers.map((s) => DropdownMenuItem(
                    value: s.supplierId, child: Text(s.supplierName))),
              ],
              onChanged: (v) => setState(() {
                _filterSupplierId = v;
                _page = 0;
              }),
            );
            final resetBtn =
                OutlinedButton(onPressed: _reset, child: const Text('Reset'));

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: catDrop),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: supDrop),
                  const SizedBox(width: 12),
                  resetBtn,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: catDrop),
                  const SizedBox(width: 12),
                  Expanded(child: supDrop),
                ]),
                const SizedBox(height: 12),
                Align(
                    alignment: Alignment.centerRight, child: resetBtn),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: pageItems.isEmpty
                  ? const Center(
                      child: Text('No items found.',
                          style: TextStyle(color: AppColors.textMuted)))
                  : Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(builder: (context, c) {
                            return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: c.maxWidth),
                              child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF8FAFC)),
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Item Code')),
                                DataColumn(label: Text('Barcode')),
                                DataColumn(label: Text('Item Name')),
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Supplier')),
                                DataColumn(
                                    label: Text('Qty In Hand'),
                                    numeric: true),
                                DataColumn(
                                    label: Text('Selling Price'),
                                    numeric: true),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: List.generate(pageItems.length, (i) {
                                final item = pageItems[i];
                                final rowNum = safePage * _pageSize + i + 1;
                                final qty =
                                    balMap[item.itemId] ?? 0;
                                return DataRow(cells: [
                                  DataCell(Text('$rowNum',
                                      style: const TextStyle(
                                          color: AppColors.textMuted))),
                                  DataCell(Text(item.itemCode,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600))),
                                  DataCell(
                                      Text(item.barcode ?? '-')),
                                  DataCell(Text(item.itemName)),
                                  DataCell(
                                      Text(item.categoryName ?? '-')),
                                  DataCell(
                                      Text(item.supplierName ?? '-')),
                                  DataCell(Text('$qty',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: qty <= 0
                                              ? AppColors.out
                                              : qty <=
                                                      item.reorderLevel
                                                  ? AppColors.low
                                                  : AppColors.textPrimary))),
                                  DataCell(Text(
                                      item.sellingPrice
                                          .toStringAsFixed(2))),
                                  DataCell(Row(children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: AppColors.primary),
                                      onPressed: () => _openForm(item),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: AppColors.out),
                                      onPressed: () => _delete(item),
                                      tooltip: 'Delete',
                                    ),
                                  ])),
                                ]);
                              }),
                            ), // DataTable
                          ), // ConstrainedBox
                          ); // SingleChildScrollView
                        }), // LayoutBuilder
                        ), // Expanded
                        const Divider(height: 1),
                        // Pagination footer
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(children: [
                            Text(
                              'Showing ${filtered.isEmpty ? 0 : safePage * _pageSize + 1}'
                              ' to ${(safePage * _pageSize + pageItems.length)}'
                              ' of ${filtered.length} items',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13),
                            ),
                            const Spacer(),
                            _PagerBtn(
                              icon: Icons.first_page,
                              enabled: safePage > 0,
                              onTap: () => setState(() => _page = 0),
                            ),
                            _PagerBtn(
                              icon: Icons.chevron_left,
                              enabled: safePage > 0,
                              onTap: () =>
                                  setState(() => _page = safePage - 1),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('${safePage + 1} / $totalPages',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            _PagerBtn(
                              icon: Icons.chevron_right,
                              enabled: safePage < totalPages - 1,
                              onTap: () =>
                                  setState(() => _page = safePage + 1),
                            ),
                            _PagerBtn(
                              icon: Icons.last_page,
                              enabled: safePage < totalPages - 1,
                              onTap: () =>
                                  setState(() => _page = totalPages - 1),
                            ),
                          ]),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PagerBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PagerBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: enabled ? onTap : null,
      color: AppColors.primary,
      disabledColor: AppColors.border,
    );
  }
}

// ── Full-page Add / Edit form ─────────────────────────────────────────────────

class _ItemFormPage extends StatefulWidget {
  final InventoryApi api;
  final Item? existing;
  final List<Category> categories;
  final List<Supplier> suppliers;
  final VoidCallback onBack;

  const _ItemFormPage({
    required this.api,
    required this.existing,
    required this.categories,
    required this.suppliers,
    required this.onBack,
  });

  @override
  State<_ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<_ItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _code, _barcode, _name, _cost, _sell, _reorder,
      _desc;
  int? _categoryId, _supplierId;
  String _status = 'Active';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _code = TextEditingController(text: e?.itemCode ?? '');
    _barcode = TextEditingController(text: e?.barcode ?? '');
    _name = TextEditingController(text: e?.itemName ?? '');
    _cost = TextEditingController(
        text: e != null ? e.costPrice.toStringAsFixed(2) : '');
    _sell = TextEditingController(
        text: e != null ? e.sellingPrice.toStringAsFixed(2) : '');
    _reorder =
        TextEditingController(text: e != null ? '${e.reorderLevel}' : '');
    _desc = TextEditingController();
    _categoryId = e?.categoryId;
    _supplierId = e?.supplierId;
    _status = (e?.isActive ?? true) ? 'Active' : 'Inactive';
  }

  @override
  void dispose() {
    for (final c in [_code, _barcode, _name, _cost, _sell, _reorder, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _supplierId == null) {
      showSnack(context, 'Please select a category and supplier.', error: true);
      return;
    }
    setState(() => _busy = true);
    final model = Item(
      itemId: widget.existing?.itemId ?? 0,
      itemCode: _code.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      itemName: _name.text.trim(),
      categoryId: _categoryId!,
      supplierId: _supplierId!,
      costPrice: double.tryParse(_cost.text) ?? 0,
      sellingPrice: double.tryParse(_sell.text) ?? 0,
      reorderLevel: int.tryParse(_reorder.text) ?? 0,
      isActive: _status == 'Active',
    );
    try {
      if (widget.existing == null) {
        await widget.api.createItem(model);
        if (mounted) showSnack(context, 'Item created.');
      } else {
        await widget.api.updateItem(widget.existing!.itemId, model);
        if (mounted) showSnack(context, 'Item updated.');
      }
      if (mounted) widget.onBack();
    } on ApiException catch (e) {
      setState(() => _busy = false);
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Row(children: [
              Expanded(
                child: Text(isNew ? 'Add Item' : 'Edit Item',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back to List'),
              ),
            ]),
            const SizedBox(height: 24),

            // Form card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Item Code | Cost Price
                  _FormRow(children: [
                    _Field(
                      label: 'Item Code *',
                      child: TextFormField(
                        controller: _code,
                        decoration: const InputDecoration(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    _Field(
                      label: 'Cost Price *',
                      child: TextFormField(
                        controller: _cost,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Row 2: Barcode | Selling Price
                  _FormRow(children: [
                    _Field(
                      label: 'Barcode',
                      child: TextFormField(
                        controller: _barcode,
                        decoration: const InputDecoration(),
                      ),
                    ),
                    _Field(
                      label: 'Selling Price *',
                      child: TextFormField(
                        controller: _sell,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Row 3: Item Name | Reorder Level
                  _FormRow(children: [
                    _Field(
                      label: 'Item Name *',
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    _Field(
                      label: 'Reorder Level *',
                      child: TextFormField(
                        controller: _reorder,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Row 4: Category | Status
                  _FormRow(children: [
                    _Field(
                      label: 'Category *',
                      child: DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        hint: const Text('Select Category'),
                        decoration: const InputDecoration(),
                        items: widget.categories
                            .map((c) => DropdownMenuItem(
                                value: c.categoryId,
                                child: Text(c.categoryName)))
                            .toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                    _Field(
                      label: 'Status *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(),
                        items: const [
                          DropdownMenuItem(
                              value: 'Active', child: Text('Active')),
                          DropdownMenuItem(
                              value: 'Inactive', child: Text('Inactive')),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? 'Active'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Row 5: Supplier | (empty)
                  _FormRow(children: [
                    _Field(
                      label: 'Supplier *',
                      child: DropdownButtonFormField<int>(
                        initialValue: _supplierId,
                        hint: const Text('Select Supplier'),
                        decoration: const InputDecoration(),
                        items: widget.suppliers
                            .map((s) => DropdownMenuItem(
                                value: s.supplierId,
                                child: Text(s.supplierName)))
                            .toList(),
                        onChanged: (v) => setState(() => _supplierId = v),
                      ),
                    ),
                    const _Field(label: '', child: SizedBox()),
                  ]),
                  const SizedBox(height: 16),
                  // Description full width
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _desc,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter item description (optional)...',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('* Required Fields',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(
                onPressed: _busy ? null : widget.onBack,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Form layout helpers ───────────────────────────────────────────────────────

class _FormRow extends StatelessWidget {
  final List<Widget> children;
  const _FormRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth > 600) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .expand((w) => [Expanded(child: w), const SizedBox(width: 16)])
              .toList()
            ..removeLast(),
        );
      }
      return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    });
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
        ],
        child,
      ],
    );
  }
}
