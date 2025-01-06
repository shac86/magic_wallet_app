import 'package:flutter/material.dart';
import 'package:magic_wallet_app/home.dart';
import 'package:magic_wallet_app/services/auth_service.dart';

class PasswordScreen extends StatelessWidget {
  final String email;
  final TextEditingController _passwordController = TextEditingController();

  PasswordScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
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

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(email: email, wallet: wallet),
                      ),
                    );
                  }
                } catch (e) {
                  if (e.toString().contains('firebase_auth/invalid-credential')) {
                    _showError(context, 'The supplied auth credential is incorrect, malformed or has expired.');
                  } else if (e.toString().contains('firebase_auth/user-not-found')) {
                    _showError(context, 'User with this email not found.');
                  } else {
                    _showError(context, 'Error: ${e.toString()}');
                  }
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}