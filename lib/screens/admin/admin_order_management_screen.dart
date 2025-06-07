import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart' as app_order; // Beri alias untuk model Order kita
import '../../models/item.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart' as firestore_platform; // Alias yang sudah ada

class AdminOrderManagementScreen extends StatelessWidget {
  const AdminOrderManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat("#,##0", "en_US");

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Manajemen Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .orderBy('orderDate', descending: true) // Order by creation time
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error fetching orders: ${snapshot.error}');
                return Center(child: Text('Error memuat data pesanan: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Belum ada pesanan.'));
              }

              final orders = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return app_order.Order.fromFirestore(data, doc.id); // Gunakan alias
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
                          Text('Pembeli: ${order.buyerName}'),
                          Text('Total: Rp ${oCcy.format(order.itemPrice * order.quantity)}'),
                          Text('Status: ${order.status.toUpperCase()}'),
                          if (order.orderDate != null)
                            Text('Tanggal: ${DateFormat('dd MMMM yyyy, HH:mm').format(order.orderDate!)}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (order.status == 'pending') ...[
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () async {
                                try {
                                  await FirebaseFirestore.instance.collection('orders').doc(order.id).update({'status': 'completed'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pesanan diselesaikan.'), backgroundColor: Colors.green)
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal menyelesaikan pesanan: $e'), backgroundColor: Colors.red)
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () async {
                                try {
                                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                                    // Get item reference
                                    final itemRef = FirebaseFirestore.instance.collection('items').doc(order.itemId);
                                    final itemSnapshot = await transaction.get(itemRef);

                                    if (itemSnapshot.exists) {
                                      final currentStock = (itemSnapshot.data()?['stock'] ?? 0).toInt();
                                      // Restore stock
                                      transaction.update(itemRef, {'stock': currentStock + order.quantity, 'updatedAt': FieldValue.serverTimestamp()});
                                    }
                                    // Update order status to cancelled
                                    transaction.update(FirebaseFirestore.instance.collection('orders').doc(order.id), {'status': 'cancelled'});
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pesanan dibatalkan dan stok dikembalikan!'), backgroundColor: Colors.orange)
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal membatalkan pesanan: $e'), backgroundColor: Colors.red)
                                  );
                                }
                              },
                            ),
                          ]
                        ],
                      ),
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
