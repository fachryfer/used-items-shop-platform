import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/item.dart';

class EditItemScreen extends StatefulWidget {
  final String itemId;

  const EditItemScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = true; // To show loading while fetching data

  @override
  void initState() {
    super.initState();
    _loadItemData();
  }

  Future<void> _loadItemData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('items').doc(widget.itemId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _priceController.text = (data['price'] ?? 0.0).toString();
          _stockController.text = (data['stock'] ?? 0).toString();
          _currentImageUrl = data['imageUrl'];
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang tidak ditemukan.'), backgroundColor: Colors.red),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data barang: $e'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Use same loading state for update
      });
      try {
        String? imageUrl = _currentImageUrl;
        if (_selectedImage != null) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Mengunggah foto baru...'), duration: Duration(seconds: 5))
             );
          }
          imageUrl = await _uploadToCloudinary(_selectedImage!);
          if (mounted) {
             ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          if (imageUrl == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal mengunggah foto baru.'), backgroundColor: Colors.red),
              );
              setState(() {
                _isLoading = false;
              });
            }
            return;
          }
        }

        await FirebaseFirestore.instance.collection('items').doc(widget.itemId).update({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'stock': int.parse(_stockController.text),
          'imageUrl': imageUrl, // Use new or existing image URL
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang berhasil diperbarui'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui barang: $e'), backgroundColor: Colors.red),
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
        title: const Text('Edit Barang Bekas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Barang',
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Barang',
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon masukkan harga';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Mohon masukkan angka positif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Stok',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon masukkan jumlah stok';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 0) { // Allow 0 for out of stock
                          return 'Mohon masukkan angka non-negatif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    _selectedImage != null
                        ? Image.file(_selectedImage!, height: 150, fit: BoxFit.cover)
                        : (_currentImageUrl != null
                            ? Image.network(_currentImageUrl!, height: 150, fit: BoxFit.cover)
                            : const Text('Tidak ada gambar dipilih')),
                    const SizedBox(height: 8.0),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Ganti Gambar'),
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateItem,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 