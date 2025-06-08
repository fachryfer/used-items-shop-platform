import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edar_shop/models/order.dart' as models;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  final models.Order order;
  final bool isAdmin;

  const OrderDetailsScreen({super.key, required this.order, this.isAdmin = false});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _statusText = widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final formattedDate = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(widget.order.orderDate ?? DateTime.now());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Ringkasan Pesanan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20, thickness: 1),
                    _buildInfoRow(context, 'ID Pesanan:', widget.order.id),
                    _buildInfoRow(context, 'Pembeli:', widget.order.buyerName),
                    _buildInfoRow(context, 'Tanggal Pesanan:', formattedDate),
                    _buildInfoRow(
                      context,
                      'Status:',
                      _statusText.toUpperCase(),
                      valueColor: _getStatusColor(_statusText),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Harga:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          oCcy.format(widget.order.totalAmount),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                      'Detail Barang',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20, thickness: 1),
                    ...widget.order.cartItems.map((cartItem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: cartItem.imageUrl.isNotEmpty
                                  ? Image.network(
                                      cartItem.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Theme.of(context).colorScheme.surface,
                                      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jumlah: ${cartItem.quantity}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    oCcy.format(cartItem.price * cartItem.quantity),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.teal.shade300),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            if (widget.order.shippingAddress != null)
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
                        'Alamat Pengiriman',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20, thickness: 1),
                      _buildInfoRow(context, 'Penerima:', widget.order.shippingAddress!['fullName'] ?? 'N/A'),
                      _buildInfoRow(context, 'Telepon:', widget.order.shippingAddress!['phoneNumber'] ?? 'N/A'),
                      _buildInfoRow(context, 'Alamat:', widget.order.shippingAddress!['address'] ?? 'N/A'),
                      _buildInfoRow(context, 'Kota:', widget.order.shippingAddress!['city'] ?? 'N/A'),
                      _buildInfoRow(context, 'Kode Pos:', widget.order.shippingAddress!['postalCode'] ?? 'N/A'),
                      if (widget.order.shippingAddress!['notes'] != null && widget.order.shippingAddress!['notes'].isNotEmpty)
                        _buildInfoRow(context, 'Catatan:', widget.order.shippingAddress!['notes']),
                    ],
                  ),
                ),
              ),
            if (widget.order.paymentMethod != null)
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
                        'Metode Pembayaran',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20, thickness: 1),
                      _buildInfoRow(context, 'Metode:', widget.order.paymentMethod!),
                      if (widget.order.paymentDetails != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Detail Transfer:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(context, 'Bank:', widget.order.paymentDetails!['bankName'] ?? 'N/A'),
                        _buildInfoRow(context, 'Nama Rekening:', widget.order.paymentDetails!['accountName'] ?? 'N/A'),
                        _buildInfoRow(context, 'Nomor Rekening:', widget.order.paymentDetails!['accountNumber'] ?? 'N/A'),
                      ],
                      if (widget.order.transferProofImageUrl != null && widget.order.transferProofImageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  'Bukti Transfer:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Image.network(
                                  widget.order.transferProofImageUrl!,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image, size: 100, color: Colors.red);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (widget.isAdmin) _buildAdminActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'packaged':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAdminActions() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aksi Admin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1),
            if (widget.order.transferProofImageUrl != null && widget.order.transferProofImageUrl!.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  if (await canLaunchUrl(Uri.parse(widget.order.transferProofImageUrl!))) {
                    await launchUrl(Uri.parse(widget.order.transferProofImageUrl!));
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak dapat membuka URL bukti transfer.'))
                      );
                    }
                  }
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Lihat Bukti Transfer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 10),
            if (_statusText == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus('packaged', 'Pesanan berhasil disetujui (dikemas).'),
                      icon: const Icon(Icons.check),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus('cancelled', 'Pesanan berhasil dibatalkan.'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Batalkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else if (_statusText == 'packaged')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus('shipped', 'Pesanan berhasil diubah menjadi Sedang diantar.'),
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('Sedang Diantar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus('cancelled', 'Pesanan berhasil dibatalkan.'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Batalkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else if (_statusText == 'shipped')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus('delivered', 'Pesanan berhasil diubah menjadi Selesai diantar.'),
                      icon: const Icon(Icons.archive),
                      label: const Text('Selesai Diantar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus('cancelled', 'Pesanan berhasil dibatalkan.'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Batalkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String newStatus, String successMessage) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.order.id).update({'status': newStatus});
      // If order is cancelled, revert item stock
      if (newStatus == 'cancelled') {
        for (var item in widget.order.cartItems) {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            DocumentReference itemRef = FirebaseFirestore.instance.collection('items').doc(item.itemId);
            DocumentSnapshot itemSnapshot = await transaction.get(itemRef);

            if (itemSnapshot.exists) {
              int currentStock = itemSnapshot['stock'] ?? 0;
              transaction.update(itemRef, {'stock': currentStock + item.quantity});
            }
          });
        }
      }

      if (mounted) {
        setState(() {
          _statusText = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }
} 