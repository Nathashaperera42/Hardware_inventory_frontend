import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../models/item.dart';
import '../models/supplier.dart';
import '../models/stock_in_record.dart';
import '../services/inventory_api.dart';
import '../widgets/feedback.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});
  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  final _api = InventoryApi();
  final _fmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('M/d/yyyy');

  // lookup data
  List<Item> _items = [];
  List<Supplier> _suppliers = [];
  List<StockInRecord> _history = [];
  bool _loading = true;

  // form visibility
  bool _showForm = false;

  // form state
  final _formKey = GlobalKey<FormState>();
  int? _itemId;
  int? _supplierId;
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  bool _saving = false;

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
        _api.getSuppliers(),
        _api.getStockInHistory(),
      ]);
      _items = results[0] as List<Item>;
      _suppliers = results[1] as List<Supplier>;
      _history = results[2] as List<StockInRecord>;
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openForm() {
    setState(() {
      _showForm = true;
      _itemId = null;
      _supplierId = null;
      _qtyCtrl.clear();
      _costCtrl.clear();
    });
  }

  void _closeForm() => setState(() => _showForm = false);

  // Auto-fill cost price when item is selected
  void _onItemChanged(int? id) {
    setState(() => _itemId = id);
    if (id != null) {
      final item = _items.firstWhere((i) => i.itemId == id,
          orElse: () => _items.first);
      _costCtrl.text = item.costPrice.toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itemId == null || _supplierId == null) {
      showSnack(context, 'Please select an item and supplier.', error: true);
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      showSnack(context, 'Quantity must be greater than 0.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.stockIn(
        itemId: _itemId!,
        supplierId: _supplierId!,
        quantity: qty,
        costPrice: double.tryParse(_costCtrl.text.trim()) ?? 0,
        stockInDate: DateTime.now(),
      );
      if (mounted) {
        showSnack(context, 'Stock In recorded successfully.');
        _closeForm();
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _buildPage();
  }

  Widget _buildPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────
          Row(children: [
            const Icon(Icons.inventory_outlined,
                color: AppColors.primary, size: 26),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('Stock In',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
            if (!_showForm) ...[
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Entry'),
              ),
            ],
          ]),
          const SizedBox(height: 20),

          // ── Entry form card ──────────────────────────────────────
          if (_showForm) ...[
            _EntryFormCard(
              formKey: _formKey,
              items: _items,
              suppliers: _suppliers,
              itemId: _itemId,
              supplierId: _supplierId,
              qtyCtrl: _qtyCtrl,
              costCtrl: _costCtrl,
              saving: _saving,
              onItemChanged: _onItemChanged,
              onSupplierChanged: (v) => setState(() => _supplierId = v),
              onSave: _save,
              onCancel: _closeForm,
            ),
            const SizedBox(height: 20),
          ],

          // ── Recent history table ─────────────────────────────────
          _HistoryCard(history: _history, fmt: _fmt, dateFmt: _dateFmt),
        ],
      ),
    );
  }
}

// ── Form card ────────────────────────────────────────────────────────────────

class _EntryFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Item> items;
  final List<Supplier> suppliers;
  final int? itemId;
  final int? supplierId;
  final TextEditingController qtyCtrl;
  final TextEditingController costCtrl;
  final bool saving;
  final ValueChanged<int?> onItemChanged;
  final ValueChanged<int?> onSupplierChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EntryFormCard({
    required this.formKey,
    required this.items,
    required this.suppliers,
    required this.itemId,
    required this.supplierId,
    required this.qtyCtrl,
    required this.costCtrl,
    required this.saving,
    required this.onItemChanged,
    required this.onSupplierChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(children: [
                const Icon(Icons.add, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Add Stock In Entry',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 20,
                      color: AppColors.textMuted),
                  tooltip: 'Close',
                ),
              ]),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Row 1: Item | Supplier
                  LayoutBuilder(builder: (context, c) {
                    final wide = c.maxWidth > 600;
                    final itemDrop = DropdownButtonFormField<int>(
                      value: itemId,
                      isExpanded: true,
                      hint: const Text('Select Item *'),
                      decoration: const InputDecoration(),
                      items: items
                          .map((i) => DropdownMenuItem(
                              value: i.itemId,
                              child: Text(i.itemName)))
                          .toList(),
                      onChanged: onItemChanged,
                      validator: (v) => v == null ? 'Required' : null,
                    );
                    final supDrop = DropdownButtonFormField<int>(
                      value: supplierId,
                      isExpanded: true,
                      hint: const Text('Select Supplier *'),
                      decoration: const InputDecoration(),
                      items: suppliers
                          .map((s) => DropdownMenuItem(
                              value: s.supplierId,
                              child: Text(s.supplierName)))
                          .toList(),
                      onChanged: onSupplierChanged,
                      validator: (v) => v == null ? 'Required' : null,
                    );
                    if (wide) {
                      return Row(children: [
                        Expanded(child: itemDrop),
                        const SizedBox(width: 16),
                        Expanded(child: supDrop),
                      ]);
                    }
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          itemDrop,
                          const SizedBox(height: 14),
                          supDrop,
                        ]);
                  }),
                  const SizedBox(height: 16),

                  // Row 2: Quantity | Unit Cost
                  LayoutBuilder(builder: (context, c) {
                    final wide = c.maxWidth > 600;
                    final qtyField = TextFormField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          hintText: 'Quantity *'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n <= 0) ? 'Enter a valid quantity' : null;
                      },
                    );
                    final costField = TextFormField(
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          hintText: 'Unit Cost *'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n < 0) ? 'Enter a valid cost' : null;
                      },
                    );
                    if (wide) {
                      return Row(children: [
                        Expanded(child: qtyField),
                        const SizedBox(width: 16),
                        Expanded(child: costField),
                      ]);
                    }
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          qtyField,
                          const SizedBox(height: 14),
                          costField,
                        ]);
                  }),
                  const SizedBox(height: 20),

                  // Action buttons — Wrap prevents overflow on narrow screens
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: saving ? null : onSave,
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.inventory_outlined, size: 18),
                        label: Text(saving ? 'Saving...' : 'Record Stock In'),
                      ),
                      OutlinedButton.icon(
                        onPressed: saving ? null : onCancel,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History table card ───────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final List<StockInRecord> history;
  final NumberFormat fmt;
  final DateFormat dateFmt;

  const _HistoryCard({
    required this.history,
    required this.fmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              const Expanded(
                child: Text('Recent Stock In History',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('${history.length} records',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),

          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No stock-in records yet.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            LayoutBuilder(builder: (context, c) {
              return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: c.maxWidth),
                child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('STOCKIN ID')),
                  DataColumn(label: Text('ITEM')),
                  DataColumn(label: Text('SUPPLIER')),
                  DataColumn(label: Text('QTY'), numeric: true),
                  DataColumn(label: Text('UNIT COST'), numeric: true),
                  DataColumn(label: Text('TOTAL'), numeric: true),
                  DataColumn(label: Text('DATE')),
                ],
                rows: history.map((r) {
                  return DataRow(cells: [
                    DataCell(Text('#${r.stockInId}',
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500))),
                    DataCell(Text(r.itemName ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500))),
                    DataCell(Text(r.supplierName ?? '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.good.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('+${r.quantity}',
                            style: const TextStyle(
                                color: AppColors.good,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ),
                    DataCell(Text('Rs. ${fmt.format(r.costPrice)}')),
                    DataCell(Text('Rs. ${fmt.format(r.total)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold))),
                    DataCell(Text(dateFmt.format(r.stockInDate))),
                  ]);
                }).toList(),
                ), // DataTable
              ), // ConstrainedBox
              ); // SingleChildScrollView
            }), // LayoutBuilder
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
