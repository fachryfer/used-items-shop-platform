import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:edar_shop/models/order.dart' as models;
import '../../models/item.dart';
import 'package:edar_shop/models/cart_item.dart';
import 'package:edar_shop/screens/order_details_screen.dart';

class AdminOrderManagementScreen extends StatelessWidget {
  const AdminOrderManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat("#,##0", "en_US");

    return Column(
      children: [
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
                return models.Order.fromFirestore(data, doc.id); // Gunakan alias
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: order, isAdmin: true),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Menggunakan ListView.builder untuk menampilkan setiap item dalam pesanan
                            ...order.cartItems.map((cartItem) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: cartItem.imageUrl.isNotEmpty
                                          ? Image.network(cartItem.imageUrl,
                                              width: 60, height: 60, fit: BoxFit.cover)
                                          : Container(
                                              width: 60, height: 60, color: Theme.of(context).colorScheme.surface,
                                              child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${cartItem.name} (x${cartItem.quantity})',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rp ${oCcy.format(cartItem.price * cartItem.quantity)}',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const Divider(height: 24, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Pesanan:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Rp ${oCcy.format(order.totalAmount)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                                const SizedBox(width: 4),
                                Text(
                                  'Pembeli: ${order.buyerName}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (order.orderDate != null)
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tanggal: ${DateFormat('dd MMMM yyyy, HH:mm').format(order.orderDate!)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order.status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8), // Added spacing below status
                            // Tombol Aksi
                            if (order.status == 'pending' || order.status == 'waiting_for_admin_confirmation')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
                                children: [
                                  if (order.transferProofImageUrl != null && order.transferProofImageUrl!.isNotEmpty && order.status == 'waiting_for_admin_confirmation')
                                    IconButton(
                                      icon: const Icon(Icons.receipt, color: Colors.blueAccent),
                                      tooltip: 'Lihat Bukti Transfer',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Bukti Transfer'),
                                            content: Image.network(order.transferProofImageUrl!), // Display the image
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Tutup'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    tooltip: 'Setujui Pesanan',
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance.collection('orders').doc(order.id).update({'status': 'packaged'});
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Pesanan disetujui dan status diubah menjadi Dikemas.'), backgroundColor: Colors.green)
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal menyetujui pesanan: $e'), backgroundColor: Colors.red)
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    tooltip: 'Batalkan Pesanan',
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance.runTransaction((transaction) async {
                                          for (var cartItem in order.cartItems) {
                                            final itemRef = FirebaseFirestore.instance.collection('items').doc(cartItem.itemId);
                                            final itemSnapshot = await transaction.get(itemRef);

                                            if (itemSnapshot.exists) {
                                              final currentStock = (itemSnapshot.data()?['stock'] ?? 0).toInt();
                                              // Restore stock for each item
                                              transaction.update(itemRef, {'stock': currentStock + cartItem.quantity, 'updatedAt': FieldValue.serverTimestamp()});
                                            }
                                          }
                                          // Update order status to cancelled
                                          transaction.update(FirebaseFirestore.instance.collection('orders').doc(order.id), {'status': 'cancelled'});
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Pesanan dibatalkan dan stok dikembalikan!'), backgroundColor: Colors.orange)
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal membatalkan pesanan: $e'), backgroundColor: Colors.red)
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            if (order.status == 'packaged')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.local_shipping, color: Colors.blueGrey),
                                    tooltip: 'Sedang Diantar',
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance.collection('orders').doc(order.id).update({'status': 'shipped'});
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Pesanan diubah menjadi Sedang Diantar.'), backgroundColor: Colors.blue)
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red)
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.archive, color: Colors.indigo),
                                    tooltip: 'Selesai',
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance.collection('orders').doc(order.id).update({'status': 'delivered'});
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Pesanan berhasil dikirim dan diselesaikan.'), backgroundColor: Colors.purple)
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red)
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            if (order.status == 'shipped')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.archive, color: Colors.indigo),
                                    tooltip: 'Selesai',
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance.collection('orders').doc(order.id).update({'status': 'delivered'});
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Pesanan berhasil diubah menjadi Selesai diantar.'), backgroundColor: Colors.purple)
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red)
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'waiting_for_admin_confirmation':
        return Colors.blue.shade700;
      case 'packaged':
        return Colors.brown.shade700;
      case 'shipped':
        return Colors.indigo.shade700;
      case 'delivered':
        return Colors.purple.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
 