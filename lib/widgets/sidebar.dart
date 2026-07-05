import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

const navItems = <NavItem>[
  NavItem(Icons.dashboard_rounded,       'Dashboard'),
  NavItem(Icons.category_rounded,        'Categories'),
  NavItem(Icons.local_shipping_rounded,  'Suppliers'),
  NavItem(Icons.inventory_2_rounded,     'Items'),
  NavItem(Icons.login_rounded,           'Stock In'),
  NavItem(Icons.logout_rounded,          'Stock Out'),
  NavItem(Icons.bar_chart_rounded,       'Reports'),
  NavItem(Icons.warning_amber_rounded,   'Low Stock'),
  NavItem(Icons.settings_rounded,        'Settings'),
];

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const Sidebar({super.key, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E0A4E), Color(0xFF2E1065)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handyman_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hardware Store',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('Inventory System',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ],
              ),
            ]),
          ),

          // ── Nav items ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, i) {
                final selected = i == selectedIndex;
                final item = navItems[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      splashColor: Colors.white12,
                      highlightColor: Colors.white10,
                      onTap: () => onSelect(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        child: Row(children: [
                          Icon(item.icon,
                              size: 20,
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white70),
                          const SizedBox(width: 12),
                          Text(item.label,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.white70)),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          const Divider(color: Colors.white12, height: 1),

          // ── User footer ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Store Admin',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text('admin@hardware.lk',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
