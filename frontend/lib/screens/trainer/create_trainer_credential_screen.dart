import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CreateTrainerCredentialScreen extends StatefulWidget {
  final int trainerId;
  const CreateTrainerCredentialScreen({required this.trainerId, super.key});

  @override
  State<CreateTrainerCredentialScreen> createState() =>
      _CreateTrainerCredentialScreenState();
}

class _CreateTrainerCredentialScreenState
    extends State<CreateTrainerCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true; // <-- Add this

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.createTrainerCredential(
        trainerId: widget.trainerId,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trainer credential created successfully!'),
        ),
      );
      Navigator.pop(context, true); // Go back or navigate as needed
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trainer Credential')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Enter username' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                    obscureText: _obscurePassword,
                    validator:
                        (v) => v == null || v.isEmpty ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Create Credential'),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
