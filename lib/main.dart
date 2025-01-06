import 'package:flutter/material.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:magic_wallet_app/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  Magic.instance = Magic("pk_live_D6F25D16E5FFE589");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Stack(children: [LoginScreen(), Magic.instance.relayer]));
  }

}
