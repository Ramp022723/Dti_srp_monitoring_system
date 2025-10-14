import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class ComplaintManagementScreen extends StatefulWidget {
  const ComplaintManagementScreen({super.key});

  @override
  State<ComplaintManagementScreen> createState() => _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState extends State<ComplaintManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadComplaints() async {
    // TODO: Implement complaint loading
    await Future.delayed(const Duration(seconds: 1));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search complaints...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Complaints List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadComplaints,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
                itemCount: 8, // Mock data
                itemBuilder: (context, index) {
                  return _buildComplaintCard(index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComplaintCard(int index) {
    final statuses = ['Pending', 'In Progress', 'Resolved', 'Closed'];
    final status = statuses[index % statuses.length];
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: const Icon(
            Icons.report_problem,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Complaint ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product quality issue reported'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${index + 1} day${index > 0 ? 's' : ''} ago',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () => _viewComplaint(index),
        ),
        onTap: () => _viewComplaint(index),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppTheme.warningColor;
      case 'In Progress':
        return AppTheme.infoColor;
      case 'Resolved':
        return AppTheme.successColor;
      case 'Closed':
        return AppTheme.lightTextMuted;
      default:
        return AppTheme.lightTextMuted;
    }
  }
  
  void _viewComplaint(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complaint ${index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', 'Product Quality Issue'),
            _buildInfoRow('Consumer', 'John Doe'),
            _buildInfoRow('Retailer', 'ABC Store'),
            _buildInfoRow('Product', 'Product ${index + 1}'),
            _buildInfoRow('Status', 'Pending'),
            _buildInfoRow('Date', '${index + 1} day${index > 0 ? 's' : ''} ago'),
            const SizedBox(height: 8),
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              'The product quality is not as expected. The item arrived damaged and does not match the description.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateComplaintStatus(index);
            },
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }
  
  void _updateComplaintStatus(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select new status:'),
            const SizedBox(height: 16),
            ...['Pending', 'In Progress', 'Resolved', 'Closed'].map((status) {
              return ListTile(
                title: Text(status),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement status update
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status updated to $status'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
            width: 80,
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
