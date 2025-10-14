import 'package:flutter/material.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Color(0xFF3498db)),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  context,
                  'New Monitoring Form',
                  Icons.add_circle,
                  Colors.green,
                  () => Navigator.pushNamed(context, '/create_form'),
                ),
                _buildActionCard(
                  context,
                  'View All Forms',
                  Icons.list_alt,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/monitoring_forms'),
                ),
                _buildActionCard(
                  context,
                  'Statistics',
                  Icons.analytics,
                  Colors.orange,
                  () => Navigator.pushNamed(context, '/statistics'),
                ),
                _buildActionCard(
                  context,
                  'Store Performance',
                  Icons.store,
                  Colors.purple,
                  () => Navigator.pushNamed(context, '/store_performance'),
                ),
                _buildActionCard(
                  context,
                  'Export Data',
                  Icons.download,
                  Colors.teal,
                  () => Navigator.pushNamed(context, '/export_data'),
                ),
                _buildActionCard(
                  context,
                  'Templates',
                  Icons.description,
                  Colors.indigo,
                  () => Navigator.pushNamed(context, '/templates'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
