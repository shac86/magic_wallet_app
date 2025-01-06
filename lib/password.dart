import 'package:flutter/material.dart';
import 'package:magic_wallet_app/home.dart';
import 'package:magic_wallet_app/services/auth_service.dart';

class PasswordScreen extends StatefulWidget {
  final String email;

  const PasswordScreen({super.key, required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login with magic'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 95),
                  Text('Unknown user', style: TextStyle(fontSize: 24.0)),
                  SizedBox(height: 95),
                  Text('Login with magic', style: TextStyle(fontSize: 20.0)),
                  SizedBox(height: 35),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Enter password',
                      hintText: 'Enter password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleLogin,
                    child: Text('Submit'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty || password.length < 6) {
      _showError('The password must be at least 6 characters long.');
      return;
    }

    try {
      final authService = AuthService();
      final user = await authService.registerOrLogin(widget.email, password);
      if (user != null) {
        final wallet = await authService.getWalletAddress(user.uid) ??
            await authService.getWalletWithMagic(widget.email);
        await authService.saveWalletAddress(user.uid, wallet!);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(email: widget.email, wallet: wallet),
          ),
        );
      }
    } catch (e) {
      if (e.toString().contains('firebase_auth/invalid-credential')) {
        _showError(
            'The supplied auth credential is incorrect, malformed or has expired.');
      } else if (e.toString().contains('firebase_auth/user-not-found')) {
        _showError('User with this email not found.');
      } else {
        _showError('Error: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}