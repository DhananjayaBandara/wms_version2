import 'package:flutter/material.dart';
import 'package:frontend/screens/user_landing_page.dart';
import '../../services/api_service.dart';
import 'user_signup_screen.dart';
import 'user_profile_screen.dart';
import '../../widgets/app_footer.dart';

class UserSigninScreen extends StatefulWidget {
  const UserSigninScreen({super.key});

  @override
  State<UserSigninScreen> createState() => _UserSigninScreenState();
}

class _UserSigninScreenState extends State<UserSigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
    });
    try {
      final result = await ApiService.participantSignin(
        _nicController.text.trim(),
        _passwordController.text,
      );
      if (result != null && result['participant_id'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful'),
            backgroundColor: Colors.green,
          ),
        );
        final participantId = result['participant_id'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: participantId),
          ),
        );
      } else {
        _showErrorDialog(result?['error']?.toString() ?? 'Invalid credentials');
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
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => UserLandingPage()),
            );
          },
          tooltip: 'Back',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nicController,
                decoration: const InputDecoration(labelText: 'NIC'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
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
                    (v) =>
                        v == null || v.length < 8 ? 'Min 8 characters' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child:
                    _loading
                        ? const CircularProgressIndicator()
                        : const Text('Sign In'),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                "Don't have an account?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => UserSignupScreen()),
                  );
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
