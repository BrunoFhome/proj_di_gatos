import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Achei Meu Gato',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          print("Auth state changed: ${userSnapshot.data?.email ?? 'No user'}");
          print("Connection state: ${userSnapshot.connectionState}");
          print("Has data: ${userSnapshot.hasData}");
          print("Has error: ${userSnapshot.hasError}");
          
          // Show loading while checking auth state
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            print("Showing loading screen");
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // If user is authenticated, show home screen
          if (userSnapshot.hasData && userSnapshot.data != null) {
            print("User is authenticated, showing home screen");
            return const HomeScreen();
          }
          
          // If no user is authenticated, show auth screen
          print("No user authenticated, showing auth screen");
          return const AuthScreen();
        },
      ),
      routes: {
        '/login': (ctx) => const AuthScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}