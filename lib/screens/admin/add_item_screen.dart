import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/item.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

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
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dmhbguqqa/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'my_flutter_upload'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final result = jsonDecode(responseData.body);
        return result['secure_url'];
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        final responseData = await http.Response.fromStream(response);
        print('Response body: ${responseData.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _addItem() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih gambar untuk barang.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User tidak login.');
        }

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final sellerName = userDoc.data()?['name'] ?? 'Unknown Seller';

        String? imageUrl;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mengunggah foto...'), duration: Duration(seconds: 5)),
          );
        }
        imageUrl = await _uploadToCloudinary(_selectedImage!);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        if (imageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal mengunggah foto.'), backgroundColor: Colors.red),
            );
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        await FirebaseFirestore.instance.collection('items').add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'stock': int.parse(_stockController.text),
          'imageUrl': imageUrl,
          'sellerId': user.uid,
          'sellerName': sellerName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang berhasil ditambahkan'), backgroundColor: Colors.green),
          );
          _nameController.clear();
          _descriptionController.clear();
          _priceController.clear();
          _stockController.clear();
          setState(() {
            _selectedImage = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menambahkan barang: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Barang Bekas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        // Image Picker
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey, width: 1.5), // Hapus style: BorderStyle.dashed
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, size: 50, color: Colors.grey[700]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Pilih Gambar Barang',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24.0), // Jarak setelah image picker
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Barang',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: const Icon(Icons.shopping_bag), // Ikon untuk nama barang
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mohon masukkan nama barang';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi Barang',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: const Icon(Icons.description), // Ikon untuk deskripsi
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mohon masukkan deskripsi barang';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Harga (Rp)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: const Icon(Icons.attach_money), // Ikon untuk harga
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mohon masukkan harga barang';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Harga harus berupa angka';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _stockController,
                          decoration: InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: const Icon(Icons.inventory), // Ikon untuk stok
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mohon masukkan stok barang';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Stok harus berupa angka bulat';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0), // Jarak sebelum tombol
                        ElevatedButton(
                          onPressed: _isLoading ? null : _addItem,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary, // Gunakan primary color dari tema
                            foregroundColor: Colors.white, // Warna teks putih
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Tambah Barang',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
} 