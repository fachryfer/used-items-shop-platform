import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../user_home_screen.dart';
import '../../models/order.dart' as models;

class UploadTransferProofScreen extends StatefulWidget {
  final models.Order orderData; // Changed to accept full order data

  const UploadTransferProofScreen({
    Key? key,
    required this.orderData,
  }) : super(key: key);

  @override
  State<UploadTransferProofScreen> createState() => _UploadTransferProofScreenState();
}

class _UploadTransferProofScreenState extends State<UploadTransferProofScreen> {
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
      } else {
        print('Tidak ada gambar yang dipilih.');
      }
    });
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/dmhbguqqa/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = 'my_flutter_upload'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = json.decode(await response.stream.bytesToString());
      return responseData['secure_url'];
    } else {
      print('Gagal mengunggah foto: ${response.reasonPhrase}');
      print('Response body: ${await response.stream.bytesToString()}');
      return null;
    }
  }

  Future<void> _uploadProofAndFinishOrder() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih bukti transfer.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengunggah bukti transfer...'), duration: Duration(seconds: 5)),
      );
      final imageUrl = await _uploadToCloudinary(_selectedImage!);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah bukti transfer.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Deduct stock for each item in the order
        for (var cartItem in widget.orderData.cartItems) {
          final itemRef = FirebaseFirestore.instance.collection('items').doc(cartItem.itemId);
          final itemSnapshot = await transaction.get(itemRef);

          if (!itemSnapshot.exists) {
            throw Exception('Barang ${cartItem.name} tidak ditemukan');
          }

          final currentStock = (itemSnapshot.data()?['stock'] ?? 0).toInt();
          if (currentStock < cartItem.quantity) {
            throw Exception('Stok barang ${cartItem.name} tidak mencukupi. Stok tersedia: $currentStock');
          }

          transaction.update(itemRef, {
            'stock': currentStock - cartItem.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Create the order document
        final orderRef = FirebaseFirestore.instance.collection('orders').doc();
        transaction.set(orderRef, {
          ...widget.orderData.toFirestore(),
          'transferProofImageUrl': imageUrl,
          'status': 'waiting_for_admin_confirmation', // New status for admin review
          'orderDate': FieldValue.serverTimestamp(), // Ensure timestamp is set correctly
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti transfer berhasil diunggah. Pesanan Anda akan segera diproses.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UserHomeScreen()),
          (Route<dynamic> route) => false,
        ); // Navigate back to user home screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah bukti transfer: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat("#,##0", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unggah Bukti Transfer'),
        automaticallyImplyLeading: false, // Prevent going back to checkout
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran:',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rp ${oCcy.format(widget.orderData.totalAmount)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const Divider(height: 20, thickness: 1),
                          Text(
                            'Transfer ke:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Bank: ${widget.orderData.paymentDetails!['bankName'] ?? 'N/A'}'),
                          Text('Nama Rekening: ${widget.orderData.paymentDetails!['accountName'] ?? 'N/A'}'),
                          Text('Nomor Rekening: ${widget.orderData.paymentDetails!['accountNumber'] ?? 'N/A'}'),
                          if (widget.orderData.paymentDetails!['qrCodeImageUrl'] != null && widget.orderData.paymentDetails!['qrCodeImageUrl'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Center(
                                child: Image.network(
                                  widget.orderData.paymentDetails!['qrCodeImageUrl'],
                                  width: 200, // Adjust size as needed
                                  height: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image, size: 100, color: Colors.red);
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Section to upload transfer proof
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unggah Bukti Transfer',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16.0),
                          _selectedImage != null
                              ? Column(
                                  children: [
                                    Image.file(
                                      _selectedImage!,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                    TextButton.icon(
                                      onPressed: _pickImage,
                                      icon: const Icon(Icons.change_circle),
                                      label: const Text('Ganti Gambar'),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.cloud_upload),
                                    label: const Text('Pilih Gambar Bukti Transfer'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 24.0),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _uploadProofAndFinishOrder,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Konfirmasi & Kirim Bukti Transfer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 