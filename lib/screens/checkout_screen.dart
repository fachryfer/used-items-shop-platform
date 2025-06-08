import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shipping_address.dart';
import '../models/user_address.dart';
import '../models/order.dart' as models;
import 'package:intl/intl.dart';
import 'user/address_management_screen.dart';
import '../models/cart_item.dart';
import 'package:http/http.dart' as http;
import 'user/upload_transfer_proof_screen.dart';

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

  List<Map<String, dynamic>> _availablePaymentMethods = [];
  Map<String, dynamic>? _selectedPaymentMethodDetails;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
    _loadPaymentMethods();
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

  Future<void> _loadPaymentMethods() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('payment_methods').get();
      setState(() {
        _availablePaymentMethods = snapshot.docs.map((doc) => doc.data()).toList();
        if (_availablePaymentMethods.isNotEmpty) {
          _selectedPaymentMethodDetails = _availablePaymentMethods.first;
          _selectedPaymentMethod = _selectedPaymentMethodDetails!['bankName'] ?? '';
        }
      });
    } catch (e) {
      print('Error loading payment methods: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat metode pembayaran: $e'), backgroundColor: Colors.red),
        );
      }
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

    if (_selectedPaymentMethodDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih metode pembayaran.'), backgroundColor: Colors.red),
      );
      return;
    }

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

      // Calculate total amount from cart items
      double totalAmount = widget.cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

      // Prepare order data to pass to UploadTransferProofScreen
      final orderData = models.Order(
        id: '', // ID will be generated in UploadTransferProofScreen
        cartItems: widget.cartItems,
        totalAmount: totalAmount,
        buyerId: user.uid,
        buyerName: user.displayName ?? user.email ?? 'Pengguna',
        sellerId: '', // Will be aggregated later if needed
        sellerName: 'N/A', // Will be aggregated later if needed
        status: 'pending', // Initial status before transfer proof
        orderDate: DateTime.now(),
        shippingAddress: shippingAddress.toMap(),
        paymentMethod: _selectedPaymentMethod,
        paymentDetails: _selectedPaymentMethodDetails,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan siap dikonfirmasi. Unggah bukti transfer.'),
            backgroundColor: Colors.blueAccent,
          ),
        );
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => UploadTransferProofScreen(
            orderData: orderData,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melanjutkan pesanan: ${e.toString()}'),
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
                                                prefixIcon: Icon(Icons.map),
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
                                          prefixIcon: Icon(Icons.local_post_office),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Kode pos harus diisi';
                                          }
                                          if (value.length < 5) {
                                            return 'Kode pos minimal 5 digit';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _notesController,
                                        decoration: const InputDecoration(
                                          labelText: 'Catatan (Opsional)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.note),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                        ),
                                        maxLines: 3,
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // Metode Pembayaran
                            Text(
                              'Metode Pembayaran',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedPaymentMethodDetails,
                              decoration: InputDecoration(
                                labelText: 'Pilih Metode Pembayaran',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.payment),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              ),
                              items: _availablePaymentMethods.map((method) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: method,
                                  child: Text(
                                    '${method['bankName']} - ${method['accountName']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethodDetails = value;
                                  _selectedPaymentMethod = value?['bankName'] ?? '';
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Mohon pilih metode pembayaran';
                                }
                                return null;
                              },
                            ),
                            if (_selectedPaymentMethodDetails != null) ...[
                              const SizedBox(height: 16),
                              Card(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Detail Transfer:',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Bank: ${_selectedPaymentMethodDetails!['bankName'] ?? 'N/A'}'),
                                      Text('Nama Rekening: ${_selectedPaymentMethodDetails!['accountName'] ?? 'N/A'}'),
                                      Text('Nomor Rekening: ${_selectedPaymentMethodDetails!['accountNumber'] ?? 'N/A'}'),
                                      if (_selectedPaymentMethodDetails!['qrCodeImageUrl'] != null && _selectedPaymentMethodDetails!['qrCodeImageUrl'].isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 16.0),
                                          child: Center(
                                            child: Image.network(
                                              _selectedPaymentMethodDetails!['qrCodeImageUrl'],
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
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _processOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Konfirmasi Pesanan'),
                              ),
                            ),
                          ],
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