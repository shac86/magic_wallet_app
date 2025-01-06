import 'package:flutter/material.dart';
import 'package:magic_wallet_app/home.dart';
import 'package:magic_wallet_app/services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController =
      TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Unknown user', style: TextStyle(fontSize: 24.0)),
            SizedBox(height: 95),
            Text('Login with magic', style: TextStyle(fontSize: 20.0)),
            SizedBox(height: 35),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Enter email',
                hintText: 'Enter email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
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
              onPressed: () => _handleLogin(context, _emailController.text),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context, String email) async {
    final password = _passwordController.text.trim();
    if (password.isEmpty || password.length < 6) {
      _showError(context, 'The password must be at least 6 characters long.');
      return;
    }

    try {
      final authService = AuthService();
      final user = await authService.registerOrLogin(email, password);
      if (user != null) {
        final wallet = await authService.getWalletAddress(user.uid) ??
            await authService.getWalletWithMagic(email);
        await authService.saveWalletAddress(user.uid, wallet!);
        
        if (wallet != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(email: email, wallet: wallet),
            ),
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('firebase_auth/invalid-credential')) {
        _showError(context,
            'The supplied auth credential is incorrect, malformed or has expired.');
      } else if (e.toString().contains('firebase_auth/user-not-found')) {
        _showError(context, 'User with this email not found.');
      } else {
        _showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
