import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './firebase_options.dart';
import 'package:edar_shop/screens/auth/login_screen.dart'; // Assuming this path
import 'package:edar_shop/screens/auth/register_screen.dart'; // Assuming this path
import 'package:edar_shop/screens/user_home_screen.dart'; // Assuming this path
import 'package:edar_shop/screens/admin/admin_home_screen.dart'; // Our newly created admin home
import 'package:provider/provider.dart';
import 'package:edar_shop/utils/cart_manager.dart';
import 'package:edar_shop/screens/user/cart_screen.dart'; // Jalur yang benar
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize date formatting for 'id' locale
  Intl.defaultLocale = 'id';
  await initializeDateFormatting('id', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartManager(),
      child: MaterialApp(
        title: 'Aplikasi Penjualan Barang Bekas',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal.shade900, // Warna dasar yang lebih gelap (hijau navy)
            brightness: Brightness.dark, // Tema gelap
            primary: Colors.teal.shade700!, // Warna primer
            onPrimary: Colors.white, // Warna teks di atas primer
            secondary: Colors.blueGrey.shade700!, // Warna sekunder/aksen
            onSecondary: Colors.white, // Warna teks di atas sekunder
            surface: Colors.blueGrey.shade800!, // Warna permukaan (misal: Card, dialog)
            onSurface: Colors.white, // Warna teks di atas permukaan
            background: Colors.blueGrey.shade900!, // Warna latar belakang umum
            onBackground: Colors.white, // Warna teks di atas latar belakang
            error: Colors.red.shade700!, // Warna error
            onError: Colors.white, // Warna teks di atas error
          ),
          scaffoldBackgroundColor: Colors.blueGrey.shade900, // Latar belakang gelap untuk semua layar
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.teal.shade900, // Warna app bar sama dengan seedColor/primary darker
            foregroundColor: Colors.white, // Warna teks di app bar
            iconTheme: const IconThemeData(color: Colors.white), // Warna ikon di app bar
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.blueGrey.shade800, // Warna card agar cocok dengan tema gelap
            elevation: 4, // Elevasi card
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Sudut membulat
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white.withOpacity(0.9)),
            bodyMedium: TextStyle(color: Colors.white.withOpacity(0.7)),
            bodySmall: TextStyle(color: Colors.white.withOpacity(0.5)),
            titleLarge: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.bold),
            titleMedium: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
            titleSmall: TextStyle(color: Colors.white.withOpacity(0.8)),
            headlineSmall: TextStyle(color: Colors.white.withOpacity(0.98), fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(color: Colors.white.withOpacity(0.98), fontWeight: FontWeight.bold),
            headlineLarge: TextStyle(color: Colors.white.withOpacity(0.98), fontWeight: FontWeight.bold),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.blueGrey.shade700, // Warna latar belakang input field
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)), // Warna label
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)), // Warna hint
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none, // Hapus border default untuk tampilan yang lebih mulus
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.blueGrey.shade600!, width: 1.0), // Border saat enable
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), // Border saat focus
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.0), // Border saat error
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2.0), // Border saat focus dan error
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Padding konten input field
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary, // Warna latar belakang tombol
              foregroundColor: Theme.of(context).colorScheme.onPrimary, // Warna teks tombol
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary, // Warna teks tombol
            ),
          ),
          radioTheme: RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.teal.shade700; // Warna saat dipilih
              }
              return Colors.white; // Warna saat tidak dipilih
            }),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.blueGrey.shade900, // Background navbar
            selectedItemColor: Colors.teal.shade300, // Warna item terpilih
            unselectedItemColor: Colors.blueGrey.shade300, // Warna item tidak terpilih
            type: BottomNavigationBarType.fixed, // Pastikan ikon tidak bergeser
            elevation: 8,
          ),
          // primaryColor: Colors.blue, // Dihapus karena menggunakan ColorScheme.fromSeed
          // primarySwatch: Colors.blue, // Dihapus karena menggunakan ColorScheme.fromSeed
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true, // Gunakan Material 3 design
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
          '/cart': (context) => const CartScreen(),
        },
      ),
    );
  }
}
