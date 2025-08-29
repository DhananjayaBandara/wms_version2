import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/participant.dart';
import 'user_signin_screen.dart';
import '../../widgets/app_footer.dart';

class UserSignupScreen extends StatefulWidget {
  const UserSignupScreen({super.key});

  @override
  State<UserSignupScreen> createState() => _UserSignupScreenState();
}

class _UserSignupScreenState extends State<UserSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _properties = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = false;
  String? _error;

  List<dynamic> userTypes = [];
  int? selectedUserTypeId;
  List<String> requiredProperties = [];
  final List<String> districts = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
    'Galle',
    'Matara',
    'Hambantota',
    'Jaffna',
    'Kilinochchi',
    'Mannar',
    'Vavuniya',
    'Mullaitivu',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Monaragala',
    'Ratnapura',
    'Kegalle',
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _selectedGender;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _loadUserTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _nicController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserTypes() async {
    try {
      final types = await ApiService.getParticipantTypes();
      setState(() {
        userTypes = types;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load user types";
      });
    }
  }

  Future<void> _loadRequiredProperties(int typeId) async {
    try {
      final details = await ApiService.getRequiredFieldsForType(typeId);
      setState(() {
        requiredProperties = List<String>.from(details['required_fields']);
        _properties.clear();
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load required fields";
      });
    }
  }

  String? validateContactNumber(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final reg = RegExp(r'^0\d{9}$');
    if (!reg.hasMatch(value)) {
      return 'Contact number must be 10 digits and start with 0';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final reg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!reg.hasMatch(value)) {
      return 'Invalid email address';
    }
    return null;
  }

  String? validateNIC(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final regOld = RegExp(r'^\d{9}[vV]$');
    final regNew = RegExp(r'^\d{12}$');
    if (!regOld.hasMatch(value) && !regNew.hasMatch(value)) {
      return 'NIC must be 12 digits or 9 digits followed by V/v';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Validation Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || selectedUserTypeId == null) {
      _showErrorDialog('Please correct the errors in the form.');
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final participant = Participant(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        contactNumber: _contactController.text.trim(),
        nic: _nicController.text.trim(),
        district: _selectedDistrict ?? '',
        gender: _selectedGender ?? '',
        participantTypeId: selectedUserTypeId!,
        properties: Map<String, dynamic>.from(_properties),
      );
      final password = _passwordController.text.trim();

      final response = await ApiService.participantSignup(
        participant,
        password,
      );
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserSigninScreen()),
        );
      } else {
        final error = response['error'] ?? {};
        final errorMessage =
            error['detail'] ??
            error['message'] ??
            (error is Map ? error.toString() : 'Registration failed');
        _showErrorDialog('Registration failed: $errorMessage');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  InputDecoration customInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    constraints.maxWidth < 500 ? constraints.maxWidth : 500,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextFormField(
                        controller: _nameController,
                        decoration: customInputDecoration('Name'),
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: customInputDecoration('Email'),
                        validator: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactController,
                        decoration: customInputDecoration('Contact Number'),
                        validator: validateContactNumber,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: customInputDecoration('Gender'),
                        items:
                            ['Male', 'Female', 'Other']
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _selectedGender = val),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedUserTypeId,
                        decoration: customInputDecoration('User Type'),
                        items:
                            userTypes
                                .map(
                                  (type) => DropdownMenuItem<int>(
                                    value: type['id'],
                                    child: Text(type['name']),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() => selectedUserTypeId = val);
                          if (val != null) _loadRequiredProperties(val);
                        },
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      ...requiredProperties.map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: TextFormField(
                            decoration: customInputDecoration(
                              field.replaceAll("_", " ").toUpperCase(),
                            ),
                            onChanged: (val) => _properties[field] = val,
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: customInputDecoration('District'),
                        items:
                            districts
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _selectedDistrict = val),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nicController,
                        decoration: customInputDecoration('NIC'),
                        validator: validateNIC,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: customInputDecoration(
                          'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: validatePassword,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: customInputDecoration(
                          'Confirm Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: validateConfirmPassword,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child:
                            _loading
                                ? const CircularProgressIndicator()
                                : const Text('Sign Up'),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        "Already have an account?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserSigninScreen(),
                            ),
                          );
                        },
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
