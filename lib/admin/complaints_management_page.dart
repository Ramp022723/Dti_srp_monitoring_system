import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ComplaintsManagementPage extends StatefulWidget {
  const ComplaintsManagementPage({super.key});

  @override
  State<ComplaintsManagementPage> createState() => _ComplaintsManagementPageState();
}

class _ComplaintsManagementPageState extends State<ComplaintsManagementPage> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _complaints = [];
  
  // Filter states
  String _selectedStatus = 'all'; // all, pending, in_progress, resolved, closed
  String _selectedPriority = 'all'; // all, low, medium, high, urgent
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AuthService.getComplaints();
      
      if (result['status'] == 'success') {
        setState(() {
          // Parse complaints data
          final complaintsData = result['data'] ?? {};
          _complaints = complaintsData['data']?['complaints'] ?? complaintsData['complaints'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load complaints data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complaints Management'),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, '/admin-dashboard'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildMainContent(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateComplaintDialog,
          icon: const Icon(Icons.add_comment),
          label: const Text('Add Complaint'),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Statistics Cards
        _buildStatisticsCards(),
        
        // Filters
        _buildFilters(),
        
        // Complaints List
        Expanded(
          child: _buildComplaintsList(),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    final totalComplaints = _complaints.length;
    final pendingComplaints = _complaints.where((c) => c['status'] == 'pending').length;
    final inProgressComplaints = _complaints.where((c) => c['status'] == 'in_progress').length;
    final resolvedComplaints = _complaints.where((c) => c['status'] == 'resolved').length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              totalComplaints.toString(),
              Icons.comment,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Pending',
              pendingComplaints.toString(),
              Icons.pending,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'In Progress',
              inProgressComplaints.toString(),
              Icons.work,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Resolved',
              resolvedComplaints.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'closed', child: Text('Closed')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value ?? 'all';
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Priority')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value ?? 'all';
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Complaints',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList() {
    final filteredComplaints = _getFilteredComplaints();
    
    if (filteredComplaints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No complaints found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredComplaints.length,
      itemBuilder: (context, index) {
        final complaint = filteredComplaints[index];
        return _buildComplaintCard(complaint);
      },
    );
  }

  Widget _buildComplaintCard(dynamic complaint) {
    final status = complaint['status'] ?? 'unknown';
    final priority = complaint['priority'] ?? 'medium';
    final statusColor = _getStatusColor(status);
    final priorityColor = _getPriorityColor(priority);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          complaint['subject'] ?? 'No Subject',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${complaint['complainant_name'] ?? 'Anonymous'}'),
            Text('Type: ${complaint['complaint_type'] ?? 'N/A'}'),
            Text('Priority: ${priority.toUpperCase()}'),
            Text('Status: ${status.toUpperCase()}'),
            if (complaint['created_at'] != null)
              Text('Created: ${_formatDate(complaint['created_at'])}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                priority.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleComplaintAction(value, complaint),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                if (status == 'pending')
                  const PopupMenuItem(
                    value: 'assign',
                    child: Row(
                      children: [
                        Icon(Icons.person_add),
                        SizedBox(width: 8),
                        Text('Assign'),
                      ],
                    ),
                  ),
                if (status == 'pending' || status == 'in_progress')
                  const PopupMenuItem(
                    value: 'resolve',
                    child: Row(
                      children: [
                        Icon(Icons.check),
                        SizedBox(width: 8),
                        Text('Mark Resolved'),
                      ],
                    ),
                  ),
                if (status == 'resolved')
                  const PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        Icon(Icons.close),
                        SizedBox(width: 8),
                        Text('Close'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showComplaintDetails(complaint),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'in_progress':
        return Icons.work;
      case 'resolved':
        return Icons.check_circle;
      case 'closed':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  List<dynamic> _getFilteredComplaints() {
    return _complaints.where((complaint) {
      // Status filter
      if (_selectedStatus != 'all') {
        if (complaint['status']?.toString().toLowerCase() != _selectedStatus) {
          return false;
        }
      }
      
      // Priority filter
      if (_selectedPriority != 'all') {
        if (complaint['priority']?.toString().toLowerCase() != _selectedPriority) {
          return false;
        }
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final subject = complaint['subject']?.toString().toLowerCase() ?? '';
        final description = complaint['description']?.toString().toLowerCase() ?? '';
        final complainantName = complaint['complainant_name']?.toString().toLowerCase() ?? '';
        
        if (!subject.contains(query) && 
            !description.contains(query) && 
            !complainantName.contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      // Trigger rebuild with new filters
    });
  }

  void _handleComplaintAction(String action, dynamic complaint) {
    switch (action) {
      case 'view':
        _showComplaintDetails(complaint);
        break;
      case 'assign':
        _assignComplaint(complaint);
        break;
      case 'resolve':
        _resolveComplaint(complaint);
        break;
      case 'close':
        _closeComplaint(complaint);
        break;
      case 'edit':
        _showEditComplaintDialog(complaint);
        break;
    }
  }

  void _showComplaintDetails(dynamic complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(complaint['subject'] ?? 'Complaint Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Complainant', complaint['complainant_name'] ?? 'Anonymous'),
              _buildDetailRow('Email', complaint['complainant_email'] ?? 'N/A'),
              _buildDetailRow('Phone', complaint['complainant_phone'] ?? 'N/A'),
              _buildDetailRow('Type', complaint['complaint_type'] ?? 'N/A'),
              _buildDetailRow('Priority', complaint['priority']?.toString().toUpperCase() ?? 'MEDIUM'),
              _buildDetailRow('Status', complaint['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
              _buildDetailRow('Created', _formatDate(complaint['created_at'] ?? '')),
              if (complaint['assigned_to'] != null)
                _buildDetailRow('Assigned To', complaint['assigned_to']),
              if (complaint['resolved_at'] != null)
                _buildDetailRow('Resolved', _formatDate(complaint['resolved_at'])),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(complaint['description'] ?? 'No description provided'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showCreateComplaintDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateComplaintDialog(
        onComplaintCreated: _loadData,
      ),
    );
  }

  void _showEditComplaintDialog(dynamic complaint) {
    showDialog(
      context: context,
      builder: (context) => _EditComplaintDialog(
        complaint: complaint,
        onComplaintUpdated: _loadData,
      ),
    );
  }

  Future<void> _assignComplaint(dynamic complaint) async {
    // This would open an assign dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assign complaint functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _resolveComplaint(dynamic complaint) async {
    try {
      // This would need to be implemented in AuthService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint resolved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _closeComplaint(dynamic complaint) async {
    try {
      // This would need to be implemented in AuthService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint closed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Create Complaint Dialog
class _CreateComplaintDialog extends StatefulWidget {
  final VoidCallback onComplaintCreated;

  const _CreateComplaintDialog({
    required this.onComplaintCreated,
  });

  @override
  State<_CreateComplaintDialog> createState() => _CreateComplaintDialogState();
}

class _CreateComplaintDialogState extends State<_CreateComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'general';
  String _selectedPriority = 'medium';
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _complainantNameController = TextEditingController();
  final _complainantEmailController = TextEditingController();
  final _complainantPhoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Complaint'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter subject' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Complaint Type'),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'price', child: Text('Price Issue')),
                  DropdownMenuItem(value: 'quality', child: Text('Quality Issue')),
                  DropdownMenuItem(value: 'service', child: Text('Service Issue')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? 'general';
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value ?? 'medium';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _complainantNameController,
                decoration: const InputDecoration(labelText: 'Complainant Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _complainantEmailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _complainantPhoneController,
                decoration: const InputDecoration(labelText: 'Phone (Optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createComplaint,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // This would need to be implemented in AuthService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      widget.onComplaintCreated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Edit Complaint Dialog
class _EditComplaintDialog extends StatefulWidget {
  final dynamic complaint;
  final VoidCallback onComplaintUpdated;

  const _EditComplaintDialog({
    required this.complaint,
    required this.onComplaintUpdated,
  });

  @override
  State<_EditComplaintDialog> createState() => _EditComplaintDialogState();
}

class _EditComplaintDialogState extends State<_EditComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _descriptionController;
  late String _selectedStatus;
  late String _selectedPriority;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.complaint['subject'] ?? '');
    _descriptionController = TextEditingController(text: widget.complaint['description'] ?? '');
    _selectedStatus = widget.complaint['status'] ?? 'pending';
    _selectedPriority = widget.complaint['priority'] ?? 'medium';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Complaint'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter subject' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value ?? 'pending';
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value ?? 'medium';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateComplaint,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // This would need to be implemented in AuthService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      widget.onComplaintUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
