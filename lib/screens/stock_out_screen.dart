import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../models/item.dart';
import '../models/stock_balance.dart';
import '../models/stock_out_record.dart';
import '../services/inventory_api.dart';
import '../widgets/feedback.dart';

class StockOutScreen extends StatefulWidget {
  const StockOutScreen({super.key});
  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  final _api = InventoryApi();
  final _dateFmt = DateFormat('M/d/yyyy');

  // lookup data
  List<Item> _items = [];
  Map<int, int> _balanceMap = {};
  List<StockOutRecord> _history = [];
  bool _loading = true;

  // form visibility
  bool _showForm = false;

  // form state
  final _formKey = GlobalKey<FormState>();
  int? _itemId;
  int _reason = 1;
  final _qtyCtrl = TextEditingController();
  bool _saving = false;

  static const _reasons = {
    1: 'Sale',
    2: 'Damage',
    3: 'Internal Use',
    4: 'Return',
  };

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
        _api.getStockOutHistory(),
      ]);
      _items = results[0] as List<Item>;
      final balances = results[1] as List<StockBalance>;
      _balanceMap = {for (final b in balances) b.itemId: b.currentBalance};
      _history = results[2] as List<StockOutRecord>;
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openForm() {
    setState(() {
      _showForm = true;
      _itemId = null;
      _reason = 1;
      _qtyCtrl.clear();
    });
  }

  void _closeForm() => setState(() => _showForm = false);

  int get _availableQty => _itemId != null ? (_balanceMap[_itemId] ?? 0) : 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itemId == null) {
      showSnack(context, 'Please select an item.', error: true);
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      showSnack(context, 'Quantity must be greater than 0.', error: true);
      return;
    }
    if (qty > _availableQty) {
      showSnack(
          context,
          'Insufficient stock. Available: $_availableQty.',
          error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.stockOut(
        itemId: _itemId!,
        quantity: qty,
        reason: _reason,
        stockOutDate: DateTime.now(),
      );
      if (mounted) {
        showSnack(context, 'Stock Out recorded successfully.');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page header ────────────────────────────────────
                Row(children: [
                  const Icon(Icons.inventory_outlined,
                      color: AppColors.primary, size: 26),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text('Stock Out',
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

                // ── Entry form card ────────────────────────────────
                if (_showForm) ...[
                  _EntryFormCard(
                    formKey: _formKey,
                    items: _items,
                    balanceMap: _balanceMap,
                    itemId: _itemId,
                    reason: _reason,
                    qtyCtrl: _qtyCtrl,
                    saving: _saving,
                    availableQty: _availableQty,
                    reasons: _reasons,
                    onItemChanged: (v) => setState(() => _itemId = v),
                    onReasonChanged: (v) => setState(() => _reason = v ?? 1),
                    onSave: _save,
                    onCancel: _closeForm,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── History table ──────────────────────────────────
                _HistoryCard(history: _history, dateFmt: _dateFmt),
              ],
            ),
          );
  }
}

// ── Form card ────────────────────────────────────────────────────────────────

class _EntryFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Item> items;
  final Map<int, int> balanceMap;
  final int? itemId;
  final int reason;
  final TextEditingController qtyCtrl;
  final bool saving;
  final int availableQty;
  final Map<int, String> reasons;
  final ValueChanged<int?> onItemChanged;
  final ValueChanged<int?> onReasonChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EntryFormCard({
    required this.formKey,
    required this.items,
    required this.balanceMap,
    required this.itemId,
    required this.reason,
    required this.qtyCtrl,
    required this.saving,
    required this.availableQty,
    required this.reasons,
    required this.onItemChanged,
    required this.onReasonChanged,
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
                  child: Text('Add Stock Out Entry',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close,
                      size: 20, color: AppColors.textMuted),
                  tooltip: 'Close',
                ),
              ]),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Select Item | Quantity
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
                    final qtyField = TextFormField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Quantity *',
                        suffixText: itemId != null
                            ? 'Avail: $availableQty'
                            : null,
                        suffixStyle: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Enter a valid quantity';
                        return null;
                      },
                    );
                    if (wide) {
                      return Row(children: [
                        Expanded(child: itemDrop),
                        const SizedBox(width: 16),
                        Expanded(child: qtyField),
                      ]);
                    }
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          itemDrop,
                          const SizedBox(height: 14),
                          qtyField,
                        ]);
                  }),
                  const SizedBox(height: 16),

                  // Row 2: Reason (half width on wide screens)
                  LayoutBuilder(builder: (context, c) {
                    final wide = c.maxWidth > 600;
                    final reasonDrop = DropdownButtonFormField<int>(
                      value: reason,
                      isExpanded: true,
                      decoration: const InputDecoration(hintText: 'Reason *'),
                      items: reasons.entries
                          .map((e) => DropdownMenuItem(
                              value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: onReasonChanged,
                    );
                    if (wide) {
                      return Row(children: [
                        Expanded(child: reasonDrop),
                        const Expanded(child: SizedBox()),
                      ]);
                    }
                    return reasonDrop;
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
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.inventory_outlined, size: 18),
                        label: Text(
                            saving ? 'Saving...' : 'Record Stock Out'),
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
  final List<StockOutRecord> history;
  final DateFormat dateFmt;

  const _HistoryCard({required this.history, required this.dateFmt});

  String _reasonLabel(String raw) {
    switch (raw.toLowerCase().replaceAll(' ', '')) {
      case 'internaluse':
        return 'Internal Use';
      case 'sale':
        return 'Sale';
      case 'damage':
        return 'Damage';
      case 'return':
        return 'Return';
      default:
        return raw;
    }
  }

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
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              const Expanded(
                child: Text('Recent Stock Out History',
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
                child: Text('No stock-out records yet.',
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
                    headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF8FAFC)),
                    headingTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5),
                    columnSpacing: 28,
                    columns: const [
                      DataColumn(label: Text('STOCKOUT ID')),
                      DataColumn(label: Text('ITEM')),
                      DataColumn(label: Text('QTY'), numeric: true),
                      DataColumn(label: Text('REASON')),
                      DataColumn(label: Text('DATE')),
                    ],
                    rows: history.map((r) {
                      return DataRow(cells: [
                        DataCell(Text('#${r.stockOutId}',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500))),
                        DataCell(Text(r.itemName ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.out.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('-${r.quantity}',
                                style: const TextStyle(
                                    color: AppColors.out,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                        ),
                        DataCell(Text(_reasonLabel(r.reason))),
                        DataCell(Text(dateFmt.format(r.stockOutDate))),
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
