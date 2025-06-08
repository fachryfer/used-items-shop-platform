import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shipping_address.dart';
import '../models/user_address.dart';
import '../models/order.dart' as models;
import 'package:intl/intl.dart';
import 'user/address_management_screen.dart';
import '../models/cart_item.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
  
  // Form controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'transfer_bank';
  bool _isLoading = false;
  bool _useSavedAddress = true;
  UserAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_addresses')
          .where('userId', isEqualTo: user.uid)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final address = UserAddress.fromMap({
          'id': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        });
        setState(() {
          _selectedAddress = address;
          _useSavedAddress = true;
          _fillAddressForm(_selectedAddress!);
        });
      }
    } catch (e) {
      print('Error loading default address: $e');
    }
  }

  void _fillAddressForm(UserAddress address) {
    _fullNameController.text = address.fullName;
    _phoneController.text = address.phoneNumber;
    _addressController.text = address.address;
    _cityController.text = address.city;
    _provinceController.text = address.province;
    _postalCodeController.text = address.postalCode;
    _notesController.text = '';
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Anda harus login untuk melakukan pembelian');

      final shippingAddress = ShippingAddress(
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        province: _provinceController.text,
        postalCode: _postalCodeController.text,
        notes: _notesController.text,
      );

      // Simpan alamat jika ini adalah alamat baru
      if (!_useSavedAddress) {
        final addressRef = FirebaseFirestore.instance.collection('user_addresses');
        await addressRef.add({
          'userId': user.uid,
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'province': _provinceController.text,
          'postalCode': _postalCodeController.text,
          'notes': _notesController.text,
          'isDefault': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        double totalAmount = 0.0;
        final List<Map<String, dynamic>> itemsToUpdate = [];

        // Fase 1: Semua pembacaan dan validasi
        for (var cartItem in widget.cartItems) {
          final itemRef = FirebaseFirestore.instance.collection('items').doc(cartItem.itemId);
          final itemSnapshot = await transaction.get(itemRef);

          if (!itemSnapshot.exists) {
            throw Exception('Barang ${cartItem.name} tidak ditemukan');
          }

          final currentStock = (itemSnapshot.data()?['stock'] ?? 0).toInt();
          if (currentStock < cartItem.quantity) {
            throw Exception('Stok barang ${cartItem.name} tidak mencukupi. Stok tersedia: $currentStock');
          }

          totalAmount += cartItem.price * cartItem.quantity;
          itemsToUpdate.add({
            'ref': itemRef,
            'newStock': currentStock - cartItem.quantity,
          });
        }

        // Fase 2: Semua penulisan
        for (var itemData in itemsToUpdate) {
          transaction.update(itemData['ref'], {
            'stock': itemData['newStock'],
            'updatedAt': FieldValue.serverTimestamp()
          });
        }

        // Buat pesanan baru
        final newOrder = models.Order(
          id: '',
          cartItems: widget.cartItems,
          totalAmount: totalAmount,
          buyerId: user.uid,
          buyerName: user.displayName ?? user.email ?? 'Pengguna',
          sellerId: '',
          sellerName: 'N/A',
          status: 'pending',
          orderDate: DateTime.now(),
          shippingAddress: shippingAddress.toMap(),
          paymentMethod: _selectedPaymentMethod,
        );

        // Tambahkan pesanan ke koleksi orders
        final orderRef = FirebaseFirestore.instance.collection('orders').doc();
        transaction.set(orderRef, {
          ...newOrder.toFirestore(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat! Silakan lakukan pembayaran.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pesanan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressManagementScreen(),
                ),
              );
              _loadDefaultAddress();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ringkasan Pesanan
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ringkasan Pesanan',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            ...widget.cartItems.map((cartItem) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      if (cartItem.imageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            cartItem.imageUrl,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cartItem.name,
                                              style: Theme.of(context).textTheme.titleMedium,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${cartItem.quantity} x Rp ${NumberFormat.decimalPattern('id').format(cartItem.price)}',
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'Rp ${NumberFormat.decimalPattern('id').format(cartItem.quantity * cartItem.price)}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Rp ${NumberFormat.decimalPattern('id').format(widget.cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)))} ',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pilihan Alamat
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alamat Pengiriman',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('user_addresses')
                                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                                  .orderBy('isDefault', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }

                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }

                                final addresses = snapshot.data?.docs
                                    .map((doc) => UserAddress.fromMap({
                                          'id': doc.id,
                                          ...doc.data() as Map<String, dynamic>,
                                        }))
                                    .toList() ??
                                    [];

                                if (addresses.isEmpty) {
                                  _useSavedAddress = false;
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (addresses.isNotEmpty) ...[
                                      SwitchListTile(
                                        title: const Text('Gunakan Alamat Tersimpan'),
                                        value: _useSavedAddress,
                                        onChanged: (value) {
                                          setState(() {
                                            _useSavedAddress = value;
                                            if (value && _selectedAddress != null) {
                                              _fillAddressForm(_selectedAddress!);
                                            } else if (!value) {
                                              _fullNameController.clear();
                                              _phoneController.clear();
                                              _addressController.clear();
                                              _cityController.clear();
                                              _provinceController.clear();
                                              _postalCodeController.clear();
                                              _notesController.clear();
                                            }
                                          });
                                        },
                                      ),
                                      if (_useSavedAddress) ...[
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<UserAddress>(
                                          value: _selectedAddress,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            labelText: 'Pilih Alamat',
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(Icons.location_on),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                          ),
                                          items: addresses.map((address) {
                                            return DropdownMenuItem(
                                              value: address,
                                              child: Expanded(
                                                child: Text(
                                                  '${address.fullName} - ${address.address}, ${address.city}',
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _selectedAddress = value;
                                                _fillAddressForm(value);
                                              });
                                            }
                                          },
                                          selectedItemBuilder: (BuildContext context) {
                                            return addresses.map<Widget>((UserAddress address) {
                                              return Text(
                                                '${address.fullName} - ${address.address}, ${address.city} ${address.province} ${address.postalCode}',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ) as Widget;
                                            }).toList();
                                          },
                                        ),
                                      ],
                                    ],
                                    if (!_useSavedAddress) ...[
                                      TextFormField(
                                        controller: _fullNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Lengkap',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.person),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                                          prefixIcon: Icon(Icons.home),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                                          prefixIcon: Icon(Icons.mail),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Kode pos harus diisi';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16), // Jarak antara alamat dan catatan
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Catatan (Opsional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Metode Pembayaran
                    Text(
                      'Metode Pembayaran',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: Text('Transfer Bank', style: Theme.of(context).textTheme.bodyLarge),
                              value: 'transfer_bank',
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: Text('E-Wallet', style: Theme.of(context).textTheme.bodyLarge),
                              value: 'e_wallet',
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Bayar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _processOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Bayar Sekarang',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 