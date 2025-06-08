import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edar_shop/screens/user/address_management_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const UserProfileScreen({super.key, required this.onNavigateToTab});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'Pengguna',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildProfileMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Pesanan Saya',
            onTap: () {
              widget.onNavigateToTab(1); // Navigate to orders tab
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Alamat',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressManagementScreen()));
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.settings_outlined,
            title: 'Pengaturan',
            onTap: () {
              // Handle settings tap
            },
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 