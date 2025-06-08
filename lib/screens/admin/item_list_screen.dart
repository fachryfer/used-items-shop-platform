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

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75, // Sesuaikan rasio aspek jika diperlukan
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    key: ValueKey(item.id),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        // Tidak ada navigasi ke detail item di admin, fokus pada edit/delete
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gambar Produk
                          if (item.imageUrl != null)
                            Expanded(
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          else
                            Expanded(
                              child: Container(
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${item.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stok: ${item.stock}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          // Tombol Edit dan Hapus
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditItemScreen(itemId: item.id),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
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
                                ),
                              ],
                            ),
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