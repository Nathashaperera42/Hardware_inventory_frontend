import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../models/item.dart';
import '../models/stock_balance.dart';
import '../services/inventory_api.dart';
import '../widgets/feedback.dart';
import '../widgets/status_chip.dart';

const _pageSize = 8;

class StockBalanceScreen extends StatefulWidget {
  final bool lowStockOnly;
  const StockBalanceScreen({super.key, this.lowStockOnly = false});
  @override
  State<StockBalanceScreen> createState() => _StockBalanceScreenState();
}

class _StockBalanceScreenState extends State<StockBalanceScreen> {
  final _api = InventoryApi();
  final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

  List<StockBalance> _all = [];
  List<Item> _items = [];
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  String? _filterCategory;
  int? _filterSupplierId;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.stockBalance(), // always full data; frontend filters for Low Stock
        _api.getItems(),
      ]);
      _all = results[0] as List<StockBalance>;
      _items = results[1] as List<Item>;
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _reload() {
    _page = 0;
    _load();
  }

  Map<int, int> get _supplierMap =>
      {for (final i in _items) i.itemId: i.supplierId};

  List<String> get _categoryOptions {
    final cats = _all.map((b) => b.categoryName).toSet().toList()..sort();
    return cats;
  }

  List<MapEntry<int, String>> get _supplierOptions {
    final seen = <int>{};
    final result = <MapEntry<int, String>>[];
    for (final i in _items) {
      if (seen.add(i.supplierId) && i.supplierName != null) {
        result.add(MapEntry(i.supplierId, i.supplierName!));
      }
    }
    result.sort((a, b) => a.value.compareTo(b.value));
    return result;
  }

  List<StockBalance> get _filtered {
    final kw = _searchCtrl.text.trim().toLowerCase();
    final supMap = _supplierMap;
    return _all.where((b) {
      // Low Stock Report shows ONLY items with status "Low Stock"
      if (widget.lowStockOnly && b.stockStatus != 'Low Stock') return false;
      if (_filterCategory != null && b.categoryName != _filterCategory) {
        return false;
      }
      if (_filterSupplierId != null &&
          supMap[b.itemId] != _filterSupplierId) {
        return false;
      }
      if (kw.isNotEmpty &&
          !b.itemName.toLowerCase().contains(kw) &&
          !b.itemCode.toLowerCase().contains(kw)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _applyFilter() => setState(() => _page = 0);

  // ── PDF generation ────────────────────────────────────────────────────────

  Future<pw.Document> _buildPdf(List<StockBalance> data) async {
    final doc = pw.Document();
    final now = _dateFmt.format(DateTime.now());
    final title = widget.lowStockOnly
        ? 'Low Stock Report'
        : 'Stock Balance Report';

    // Both reports use all 8 required columns
    const headers = [
      '#', 'Item Code', 'Item Name', 'Category Name',
      'Total Stock In', 'Total Stock Out', 'Current Balance',
      'Reorder Level', 'Stock Status',
    ];

    final rows = data.asMap().entries.map((e) {
      final i = e.key + 1;
      final b = e.value;
      return [
        '$i', b.itemCode, b.itemName, b.categoryName,
        '${b.totalStockIn}', '${b.totalStockOut}', '${b.currentBalance}',
        '${b.reorderLevel}', b.stockStatus,
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Text(title,
              style: const pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generated: $now   •   Total records: ${data.length}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey100),
            rowDecoration: const pw.BoxDecoration(),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
            },
          ),
        ],
      ),
    );
    return doc;
  }

  Future<void> _downloadPdf() async {
    final data = _filtered;
    if (data.isEmpty) {
      showSnack(context, 'No data to export.', error: true);
      return;
    }
    try {
      final doc = await _buildPdf(data);
      final bytes = await doc.save();
      final fileName = widget.lowStockOnly
          ? 'low_stock_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf'
          : 'stock_balance_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (mounted) showSnack(context, 'PDF export failed: $e', error: true);
    }
  }

  Future<void> _printReport() async {
    final data = _filtered;
    if (data.isEmpty) {
      showSnack(context, 'No data to print.', error: true);
      return;
    }
    try {
      final doc = await _buildPdf(data);
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: widget.lowStockOnly ? 'Low Stock Report' : 'Stock Balance Report',
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Print failed: $e', error: true);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header (responsive: icon-only buttons on narrow screens) ──
          LayoutBuilder(builder: (ctx, c) {
            final narrow = c.maxWidth < 520;
            final title = widget.lowStockOnly
                ? 'Low Stock Report'
                : 'Stock Balance Report';
            final icon = widget.lowStockOnly
                ? const Icon(Icons.warning_amber_rounded,
                    color: AppColors.low, size: 26)
                : const Icon(Icons.assessment_outlined,
                    color: AppColors.primary, size: 26);
            return Row(children: [
              icon,
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              if (narrow) ...[
                IconButton(
                  onPressed: _printReport,
                  icon: const Icon(Icons.print_outlined),
                  tooltip: 'Print',
                  color: AppColors.primary,
                ),
                IconButton(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Download PDF',
                  color: AppColors.primary,
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _printReport,
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Download PDF'),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh, color: AppColors.textMuted),
                tooltip: 'Refresh',
              ),
            ]);
          }),
          const SizedBox(height: 12),

          // ── Low Stock summary banner (only on Low Stock screen) ────────
          if (widget.lowStockOnly && !_loading) _buildLowStockBanner(),

          if (!widget.lowStockOnly) const SizedBox(height: 4),

          // ── Filters ───────────────────────────────────────────────────
          if (!_loading) ...[
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 680;
              final catDrop = DropdownButtonFormField<String?>(
                initialValue: _filterCategory,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ..._categoryOptions.map((c) =>
                      DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (v) => setState(() {
                  _filterCategory = v;
                  _page = 0;
                }),
              );
              final supDrop = DropdownButtonFormField<int?>(
                initialValue: _filterSupplierId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Supplier'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ..._supplierOptions.map((e) => DropdownMenuItem(
                      value: e.key, child: Text(e.value))),
                ],
                onChanged: (v) => setState(() {
                  _filterSupplierId = v;
                  _page = 0;
                }),
              );
              final search = TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Search Item',
                  hintText: 'Search by code or name...',
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
                onChanged: (_) => _applyFilter(),
              );
              final filterBtn = ElevatedButton(
                onPressed: _applyFilter,
                child: const Text('Filter'),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 2, child: catDrop),
                    const SizedBox(width: 12),
                    if (!widget.lowStockOnly) ...[
                      Expanded(flex: 2, child: supDrop),
                      const SizedBox(width: 12),
                    ],
                    Expanded(flex: 3, child: search),
                    const SizedBox(width: 12),
                    filterBtn,
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
                    if (!widget.lowStockOnly) ...[
                      const SizedBox(width: 12),
                      Expanded(child: supDrop),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  Align(
                      alignment: Alignment.centerRight,
                      child: filterBtn),
                ],
              );
            }),
            const SizedBox(height: 16),
          ],

          // ── Table ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockBanner() {
    final lowCount =
        _all.where((b) => b.stockStatus == 'Low Stock').length;
    final totalItems = _all.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        _BannerChip(
          label: 'Low Stock Items',
          count: lowCount,
          color: AppColors.low,
          bgColor: AppColors.low.withValues(alpha: 0.1),
          icon: Icons.warning_amber_outlined,
        ),
        const SizedBox(width: 12),
        _BannerChip(
          label: 'Total Items',
          count: totalItems,
          color: AppColors.textMuted,
          bgColor: AppColors.scaffold,
          icon: Icons.inventory_2_outlined,
        ),
      ]),
    );
  }

  Widget _buildTable() {
    final filtered = _filtered;
    final totalPages =
        (filtered.length / _pageSize).ceil().clamp(1, 99999);
    final safePage = _page.clamp(0, totalPages - 1);
    final pageItems =
        filtered.skip(safePage * _pageSize).take(_pageSize).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: widget.lowStockOnly
                ? AppColors.low.withValues(alpha: 0.3)
                : AppColors.border),
      ),
      child: pageItems.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.lowStockOnly
                        ? Icons.check_circle_outline
                        : Icons.inventory_2_outlined,
                    size: 48,
                    color: widget.lowStockOnly
                        ? AppColors.good
                        : AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.lowStockOnly
                        ? 'All items are well stocked!'
                        : 'No stock data found.',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          : Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      widget.lowStockOnly
                          ? AppColors.low.withValues(alpha: 0.08)
                          : const Color(0xFFF8FAFC),
                    ),
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Item Code')),
                      DataColumn(label: Text('Item Name')),
                      DataColumn(label: Text('Category Name')),
                      DataColumn(
                          label: Text('Total Stock In'), numeric: true),
                      DataColumn(
                          label: Text('Total Stock Out'), numeric: true),
                      DataColumn(
                          label: Text('Current Balance'), numeric: true),
                      DataColumn(
                          label: Text('Reorder Level'), numeric: true),
                      DataColumn(label: Text('Stock Status')),
                    ],
                    rows: List.generate(pageItems.length, (i) {
                      final b = pageItems[i];
                      final rowNum = safePage * _pageSize + i + 1;
                      return DataRow(cells: [
                        DataCell(Text('$rowNum',
                            style: const TextStyle(
                                color: AppColors.textMuted))),
                        DataCell(Text(b.itemCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600))),
                        DataCell(Text(b.itemName)),
                        DataCell(Text(b.categoryName)),
                        DataCell(Text('${b.totalStockIn}',
                            style: const TextStyle(
                                color: AppColors.good))),
                        DataCell(Text('${b.totalStockOut}',
                            style: const TextStyle(
                                color: AppColors.out))),
                        DataCell(Text('${b.currentBalance}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: b.currentBalance <= 0
                                    ? AppColors.out
                                    : b.currentBalance <= b.reorderLevel
                                        ? AppColors.low
                                        : AppColors.textPrimary))),
                        DataCell(Text('${b.reorderLevel}')),
                        DataCell(StatusChip(b.stockStatus)),
                      ]);
                    }),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Pagination footer
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(children: [
                  Text(
                    'Showing ${filtered.isEmpty ? 0 : safePage * _pageSize + 1}'
                    ' to ${safePage * _pageSize + pageItems.length}'
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
                    onTap: () => setState(() => _page = safePage - 1),
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
                    onTap: () => setState(() => _page = safePage + 1),
                  ),
                  _PagerBtn(
                    icon: Icons.last_page,
                    enabled: safePage < totalPages - 1,
                    onTap: () =>
                        setState(() => _page = totalPages - 1),
                  ),
                ]),
              ),
            ]),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _BannerChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _BannerChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: color)),
        ]),
      ]),
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
