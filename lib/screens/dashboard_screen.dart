import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/dashboard_summary.dart';
import '../models/stock_balance.dart';
import '../models/stock_in_record.dart';
import '../models/stock_out_record.dart';
import '../services/inventory_api.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  /// Called with the sidebar tab index to jump to when a "View All" link is tapped.
  final ValueChanged<int>? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// Sidebar tab indices (must match Sidebar's navItems order in home_shell.dart).
const _tabStockIn = 4;
const _tabStockOut = 5;
const _tabLowStock = 7;

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = InventoryApi();
  final _dateFmt = DateFormat('MMM d, yyyy');
  late Future<_DashData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashData> _load() async {
    final results = await Future.wait([
      _api.dashboardSummary(),
      _api.lowStock(),
      _api.getStockInHistory(),
      _api.getStockOutHistory(),
    ]);
    return _DashData(
      summary:   results[0] as DashboardSummary,
      lowStock:  results[1] as List<StockBalance>,
      recentIn:  (results[2] as List<StockInRecord>).take(5).toList(),
      recentOut: (results[3] as List<StockOutRecord>).take(5).toList(),
    );
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry')),
            ]),
          );
        }

        final d = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _Header(onRefresh: _refresh),
            const SizedBox(height: 20),
            _StatGrid(summary: d.summary),
            const SizedBox(height: 20),
            _RecentRow(
                recentIn: d.recentIn,
                recentOut: d.recentOut,
                dateFmt: _dateFmt,
                onViewAllIn: () => widget.onNavigate?.call(_tabStockIn),
                onViewAllOut: () => widget.onNavigate?.call(_tabStockOut)),
            const SizedBox(height: 20),
            _LowStockCard(
                items: d.lowStock,
                onViewAll: () => widget.onNavigate?.call(_tabLowStock)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── Data holder ───────────────────────────────────────────────────────────────
class _DashData {
  final DashboardSummary summary;
  final List<StockBalance> lowStock;
  final List<StockInRecord> recentIn;
  final List<StockOutRecord> recentOut;
  const _DashData({
    required this.summary,
    required this.lowStock,
    required this.recentIn,
    required this.recentOut,
  });
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dashboard',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        SizedBox(height: 2),
        Text('Welcome back, Admin  👋',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ]),
      const Spacer(),
      IconButton(
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
        color: AppColors.textMuted,
        tooltip: 'Refresh',
      ),
    ]);
  }
}

// ── Stat cards grid ───────────────────────────────────────────────────────────
class _StatGrid extends StatelessWidget {
  final DashboardSummary summary;
  const _StatGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
          icon: Icons.inventory_2_rounded,
          accent: AppColors.primary,
          value: '${summary.totalItems}',
          label: 'Total Items'),
      StatCard(
          icon: Icons.category_rounded,
          accent: const Color(0xFF0891B2),
          value: '${summary.totalCategories}',
          label: 'Total Categories'),
      StatCard(
          icon: Icons.local_shipping_rounded,
          accent: const Color(0xFF059669),
          value: '${summary.totalSuppliers}',
          label: 'Total Suppliers'),
      StatCard(
          icon: Icons.warning_amber_rounded,
          accent: AppColors.low,
          value: '${summary.lowStockItems}',
          label: 'Low Stock Items'),
    ];

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 800 ? 4 : 2;
      final cardW = (c.maxWidth - (cols - 1) * 16) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: cards.map((card) => SizedBox(width: cardW, child: card)).toList(),
      );
    });
  }
}

// ── Recent stock panels ───────────────────────────────────────────────────────
class _RecentRow extends StatelessWidget {
  final List<StockInRecord>  recentIn;
  final List<StockOutRecord> recentOut;
  final DateFormat dateFmt;
  final VoidCallback? onViewAllIn;
  final VoidCallback? onViewAllOut;
  const _RecentRow({
    required this.recentIn,
    required this.recentOut,
    required this.dateFmt,
    this.onViewAllIn,
    this.onViewAllOut,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth > 680) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _RecentInCard(records: recentIn, dateFmt: dateFmt, onViewAll: onViewAllIn)),
            const SizedBox(width: 16),
            Expanded(child: _RecentOutCard(records: recentOut, dateFmt: dateFmt, onViewAll: onViewAllOut)),
          ],
        );
      }
      return Column(children: [
        _RecentInCard(records: recentIn, dateFmt: dateFmt, onViewAll: onViewAllIn),
        const SizedBox(height: 16),
        _RecentOutCard(records: recentOut, dateFmt: dateFmt, onViewAll: onViewAllOut),
      ]);
    });
  }
}

class _RecentInCard extends StatelessWidget {
  final List<StockInRecord> records;
  final DateFormat dateFmt;
  final VoidCallback? onViewAll;
  const _RecentInCard({required this.records, required this.dateFmt, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return _RecentCard(
      title: 'Recent Stock In',
      accentColor: AppColors.good,
      emptyMessage: 'No recent stock-in records.',
      onViewAll: onViewAll,
      rows: records.map((r) => _RecentRow2(
        item: r.itemName ?? '-',
        qty: '+${r.quantity}',
        qtyColor: AppColors.good,
        date: dateFmt.format(r.stockInDate),
      )).toList(),
    );
  }
}

class _RecentOutCard extends StatelessWidget {
  final List<StockOutRecord> records;
  final DateFormat dateFmt;
  final VoidCallback? onViewAll;
  const _RecentOutCard({required this.records, required this.dateFmt, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return _RecentCard(
      title: 'Recent Stock Out',
      accentColor: AppColors.out,
      emptyMessage: 'No recent stock-out records.',
      onViewAll: onViewAll,
      rows: records.map((r) => _RecentRow2(
        item: r.itemName ?? '-',
        qty: '-${r.quantity}',
        qtyColor: AppColors.out,
        date: dateFmt.format(r.stockOutDate),
      )).toList(),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final String emptyMessage;
  final List<_RecentRow2> rows;
  final VoidCallback? onViewAll;
  const _RecentCard({
    required this.title,
    required this.accentColor,
    required this.emptyMessage,
    required this.rows,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
            const SizedBox(width: 8),
            _ViewAllLink(onTap: onViewAll),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Column headers
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: const [
            Expanded(child: Text('Item',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted))),
            SizedBox(width: 40,
                child: Text('Qty', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.textMuted))),
            SizedBox(width: 12),
            Text('Date',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),

        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(emptyMessage,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            ),
          )
        else
          ...rows.map((r) => _buildRow(r)).toList(),

        const SizedBox(height: 6),
      ]),
    );
  }

  Widget _buildRow(_RecentRow2 r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.scaffold,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.inventory_2_outlined,
              size: 15, color: AppColors.textMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(r.item,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        SizedBox(
          width: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: r.qtyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(r.qty,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: r.qtyColor)),
          ),
        ),
        const SizedBox(width: 12),
        Text(r.date,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _ViewAllLink extends StatelessWidget {
  final VoidCallback? onTap;
  const _ViewAllLink({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text('View All',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _RecentRow2 {
  final String item, qty, date;
  final Color qtyColor;
  const _RecentRow2({
    required this.item,
    required this.qty,
    required this.qtyColor,
    required this.date,
  });
}

// ── Low Stock Alerts ──────────────────────────────────────────────────────────
class _LowStockCard extends StatelessWidget {
  final List<StockBalance> items;
  final VoidCallback? onViewAll;
  const _LowStockCard({required this.items, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                  color: AppColors.low,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 10),
            const Text('Low Stock Alerts',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const Spacer(),
            _ViewAllLink(onTap: onViewAll),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Table header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: const [
            Expanded(flex: 3, child: Text('Item',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted))),
            Flexible(flex: 1, child: Text('Stock', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted))),
            SizedBox(width: 8),
            Flexible(flex: 1, child: Text('Reorder', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted))),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),

        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 40, color: AppColors.good),
                SizedBox(height: 8),
                Text('All items are well stocked!',
                    style: TextStyle(color: AppColors.textMuted)),
              ]),
            ),
          )
        else
          ...items.take(6).map((b) {
            final color = b.currentBalance <= 0
                ? AppColors.out
                : AppColors.low;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        size: 16, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.itemName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(b.categoryName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ]),
                  ),
                  Flexible(
                    flex: 1,
                    child: Center(
                      child: Text('${b.currentBalance}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: Center(
                      child: Text('${b.reorderLevel}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
                    ),
                  ),
                ]),
              ),
              if (b != items.take(6).last)
                const Divider(height: 1, color: AppColors.border),
            ]);
          }).toList(),

        const SizedBox(height: 6),
      ]),
    );
  }
}
