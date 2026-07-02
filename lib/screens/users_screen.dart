import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text('User Management',
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
