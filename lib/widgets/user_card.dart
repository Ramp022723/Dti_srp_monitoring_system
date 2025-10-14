import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  
  const UserCard({
    super.key,
    required this.user,
    this.onEdit,
    this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getUserTypeColor(),
          child: Text(
            user.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.username),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getUserTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.adminTypeDisplay,
                    style: TextStyle(
                      color: _getUserTypeColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (user.email != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.email!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTextMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
                tooltip: 'Edit User',
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
                tooltip: 'Delete User',
                color: AppTheme.errorColor,
              ),
          ],
        ),
        onTap: () => _showUserDetails(context),
      ),
    );
  }
  
  Color _getUserTypeColor() {
    switch (user.adminType) {
      case 'admin':
        return AppTheme.primaryColor;
      case 'barangay_admin':
        return AppTheme.successColor;
      case 'consumer':
        return AppTheme.infoColor;
      case 'retailer':
        return AppTheme.warningColor;
      default:
        return AppTheme.lightTextMuted;
    }
  }
  
  void _showUserDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Username', user.username),
            _buildInfoRow('Full Name', user.fullName),
            _buildInfoRow('Email', user.email ?? 'Not provided'),
            _buildInfoRow('Type', user.adminTypeDisplay),
            _buildInfoRow('Created', user.createdAt?.toString().split(' ')[0] ?? 'Unknown'),
            _buildInfoRow('Last Updated', user.updatedAt?.toString().split(' ')[0] ?? 'Unknown'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (onEdit != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onEdit!();
              },
              child: const Text('Edit'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
