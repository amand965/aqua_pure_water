import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/customer_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/splash/splash_animation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  String? initError;

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCysw8aEGMtIiE67fVVOGbo3rjKcqDNkvE',
          appId: '1:371541432832:web:bc86f189c9023a7bead6e5',
          messagingSenderId: '371541432832',
          projectId: 'meet-electronics-ac083',
          storageBucket: 'meet-electronics-ac083.firebasestorage.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    firebaseInitialized = true;
  } catch (e) {
    initError = e.toString();
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(MyApp(
    firebaseInitialized: firebaseInitialized,
    firebaseError: initError,
  ));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? firebaseError;

  const MyApp({
    super.key,
    required this.firebaseInitialized,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<CustomerProvider>(
          create: (_) => CustomerProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'ME Service Manager',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: firebaseInitialized
            ? const SplashAnimationScreen()
            : FirebaseConfigErrorScreen(errorMessage: firebaseError),
      ),
    );
  }
}

// Routes users based on Auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}

// Interactive configuration instructions display
class FirebaseConfigErrorScreen extends StatelessWidget {
  final String? errorMessage;
  const FirebaseConfigErrorScreen({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Configuration Needed'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 80,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Firebase Project Configuration Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Meet Electronics app stores records securely in the Firebase cloud. To run this app on your device, please link it to your Firebase Project:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Steps to Setup:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 8),
                    Text('1. Go to console.firebase.google.com'),
                    Text('2. Create a Firebase project named "Meet Electronics"'),
                    Text('3. Add an Android app with Package Name:'),
                    Text('   "com.meetelectronics.aqua_pure_water"', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('4. Download the "google-services.json" file'),
                    Text('5. Copy the file into your Flutter project inside:'),
                    Text('   "android/app/" directory', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Error Log:\n$errorMessage',
                  style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontFamily: 'monospace'),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        );
                      },
                      child: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        );
                      },
                      child: const Text('Demo Mode'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
