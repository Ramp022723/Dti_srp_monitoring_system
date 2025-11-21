import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RetailerManagementPage extends StatefulWidget {
  const RetailerManagementPage({super.key});

  @override
  State<RetailerManagementPage> createState() => _RetailerManagementPageState();
}

class _RetailerManagementPageState extends State<RetailerManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form fields
  final TextEditingController _storeName = TextEditingController();
  final TextEditingController _ownerName = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _description = TextEditingController();
  int? _locationId;

  bool _isLoading = false;
  List<Map<String, dynamic>> _retailers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRetailers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _storeName.dispose();
    _ownerName.dispose();
    _username.dispose();
    _password.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadRetailers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.getRetailers(limit: 50, search: _searchController.text.trim());
    if (!mounted) return;

    if (result['status'] == 'success') {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final list = (data['retailers'] as List?) ?? (data['data'] as List?);
      setState(() {
        _retailers = (list ?? []).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'] ?? 'Failed to load retailers';
        _isLoading = false;
      });
    }
  }

  Future<void> _onAddRetailer() async {
    _storeName.clear();
    _ownerName.clear();
    _username.clear();
    _password.clear();
    _email.clear();
    _phone.clear();
    _address.clear();
    _description.clear();
    _locationId = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: controller,
              children: [
                const Text(
                  'Add Retailer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildTextField(_storeName, label: 'Store Name', required: true),
                _buildTextField(_ownerName, label: 'Owner Name', required: true),
                _buildTextField(_username, label: 'Username', required: true),
                _buildTextField(_password, label: 'Password', required: true, obscure: true),
                _buildLocationField(),
                _buildTextField(_email, label: 'Email'),
                _buildTextField(_phone, label: 'Phone'),
                _buildTextField(_address, label: 'Address'),
                _buildTextField(_description, label: 'Description', maxLines: 3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitCreateRetailer,
                        child: const Text('Create Retailer'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitCreateRetailer() async {
    if (!_formKey.currentState!.validate() || _locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.adminCreateRetailer(
      storeName: _storeName.text.trim(),
      ownerName: _ownerName.text.trim(),
      username: _username.text.trim(),
      password: _password.text,
      locationId: _locationId!,
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['status'] == 'success') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Retailer created'), backgroundColor: Colors.green),
      );
      await _loadRetailers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to create retailer'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildTextField(
    TextEditingController controller, {
    required String label,
    bool required = false,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLocationField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        value: _locationId,
        items: const [
          DropdownMenuItem(value: 1, child: Text('Bago City')), // Example; replace with API-fed locations if available
        ],
        decoration: const InputDecoration(
          labelText: 'Location',
          border: OutlineInputBorder(),
        ),
        onChanged: (v) => setState(() => _locationId = v),
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRetailers,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddRetailer,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadRetailers,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _retailers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = _retailers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.store)),
                        title: Text(r['store_name']?.toString() ?? r['retailer_name']?.toString() ?? 'Retailer'),
                        subtitle: Text(r['username']?.toString() ?? r['owner_name']?.toString() ?? ''),
                      );
                    },
                  ),
                ),
    );
  }
}


