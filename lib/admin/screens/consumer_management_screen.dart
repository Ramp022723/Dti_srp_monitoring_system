import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/user_card.dart';

class ConsumerManagementScreen extends StatefulWidget {
  const ConsumerManagementScreen({super.key});

  @override
  State<ConsumerManagementScreen> createState() => _ConsumerManagementScreenState();
}

class _ConsumerManagementScreenState extends State<ConsumerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadConsumers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadConsumers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    await userProvider.fetchConsumers(authToken: authProvider.authToken);
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
                hintText: 'Search consumers...',
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
          
          // Consumers List
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (userProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (userProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          userProvider.error!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        ElevatedButton(
                          onPressed: _loadConsumers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                final consumers = _searchQuery.isEmpty
                    ? userProvider.consumers
                    : userProvider.searchConsumers(_searchQuery);
                
                if (consumers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.lightTextMuted,
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No consumers found'
                              : 'No consumers match your search',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _loadConsumers,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                    ),
                    itemCount: consumers.length,
                    itemBuilder: (context, index) {
                      final consumer = consumers[index];
                      return ConsumerCard(
                        consumer: consumer,
                        onView: () => _viewConsumer(consumer),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _viewConsumer(User consumer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(consumer.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Username', consumer.username),
            _buildInfoRow('Email', consumer.email ?? 'Not provided'),
            _buildInfoRow('Type', consumer.adminTypeDisplay),
            _buildInfoRow('Joined', consumer.createdAt?.toString().split(' ')[0] ?? 'Unknown'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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

class ConsumerCard extends StatelessWidget {
  final User consumer;
  final VoidCallback? onView;
  
  const ConsumerCard({
    super.key,
    required this.consumer,
    this.onView,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            consumer.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          consumer.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(consumer.username),
            if (consumer.email != null)
              Text(
                consumer.email!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTextMuted,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: onView,
        ),
        onTap: onView,
      ),
    );
  }
}
