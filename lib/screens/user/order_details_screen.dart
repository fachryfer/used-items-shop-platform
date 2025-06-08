import 'package:flutter/material.dart';
import 'package:edar_shop/models/order.dart' as models;
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final models.Order order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat("#,##0", "en_US");

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
                    _buildInfoRow(context, 'ID Pesanan:', order.id),
                    _buildInfoRow(context, 'Pembeli:', order.buyerName),
                    if (order.orderDate != null)
                      _buildInfoRow(
                        context,
                        'Tanggal Pesanan:',
                        DateFormat('dd MMMM yyyy, HH:mm').format(order.orderDate!),
                      ),
                    _buildInfoRow(context, 'Status:', order.status.toUpperCase(),
                        valueColor: _getStatusColor(order.status)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Harga:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rp ${oCcy.format(order.totalAmount)}',
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
                    ...order.cartItems.map((cartItem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: cartItem.imageUrl.isNotEmpty
                                  ? Image.network(cartItem.imageUrl,
                                      width: 80, height: 80, fit: BoxFit.cover)
                                  : Container(
                                      width: 80, height: 80, color: Theme.of(context).colorScheme.surface,
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
                                    'Rp ${oCcy.format(cartItem.price * cartItem.quantity)}',
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
            if (order.shippingAddress != null) 
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
                      _buildInfoRow(context, 'Penerima:', order.shippingAddress!['fullName'] ?? 'N/A'),
                      _buildInfoRow(context, 'Telepon:', order.shippingAddress!['phoneNumber'] ?? 'N/A'),
                      _buildInfoRow(context, 'Alamat:', order.shippingAddress!['address'] ?? 'N/A'),
                      _buildInfoRow(context, 'Kota:', order.shippingAddress!['city'] ?? 'N/A'),
                      _buildInfoRow(context, 'Kode Pos:', order.shippingAddress!['postalCode'] ?? 'N/A'),
                    ],
                  ),
                ),
              ),
            if (order.paymentMethod != null)
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
                      _buildInfoRow(context, 'Metode:', order.paymentMethod!),
                    ],
                  ),
                ),
              ),
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'shipped':
        return Colors.blue.shade700;
      case 'delivered':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
} 