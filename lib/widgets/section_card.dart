import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // size to content, not bounded parent
        children: [
          // ── Responsive header: title left, action right (wraps on narrow) ──
          LayoutBuilder(builder: (ctx, c) {
            final titleWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ],
              ],
            );

            if (action == null) return titleWidget;

            // Wide enough: row layout
            if (c.maxWidth > 380) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: 12),
                  action!,
                ],
              );
            }

            // Narrow: stack vertically
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleWidget,
                const SizedBox(height: 10),
                action!,
              ],
            );
          }),

          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
