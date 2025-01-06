import 'package:flutter/material.dart';
import 'package:magic_wallet_app/main.dart';
import 'package:magic_wallet_app/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final String email;
  final String? wallet;
  final AuthService _authService = AuthService();

  HomeScreen({super.key, required this.email, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Successful login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Text(
              'User logged in successfully',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            )),
            SizedBox(height: 16),
            Center(child: Text('Email: $email')),
            SizedBox(height: 8),
            Center(child: Text('Wallet address: ${wallet ?? "not found"}')),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _authService.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => MyApp()),
                      (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString()}")),
                    );
                  }
                },
                child: Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
