import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edar_shop/models/order.dart' as models;
import 'package:intl/intl.dart';

class UserOrderHistoryScreen extends StatelessWidget {
  const UserOrderHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Anda harus login untuk melihat riwayat pesanan.'));
    }

    final oCcy = NumberFormat("#,##0", "en_US");

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Riwayat Pesanan Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('buyerId', isEqualTo: user.uid)
                .orderBy('orderDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error fetching user orders: ${snapshot.error}');
                return Center(child: Text('Error memuat riwayat pesanan: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Belum ada riwayat pesanan.'));
              }

              final orders = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return models.Order.fromFirestore(data, doc.id);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: order.itemImageUrl != null
                          ? Image.network(order.itemImageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported, size: 50),
                      title: Text('${order.itemName} (x${order.quantity})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total: Rp ${oCcy.format(order.itemPrice * order.quantity)}'),
                          Text('Status: ${order.status.toUpperCase()}'),
                          Text('Penjual: ${order.sellerName}'),
                          if (order.orderDate != null)
                            Text('Tanggal: ${DateFormat('dd MMMM yyyy, HH:mm').format(order.orderDate!)}'),
                        ],
                      ),
                      onTap: () {
                        // TODO: Navigate to order detail screen if needed
                        print('View order detail for ${order.id}');
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
} 