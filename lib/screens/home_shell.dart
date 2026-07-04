import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/sidebar.dart';
import 'dashboard_screen.dart';
import 'categories_screen.dart';
import 'suppliers_screen.dart';
import 'items_screen.dart';
import 'stock_in_screen.dart';
import 'stock_out_screen.dart';
import 'stock_balance_screen.dart';
import 'users_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  // Incrementing this per-screen forces a full widget rebuild (new key →
  // dispose old state + initState on new state → fresh API load).
  final List<int> _refreshKeys = List.filled(10, 0);

  void _navigate(int newIndex) {
    setState(() {
      _refreshKeys[newIndex]++;   // bump key → triggers fresh load
      _index = newIndex;
    });
  }

  Widget _body() {
    switch (_index) {
      case 0:
        return DashboardScreen(key: ValueKey(_refreshKeys[0]));
      case 1:
        return CategoriesScreen(key: ValueKey(_refreshKeys[1]));
      case 2:
        return SuppliersScreen(key: ValueKey(_refreshKeys[2]));
      case 3:
        return ItemsScreen(key: ValueKey(_refreshKeys[3]));
      case 4:
        return StockInScreen(key: ValueKey(_refreshKeys[4]));
      case 5:
        return StockOutScreen(key: ValueKey(_refreshKeys[5]));
      case 6:
        return StockBalanceScreen(key: ValueKey(_refreshKeys[6]));
      case 7:
        return StockBalanceScreen(
            key: ValueKey(_refreshKeys[7]), lowStockOnly: true);
      case 8:
        return UsersScreen(key: ValueKey(_refreshKeys[8]));
      case 9:
        return SettingsScreen(key: ValueKey(_refreshKeys[9]));
      default:
        return DashboardScreen(key: ValueKey(_refreshKeys[0]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;

    final topBar = Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
            bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!wide)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                color: AppColors.textPrimary,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          const Flexible(
            child: Text(
              'Mini Inventory Management System',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const Spacer(),
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded),
                color: AppColors.textMuted,
                onPressed: () {},
              ),
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.out,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Admin dropdown
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary,
                  child: Text('A',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Admin',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                    Text('Administrator',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted)),
                  ],
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.textMuted),
              ],
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('My Profile')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
    );

    final content = Expanded(
      child: Column(
        children: [
          topBar,
          Expanded(
            child: ColoredBox(
              color: AppColors.scaffold,
              child: _body(),
            ),
          ),
        ],
      ),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            Sidebar(
                selectedIndex: _index,
                onSelect: _navigate),
            content,
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: Sidebar(
          selectedIndex: _index,
          onSelect: (i) {
            _navigate(i);
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(children: [topBar, Expanded(child: _body())]),
    );
  }
}
