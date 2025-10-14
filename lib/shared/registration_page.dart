import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  String? selectedRole;
  bool agreedToTerms = false;
  bool isDropdownOpen = false;

  // Consumer form controllers
  final _consumerFormKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _consumerPasswordController = TextEditingController();
  final TextEditingController _consumerConfirmPasswordController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedBarangay;

  // Retailer form controllers
  final _retailerFormKey = GlobalKey<FormState>();
  final TextEditingController _retailerUsernameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _retailerPasswordController = TextEditingController();
  final TextEditingController _retailerConfirmPasswordController = TextEditingController();

  final List<String> roles = [
    'Select your role',
    'Consumer',
    'Retailer'
  ];

  final List<String> _barangays = [
    'Abuanan', 'Alianza', 'Atipuluan', 'Bacong', 'Bagroy', 'Balingasag',
    'Binubuhan', 'Busay', 'Calumangan', 'Caridad', 'Don Jorge Araneta',
    'Dulao', 'Ilijan', 'Lag-asan', 'Ma-ao', 'Mailum', 'Malingin',
    'Napoles', 'Pacol', 'Población', 'Sagasa', 'Sampinit', 'Tabunan', 'Taloc'
  ];

  void handleRoleSelect(String role) {
    setState(() {
      selectedRole = role;
      isDropdownOpen = false;
    });
  }

  void handleCreateAccount() async {
    if (selectedRole == null || selectedRole == 'Select your role') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    // Validate specific form based on role
    bool isFormValid = false;
    if (selectedRole == 'Consumer') {
      isFormValid = _consumerFormKey.currentState?.validate() ?? false;
      if (isFormValid && _consumerPasswordController.text != _consumerConfirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords do not match"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (selectedRole == 'Retailer') {
      isFormValid = _retailerFormKey.currentState?.validate() ?? false;
      if (isFormValid && _retailerPasswordController.text != _retailerConfirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords do not match"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (!agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please agree to the Terms & Conditions and Privacy Policy')),
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
      Map<String, dynamic> result;
      
      if (selectedRole == 'Consumer') {
        // Register consumer
        result = await AuthService.registerConsumer(
          username: _usernameController.text.trim(),
          password: _consumerPasswordController.text,
          confirmPassword: _consumerConfirmPasswordController.text,
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          middleName: _middleNameController.text.trim(),
          gender: _selectedGender?.toLowerCase() ?? 'male',
          birthdate: _birthdateController.text,
          age: int.tryParse(_ageController.text) ?? 0,
          locationId: 1, // Default location ID - you can map barangay to location ID
        );
      } else if (selectedRole == 'Retailer') {
        // Register retailer
        result = await AuthService.registerRetailer(
          username: _retailerUsernameController.text.trim(),
          password: _retailerPasswordController.text,
          confirmPassword: _retailerConfirmPasswordController.text,
          registrationCode: _codeController.text.trim(),
        );
      } else {
        throw Exception('Invalid user type');
      }

      // Hide loading indicator
      Navigator.of(context).pop();

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '$selectedRole registered successfully!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B5CF6),
              Color(0xFF7C3AED),
              Color(0xFF6D28D9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Main Card Container
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Welcome Section (Top)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF374151),
                                Color(0xFF1F2937),
                                Color(0xFF111827),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Decorative circles
                              Positioned(
                                top: -10,
                                right: 20,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 30,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.purple[300]!.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              
                              // Main content
                              Column(
                                children: [
                                  // Animated Welcome Icon
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFA78BFA),
                                          Color(0xFF818CF8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(40),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.3),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_add,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Text(
                                    'Join Our Marketplace!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  Text(
                                    'Start your journey with us today. Create your account and unlock amazing features and possibilities.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[300],
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Form Section (Bottom)
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join our community and get started today',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Role Selection Label with Icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Select Role',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const Text(
                                    ' *',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Custom Dropdown
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isDropdownOpen = !isDropdownOpen;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedRole ?? 'Select your role',
                                        style: GoogleFonts.poppins(
                                          color: selectedRole != null &&
                                                  selectedRole != 'Select your role'
                                              ? Colors.black87
                                              : Colors.grey[500],
                                          fontSize: 16,
                                        ),
                                      ),
                                      Icon(
                                        isDropdownOpen
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: Colors.grey[500],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Dropdown Menu
                              if (isDropdownOpen)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: roles.map((role) {
                                      return InkWell(
                                        onTap: () => handleRoleSelect(role),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            border: role != roles.last
                                                ? Border(
                                                    bottom: BorderSide(
                                                      color: Colors.grey[200]!,
                                                      width: 1,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          child: Text(
                                            role,
                                            style: GoogleFonts.poppins(
                                              color: role == roles.first
                                                  ? Colors.grey[500]
                                                  : Colors.black87,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                              const SizedBox(height: 24),

                              // CONSUMER REGISTRATION FORM - Appears when Consumer is selected
                              if (selectedRole == 'Consumer')
                                _buildConsumerForm(),

                              // RETAILER REGISTRATION FORM - Appears when Retailer is selected  
                              if (selectedRole == 'Retailer')
                                _buildRetailerForm(),

                              // Add spacing only if a form is shown
                              if (selectedRole == 'Consumer' || selectedRole == 'Retailer')
                                const SizedBox(height: 24),

                              // Terms & Conditions Checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: agreedToTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        agreedToTerms = value!;
                                      });
                                    },
                                    activeColor: Colors.purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            height: 1.4,
                                          ),
                                          children: [
                                            const TextSpan(text: 'I agree to the '),
                                            TextSpan(
                                              text: 'Terms & Conditions',
                                              style: const TextStyle(
                                                color: Colors.purple,
                                                decoration: TextDecoration.underline,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  // Handle terms tap
                                                },
                                            ),
                                            const TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: const TextStyle(
                                                color: Colors.purple,
                                                decoration: TextDecoration.underline,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  // Handle privacy policy tap
                                                },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Create Account Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: handleCreateAccount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[900],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.person_add, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Create Account',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Sign In Link
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    children: [
                                      const TextSpan(text: 'Already have an account? '),
                                      TextSpan(
                                        text: 'Sign in here',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.pop(context);
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsumerForm() {
    return Form(
      key: _consumerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consumer Registration',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 16),
          
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
          _buildTextField(label: 'Password', controller: _consumerPasswordController, obscure: true),
          _buildTextField(label: 'Confirm Password', controller: _consumerConfirmPasswordController, obscure: true),
        ],
      ),
    );
  }

  Widget _buildRetailerForm() {
    return Form(
      key: _retailerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Retailer Registration',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildTextField(label: 'Username', controller: _retailerUsernameController),
          _buildTextField(label: 'Code', controller: _codeController),
          _buildTextField(label: 'Password', controller: _retailerPasswordController, obscure: true),
          _buildTextField(label: 'Confirm Password', controller: _retailerConfirmPasswordController, obscure: true),
        ],
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
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
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
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
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