import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: userController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dobController,
              decoration: const InputDecoration(labelText: 'DOB (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red)),
            if (_successMessage != null)
              Text(_successMessage!,
                  style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    final username = userController.text.trim();
    final password = passController.text.trim();
    final dob = dobController.text.trim();

    if (username.isEmpty || password.isEmpty || dob.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isLoading = true;
    });

    try {
      final res = await ApiService.post('register', {
        'username': username,
        'password': password,
        'dob': dob,
      });

      // Your API returns a success string or message.
      // If you want stricter check, adapt based on API response shape.
      setState(() {
        _successMessage = 'Registered successfully!';
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
