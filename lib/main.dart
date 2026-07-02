import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/home_shell.dart';

void main() => runApp(const MiniInventoryApp());

class MiniInventoryApp extends StatelessWidget {
  const MiniInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hardware Inventory System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeShell(),
    );
  }
}
