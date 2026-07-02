import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_outlined, size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text('Settings',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Text('This feature is coming soon.',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
