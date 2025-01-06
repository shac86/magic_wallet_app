import 'package:flutter/material.dart';
import 'package:magic_wallet_app/home.dart';
import 'package:magic_wallet_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _handleLogin() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  final user = await _authService.registerOrLogin(email, password);

  if (user != null) {
    String? wallet = await _authService.getWalletAddress(user.uid);
    if (wallet == null) {
      wallet = await _authService.getWalletWithMagic(email);
      if (wallet != null) {
        await _authService.saveWalletAddress(user.uid, wallet);
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(email: email, wallet: wallet),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login with magic')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Enter email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Enter password'),
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
}
