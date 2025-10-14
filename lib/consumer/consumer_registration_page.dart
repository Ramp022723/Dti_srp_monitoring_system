import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class ConsumerRegistrationPage extends StatefulWidget {
  const ConsumerRegistrationPage({super.key});

  @override
  State<ConsumerRegistrationPage> createState() =>
      _ConsumerRegistrationPageState();
}

class _ConsumerRegistrationPageState extends State<ConsumerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final List<String> _barangays = [
    'Abuanan', 'Alianza', 'Atipuluan', 'Bacong', 'Bagroy', 'Balingasag',
    'Binubuhan', 'Busay', 'Calumangan', 'Caridad', 'Don Jorge Araneta',
    'Dulao', 'Ilijan', 'Lag-asan', 'Ma-ao', 'Mailum', 'Malingin',
    'Napoles', 'Pacol', 'Población', 'Sagasa', 'Sampinit', 'Tabunan', 'Taloc'
  ];

  String? _selectedGender;
  String? _selectedBarangay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Consumer Registration',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 100),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Text(
                              'Create Consumer Account',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'Fill in your details to register',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            _buildTextField(label: 'Username', controller: _usernameController),
                            _buildTextField(label: 'First Name', controller: _firstNameController),
                            _buildTextField(label: 'Middle Name (optional)', controller: _middleNameController, required: false),
                            _buildTextField(label: 'Last Name', controller: _lastNameController),
                            _buildTextField(label: 'Suffix (optional)', controller: _suffixController, required: false),
                            _buildDropdown(
                              label: 'Gender',
                              value: _selectedGender,
                              items: ['Male', 'Female'],
                              onChanged: (val) => setState(() => _selectedGender = val),
                            ),
                            _buildDatePicker(label: 'Birthdate', controller: _birthdateController),
                            _buildTextField(label: 'Age', controller: _ageController, readOnly: true),
                            _buildTextField(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
                            _buildDropdown(
                              label: 'Barangay',
                              value: _selectedBarangay,
                              items: _barangays,
                              onChanged: (val) => setState(() => _selectedBarangay = val),
                            ),
                            _buildTextField(label: 'Password', controller: _passwordController, obscure: true),
                            _buildTextField(label: 'Confirm Password', controller: _confirmPasswordController, obscure: true),
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    if (_passwordController.text != _confirmPasswordController.text) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Passwords do not match"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Show loading indicator
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );

                                    try {
                                      // Register consumer using AuthService
                                      final result = await AuthService.registerConsumer(
                                        username: _usernameController.text.trim(),
                                        password: _passwordController.text,
                                        confirmPassword: _confirmPasswordController.text,
                                        email: _emailController.text.trim(),
                                        firstName: _firstNameController.text.trim(),
                                        lastName: _lastNameController.text.trim(),
                                        middleName: _middleNameController.text.trim(),
                                        gender: _selectedGender?.toLowerCase() ?? 'male',
                                        birthdate: _birthdateController.text,
                                        age: int.tryParse(_ageController.text) ?? 0,
                                        locationId: 1, // Default location ID - you can map barangay to location ID
                                      );

                                      // Hide loading indicator
                                      Navigator.of(context).pop();

                                      if (result['status'] == 'success') {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(result['message'] ?? "Consumer registered successfully!"),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        
                                        // Navigate back to login after successful registration
                                        Future.delayed(const Duration(seconds: 2), () {
                                          Navigator.popUntil(context, (route) => route.isFirst);
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(result['message'] ?? 'Registration failed'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Hide loading indicator
                                      Navigator.of(context).pop();
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Registration failed: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Register as Consumer',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool required = true,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : null,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) => val == null || val.isEmpty ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            controller.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
            
            // Calculate and set age automatically
            final now = DateTime.now();
            int age = now.year - date.year;
            if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
              age--;
            }
            _ageController.text = age.toString();
          }
        },
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }
}
