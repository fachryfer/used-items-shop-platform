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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: const Icon(Icons.person),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mohon masukkan nama lengkap';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Nomor Telepon',
                            prefixIcon: const Icon(Icons.phone),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mohon masukkan nomor telepon';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Alamat Lengkap',
                            prefixIcon: const Icon(Icons.home),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mohon masukkan alamat lengkap';
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
                                decoration: InputDecoration(
                                  labelText: 'Kota',
                                  prefixIcon: const Icon(Icons.location_city),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Mohon masukkan kota';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _provinceController,
                                decoration: InputDecoration(
                                  labelText: 'Provinsi',
                                  prefixIcon: const Icon(Icons.area_chart),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Mohon masukkan provinsi';
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
                          decoration: InputDecoration(
                            labelText: 'Kode Pos',
                            prefixIcon: const Icon(Icons.mail),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mohon masukkan kode pos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Jadikan Alamat Utama'),
                          value: _isDefault,
                          onChanged: (value) {
                            setState(() {
                              _isDefault = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveAddress,
                          child: Text(_isEditing ? 'Perbarui Alamat' : 'Tambah Alamat'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _resetForm,
                          child: const Text('Batal'),
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
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                address.fullName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (address.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'UTAMA',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          address.phoneNumber,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${address.address}, ${address.city}, ${address.province}, ${address.postalCode}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Divider(height: 24, thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditForm(address),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAddress(address.id!),
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

          return Column(
            children: [
              Expanded(child: content),
              if (!_showForm)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton.extended(
                    onPressed: _showAddForm,
                    label: const Text('Tambah Alamat Baru'),
                    icon: const Icon(Icons.add),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 