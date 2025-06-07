import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_address.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({Key? key}) : super(key: key);

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _isDefault = false;
  bool _isEditing = false;
  String? _editingAddressId;
  bool _showForm = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _fullNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
    _provinceController.clear();
    _postalCodeController.clear();
    _isDefault = false;
    _isEditing = false;
    _editingAddressId = null;
    _showForm = false;
  }

  void _showAddForm() {
    _resetForm();
    setState(() {
      _showForm = true;
    });
  }

  void _showEditForm(UserAddress address) {
    setState(() {
      _isEditing = true;
      _editingAddressId = address.id;
      _fullNameController.text = address.fullName;
      _phoneController.text = address.phoneNumber;
      _addressController.text = address.address;
      _cityController.text = address.city;
      _provinceController.text = address.province;
      _postalCodeController.text = address.postalCode;
      _isDefault = address.isDefault;
      _showForm = true;
    });
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final addressRef = FirebaseFirestore.instance.collection('user_addresses');
      
      if (_isDefault) {
        final existingDefaults = await addressRef
            .where('userId', isEqualTo: user.uid)
            .where('isDefault', isEqualTo: true)
            .get();
        
        for (var doc in existingDefaults.docs) {
          if (doc.id != _editingAddressId) {
            await doc.reference.update({'isDefault': false});
          }
        }
      }

      if (_isEditing && _editingAddressId != null) {
        await addressRef.doc(_editingAddressId).update({
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'province': _provinceController.text,
          'postalCode': _postalCodeController.text,
          'isDefault': _isDefault,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await addressRef.add({
          'userId': user.uid,
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'province': _provinceController.text,
          'postalCode': _postalCodeController.text,
          'isDefault': _isDefault,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      _resetForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan alamat: $e')),
        );
      }
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_addresses')
          .doc(addressId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus alamat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Alamat'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_addresses')
            .where('userId', isEqualTo: user.uid)
            .orderBy('isDefault', descending: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final addresses = snapshot.data?.docs
                  .map((doc) => UserAddress.fromMap({
                        'id': doc.id,
                        ...doc.data() as Map<String, dynamic>,
                      }))
                  .toList() ??
              [];

          Widget content;
          if (_showForm) {
            content = SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Alamat' : 'Tambah Alamat Baru',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama lengkap harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nomor telepon harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Lengkap',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alamat harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'Kota',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kota harus diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _provinceController,
                                decoration: const InputDecoration(
                                  labelText: 'Provinsi',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.area_chart),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Provinsi harus diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _postalCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Kode Pos',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.local_post_office),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kode pos harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text('Jadikan Alamat Default'),
                          value: _isDefault,
                          onChanged: (value) {
                            setState(() {
                              _isDefault = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetForm,
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveAddress,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Alamat'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else if (addresses.isEmpty) {
            content = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum ada alamat tersimpan.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddForm,
                    child: const Text('Tambah Alamat Baru'),
                  ),
                ],
              ),
            );
          } else {
            content = ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (address.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          address.phoneNumber,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${address.address}, ${address.city}, ${address.province} ${address.postalCode}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _showEditForm(address),
                              child: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _deleteAddress(address.id),
                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: content),
              if (!_showForm && addresses.isNotEmpty)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _showAddForm,
                    label: const Text('Tambah Alamat Baru'),
                    icon: const Icon(Icons.add),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 