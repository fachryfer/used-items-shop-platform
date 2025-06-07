import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';
import 'package:intl/intl.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;

  const ItemDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat("#,##0", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.item.imageUrl != null)
              Center(
                child: Image.network(
                  widget.item.imageUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 150,
                  color: Colors.grey[300],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.item.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Harga: Rp ${oCcy.format(widget.item.price)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stok Tersedia: ${widget.item.stock}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.item.description),
            const SizedBox(height: 16),
            Text(
              'Penjual: ${widget.item.sellerName ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            if (widget.item.createdAt != null)
              Text(
                'Ditambahkan pada: ${DateFormat('dd MMMM yyyy').format(widget.item.createdAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 24),
            // Purchase Button (conditionally enabled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.item.stock > 0
                    ? () {
                        // TODO: Implement purchase logic
                        print('Beli ${widget.item.name}');
                      }
                    : null, // Disable button if stock is 0
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.item.stock > 0 ? Colors.blue : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.item.stock > 0 ? 'Beli Sekarang' : 'Stok Habis',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 