import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './firebase_options.dart';
import 'package:edar_shop/screens/auth/login_screen.dart'; // Assuming this path
import 'package:edar_shop/screens/auth/register_screen.dart'; // Assuming this path
import 'package:edar_shop/screens/user_home_screen.dart'; // Assuming this path
import 'package:edar_shop/screens/admin/admin_home_screen.dart'; // Our newly created admin home

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Aplikasi Penjualan Barang Bekas',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // Ganti tema dasar
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>( // Use StreamBuilder to check auth state
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // User is logged in, check role
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final role = userSnapshot.data!['role'];
                  if (role == 'admin') {
                    return const AdminHomeScreen();
                  } else {
                    return const UserHomeScreen();
                  }
                } else {
                  // If user data not found, send to login
                  return const LoginScreen();
                }
              },
            );
          } else {
            // User is not logged in
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/user_home': (context) => const UserHomeScreen(),
        '/admin_home': (context) => const AdminHomeScreen(),
      },
    );
  }
}
