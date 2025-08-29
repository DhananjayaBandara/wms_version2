import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditUserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final int userId;
  const EditUserProfileScreen({
    super.key,
    required this.user,
    required this.userId,
  });

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;
  late TextEditingController _districtController;
  late TextEditingController _nicController;
  String? _gender;
  bool _loading = false;
  String? _error;

  List<dynamic> userTypes = [];
  int? selectedUserTypeId;
  List<String> requiredProperties = [];
  Map<String, dynamic> properties = {};

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

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user['name'] ?? '');
    _emailController = TextEditingController(text: user['email'] ?? '');
    _contactController = TextEditingController(
      text: user['contact_number'] ?? '',
    );
    _districtController = TextEditingController(text: user['district'] ?? '');
    _nicController = TextEditingController(text: user['nic'] ?? '');
    _gender = user['gender'];
    selectedUserTypeId =
        user['participant_type']?['id'] ?? user['participant_type_id'];
    // Load properties from user
    dynamic props = user['properties'];
    if (props is String) {
      try {
        properties =
            props.isNotEmpty
                ? Map<String, dynamic>.from(jsonDecode(props))
                : {};
      } catch (_) {}
    } else if (props is Map<String, dynamic>) {
      properties = props;
    }
    _loadUserTypes();
  }

  Future<void> _loadUserTypes() async {
    try {
      final types = await ApiService.getParticipantTypes();
      setState(() {
        userTypes = types;
      });
      if (selectedUserTypeId != null) {
        _loadRequiredProperties(selectedUserTypeId!);
      }
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
        // Ensure all required properties are present in the map
        for (final field in requiredProperties) {
          properties[field] = properties[field] ?? '';
        }
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load required fields";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || selectedUserTypeId == null) {
      _showErrorDialog('Please correct the errors in the form.');
      return;
    }
    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'contact_number': _contactController.text.trim(),
        'district': _districtController.text.trim(),
        'nic': _nicController.text.trim(),
        'gender': _gender,
        'participant_type_id': selectedUserTypeId,
        'properties': properties,
      };
      await ApiService.updateUserProfile(widget.userId, data);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _loading = false);
    }
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
        title: const Text('Edit Profile'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nicController,
                decoration: customInputDecoration('NIC'),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: customInputDecoration('Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: customInputDecoration('Email'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                    return 'Invalid email';
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: customInputDecoration('Contact Number'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^0\d{9}$').hasMatch(v)) {
                    return 'Must be 10 digits and start with 0';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: customInputDecoration('Gender'),
                items:
                    ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                onChanged: (val) => setState(() => _gender = val),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value:
                    _districtController.text.isNotEmpty
                        ? _districtController.text
                        : null,
                decoration: customInputDecoration('District'),
                items:
                    districts
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    _districtController.text = val ?? '';
                  });
                },
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
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
                  setState(() {
                    selectedUserTypeId = val;
                    if (val != null) _loadRequiredProperties(val);
                  });
                },
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ...requiredProperties.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: TextFormField(
                    initialValue: properties[field]?.toString() ?? '',
                    decoration: customInputDecoration(
                      field.replaceAll("_", " ").toUpperCase(),
                    ),
                    onChanged: (val) => properties[field] = val,
                    validator:
                        (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                child:
                    _loading
                        ? const CircularProgressIndicator()
                        : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
