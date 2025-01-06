import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final magic = Magic.instance;

  static final AuthService _singleton = AuthService._internal();
  factory AuthService() {
    return _singleton;
  }
  AuthService._internal();

  String deviceId = 'unknown-device-id'; // Store device ID for global access

  Future<User?> registerOrLogin(String email, String password) async {
    try {
      print("Create user with email: $email");
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("User registered: ${userCredential.user?.uid}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print("Email is already in use, log in...");
        return await _loginUser(email, password);
      } else {
        print("Registration error: ${e.message}");
        rethrow;
      }
    }
  }

  Future<User?> _loginUser(String email, String password) async {
    try {
      print("Log in with email: $email");
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Log in: ${userCredential.user?.email}");
      return userCredential.user;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<String?> getWalletAddress(String uid) async {
    try {
      print("Get wallet address from Firestore with uuid: $uid");
      final doc = await _db.collection('users').doc(uid).get();
      final addr = doc.data()?['wallet'];
      print("wallet address from Firestore is: $addr");
      return addr;
    } catch (e) {
      print("Error getting wallet address: $e");
      return null;
    }
  }

  Future<void> saveWalletAddress(String uid, String wallet) async {
    try {
      print("Save wallet address to Firestore with uid: $uid");
      await _db.collection('users').doc(uid).set({
        'wallet': wallet,
      });
    } catch (e) {
      print("Error saving wallet address: $e");
    }
  }

  // Magic.link
  Future<String?> getWalletWithMagic(String email) async {
    try {
      print("Get wallet address from Magic.link for email: $email");
      var token = await magic.auth.loginWithEmailOTP(email: email);
      print("token received: $token");

      final metadata = await Magic.instance.user.getInfo();
      print("wallet address from Magic.link: ${metadata.publicAddress}");
      return metadata.publicAddress;
    } catch (e) {
      print("Magic link error: $e");
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await Magic.instance.user.logout();
      print("The user has logged out.");
    } catch (e) {
      print("Exit error: $e");
    }
  }

  Future<String> signInWithDeviceId() async {
    print("Starting signInWithDeviceId");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    deviceId =
        await _getDeviceId(prefs); // Always retrieves or sets a device ID
    print("Retrieved device ID: $deviceId");

    // Start the sign-in process asynchronously
    _signInFirebaseUser(deviceId).then((_) async {
      // Check internet connection before handling messaging token
      if (await _checkInternetConnection()) {
        await _handleMessagingToken();
        print("Handled messaging token");
      } else {
        print("No internet connection, skipping messaging token operations.");
      }
    });

    return deviceId;
  }

  Future<String> _getDeviceId(SharedPreferences prefs) async {
    print("Retrieving device ID");
    String? localDeviceId = prefs.getString('device_id');
    if (localDeviceId != null) {
      print("Found cached device ID: $localDeviceId");
      return localDeviceId; // Use cached device ID
    } else {
      print("No cached device ID found, fetching from device");
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        localDeviceId = iosInfo.identifierForVendor ?? 'default-ios-device-id';
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        localDeviceId = androidInfo.id ?? 'default-android-device-id';
      }
      localDeviceId =
          localDeviceId ?? 'unknown-device-id'; // Fallback if still null
      await prefs.setString('device_id', localDeviceId); // Save the device ID
      print("Fetched and saved device ID: $localDeviceId");
      return localDeviceId;
    }
  }

  Future<void> _signInFirebaseUser(String deviceId) async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      User? user = userCredential.user;
      if (user != null) {
        bool isConnected = await _checkInternetConnection();
        if (isConnected) {
          print(
              "Internet connection available, performing Firestore operations.");
          var existingUser = await _db
              .collection('users')
              .where('deviceId', isEqualTo: deviceId)
              .limit(1)
              .get();
          if (existingUser.docs.isEmpty) {
            await _db.collection('users').doc(user.uid).set({
              'deviceId': deviceId,
              'lastLogin': FieldValue.serverTimestamp()
            });
          } else {
            await _db
                .collection('users')
                .doc(existingUser.docs.first.id)
                .update({'lastLogin': FieldValue.serverTimestamp()});
          }
        } else {
          print("No internet connection, skipping Firestore operations.");
        }
      }
    } catch (e) {
      print("Error signing in anonymously: $e");
    }
  }

  Future<void> _handleMessagingToken() async {
    try {
      bool isConnected = await _checkInternetConnection();
      if (isConnected) {
        print(
            "Internet connection available, performing FCM token operations.");

        if (Platform.isIOS) {
          // Ensure the APNS token is set before requesting the FCM token
          await _messaging.requestPermission();
          String? apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            print("APNS token not available.");
            return;
          }
        }

        String? token = await _messaging.getToken();
        if (token != null) {
          _db.collection('users').doc(_auth.currentUser?.uid).set({
            'fcmToken': token,
          }, SetOptions(merge: true));
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
            _db.collection('users').doc(_auth.currentUser?.uid).set({
              'fcmToken': token,
            }, SetOptions(merge: true));
          });
        }
      } else {
        print("No internet connection, skipping FCM token operations.");
      }
    } catch (e) {
      print("Error handling FCM token: $e");
    }
  }

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    // Further check if we can actually make a network request
    try {
      final result = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      if (result.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Add this method to get the current user
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
