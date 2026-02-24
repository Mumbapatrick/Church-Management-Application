import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'authscreen.dart';
import 'firebase_options.dart';
import 'dashboard.dart';
import 'model/user.dart';

/// Helper class to load environment variables from .env or local.properties
class EnvConfig {
  static String? webClientId;

  static Future<void> load() async {
    try {
      // 1️⃣ Load from .env
      try {
        final envFile = File('.env');
        if (await envFile.exists()) {
          final lines = await envFile.readAsLines();
          for (var line in lines) {
            if (line.startsWith('WEB_CLIENT_ID=')) {
              webClientId = line.split('=')[1].trim();
              if (webClientId!.isNotEmpty) {
                print('✅ WEB_CLIENT_ID loaded from .env');
                return;
              }
            }
          }
          print('⚠️ WEB_CLIENT_ID not found in .env');
        }
      } catch (e) {
        print('⚠️ Failed to read .env: $e');
      }

      // 2️⃣ Fallback to local.properties on mobile/desktop only
      if (!kIsWeb) {
        final file = File('local.properties');
        if (await file.exists()) {
          final content = await file.readAsString();
          final match = RegExp(r'WEB_CLIENT_ID=(.*)').firstMatch(content);
          if (match != null) {
            webClientId = match.group(1)?.trim();
            if (webClientId!.isNotEmpty) {
              print('✅ WEB_CLIENT_ID loaded from local.properties');
              return;
            }
          }
        }
      }

      print('⚠️ WEB_CLIENT_ID not found in both .env and local.properties');
    } catch (e) {
      print('❌ Failed to load WEB_CLIENT_ID: $e');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before Firebase initialization
  await EnvConfig.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Church App',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay
    final user = _auth.currentUser;

    if (user != null) {
      await user.reload();
      final refreshedUser = _auth.currentUser;

      final bool isVerified =
          refreshedUser!.emailVerified || refreshedUser.phoneNumber != null;

      if (isVerified) {
        final safeName = (refreshedUser.displayName?.trim().isNotEmpty ?? false)
            ? refreshedUser.displayName!
            : "User";

        final safeEmail = (refreshedUser.email?.trim().isNotEmpty ?? false)
            ? refreshedUser.email!
            : "Unknown";

        final safePhone = (refreshedUser.phoneNumber?.trim().isNotEmpty ?? false)
            ? refreshedUser.phoneNumber!
            : "Unknown";

        final userModel = User(
          id: refreshedUser.uid,
          name: safeName,
          email: safeEmail,
          phone: safePhone,
          role: "member",
          location: '',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Dashboard(
              user: userModel,
              onNavigate: (screen) {},
              onLogout: () async {
                await _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => AuthScreen(onLogin: (_) {})),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please verify your email before logging in."),
            backgroundColor: Colors.red,
          ),
        );
        await _auth.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AuthScreen(onLogin: (_) {})),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen(onLogin: (_) {})),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[900],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.church, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Welcome to Church App",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
