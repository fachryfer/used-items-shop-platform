import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_item_screen.dart'; // Import AddItemScreen
import 'item_list_screen.dart'; // Will create this later
import 'admin_order_management_screen.dart'; // Import AdminOrderManagementScreen
import 'admin_profile_screen.dart'; // Import AdminProfileScreen

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const ItemListScreen(), // Daftar Barang
    const AdminOrderManagementScreen(), // Manajemen Pesanan
    const AdminProfileScreen(), // Profil Admin
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      floatingActionButton: _selectedIndex == 0 // Show button on Item List tab
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen()));
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.primary, // Gunakan primary color dari tema
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Barang'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
} 