import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import '../screens/item_detail_screen.dart';
import '../screens/user/user_order_history_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    // Daftar Barang (Home)
    Column(
      children: [
        const SizedBox(height: 16),
        const Text('Barang Tersedia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('items')
                .where('stock', isGreaterThan: 0)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              print('StreamBuilder ConnectionState: ${snapshot.connectionState}');
              print('StreamBuilder hasData: ${snapshot.hasData}');
              print('StreamBuilder hasError: ${snapshot.hasError}');
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error fetching items: ${snapshot.error}');
                return Center(child: Text('Error memuat data barang: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                print('No data or empty docs.');
                return const Center(child: Text('Belum ada barang tersedia.'));
              }

              print('Data received: ${snapshot.data!.docs.length} items');
              final items = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Item.fromFirestore(data, doc.id);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: item.imageUrl != null
                          ? Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported, size: 50),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harga: Rp ${item.price.toStringAsFixed(0)}'),
                          Text('Stok: ${item.stock}'),
                          Text('Penjual: ${item.sellerName ?? 'N/A'}'),
                        ],
                      ),
                      onTap: () {
                        // TODO: Navigate to item detail screen
                        // print('View item detail for ${item.name}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(item: item),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    // Riwayat Pesanan
    const UserOrderHistoryScreen(),
    // Profil User
    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Selamat datang, Pengguna!'),
          const SizedBox(height: 20),
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    ),
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
        title: const Text('Dashboard Pengguna'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
} 