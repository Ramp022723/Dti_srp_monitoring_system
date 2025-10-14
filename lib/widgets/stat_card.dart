import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

enum ChangeType { positive, negative, neutral }

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? change;
  final ChangeType? changeType;
  final VoidCallback? onTap;
  
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
    this.changeType,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  if (change != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getChangeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getChangeIcon(),
                            size: 12,
                            color: _getChangeColor(),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            change!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getChangeColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getChangeColor() {
    switch (changeType) {
      case ChangeType.positive:
        return AppTheme.successColor;
      case ChangeType.negative:
        return AppTheme.errorColor;
      case ChangeType.neutral:
        return AppTheme.lightTextMuted;
      default:
        return AppTheme.lightTextMuted;
    }
  }
  
  IconData _getChangeIcon() {
    switch (changeType) {
      case ChangeType.positive:
        return Icons.trending_up;
      case ChangeType.negative:
        return Icons.trending_down;
      case ChangeType.neutral:
        return Icons.trending_flat;
      default:
        return Icons.trending_flat;
    }
  }
}
