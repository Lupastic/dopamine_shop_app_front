import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.dio.get('/orders');
      setState(() {
        _orders = (response.data as List<dynamic>).reversed.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Мои заказы'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _loading && _orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? _buildEmptyOrders()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = _orders[index] as Map<String, dynamic>;
                      return _buildOrderCard(order);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'У вас пока нет заказов',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'PROCESSING':
        return 'В обработке';
      case 'SORTING':
        return 'Сортировка';
      case 'IN_TRANSIT':
        return 'В пути';
      case 'ARRIVED':
      case 'COMPLETED':
        return 'Доставлен';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PROCESSING':
        return Colors.blue;
      case 'SORTING':
        return Colors.orange;
      case 'IN_TRANSIT':
        return Colors.deepPurple;
      case 'ARRIVED':
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final color = _getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ от ${order['placedAt']?.toString().split('T')[0] ?? 'недавно'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _translateStatus(status),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${order['totalAmount']} ${order['currency'] ?? '₸'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            const Text(
              'История статусов:',
              style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final step in (order['statusHistory'] as List<dynamic>? ?? []))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${_translateStatus(step['status'] ?? '')} - ${step['changedAt']?.toString().split('T')[0] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
