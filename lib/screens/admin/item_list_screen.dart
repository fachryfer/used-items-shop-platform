import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/item.dart';
import 'edit_item_screen.dart';

class ItemListScreen extends StatelessWidget {
  const ItemListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Daftar Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('items')
                .orderBy('createdAt', descending: true) // Order by creation time
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                 print('Error fetching items: ${snapshot.error}');
                return Center(child: Text('Error memuat data barang: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Belum ada barang ditambahkan.'));
              }

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
                    key: ValueKey(item.id),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              // TODO: Implement edit navigation
                              // print('Edit item ${item.id}'); // Placeholder
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditItemScreen(itemId: item.id),
                                ),
                              );
                            },
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // Implement delete functionality
                              try {
                                await FirebaseFirestore.instance.collection('items').doc(item.id).delete();
                                if (context.mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('Barang berhasil dihapus'), backgroundColor: Colors.green)
                                   );
                                }
                              } catch (e) {
                                 if (context.mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(content: Text('Gagal menghapus barang: $e'), backgroundColor: Colors.red)
                                   );
                                 }
                              }
                            },
                          ),
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