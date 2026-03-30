// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETUP CHECKLIST (before running):
//
//  1. Run: flutterfire configure
//     → Generates lib/firebase_options.dart automatically
//     → Connects your Flutter app to Firebase project
//
//  2. In firebase_options.dart, enable:
//     • Authentication → Google Sign-In
//     • Cloud Firestore
//     • Firebase Messaging (for push notifications)
//
//  3. Add SHA-1 fingerprint in Firebase Console → Project Settings → Android app
//     Run: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
//
//  4. Add to android/app/build.gradle:
//     minSdkVersion 21
//
//  5. NO Google Maps API key needed — flutter_map uses OpenStreetMap (free!)
//
//  6. Firestore security rules (basic):
//     rules_version = '2';
//     service cloud.firestore {
//       match /databases/{database}/documents {
//         match /{document=**} {
//           allow read, write: if request.auth != null;
//         }
//       }
//     }
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  // Uncomment after running `flutterfire configure`:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  runApp(const GuardianApp());
}

class GuardianApp extends StatelessWidget {
  const GuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        return snap.data != null
            ? const ShellScreen()
            : const LoginScreen();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
                Icons.shield_rounded, color: AppColors.teal, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Guardian',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.teal)),
          const SizedBox(height: 28),
          const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
                color: AppColors.teal, strokeWidth: 2.5),
          ),
        ]),
      ),
    );
  }
}