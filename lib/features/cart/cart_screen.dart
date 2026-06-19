import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../profile/models/user_address.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? _cart;
  List<UserAddress> _addresses = [];
  UserAddress? _selectedAddress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cartResponse = await ApiClient.instance.dio.get('/cart');
      final addresses = await ApiClient.instance.getMyAddresses();
      
      setState(() {
        _cart = cartResponse.data as Map<String, dynamic>;
        _addresses = addresses;
        _selectedAddress = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkout() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите адрес доставки')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiClient.instance.checkout(_selectedAddress!.id);
      if (!mounted) return;
      
      _showSuccessAnimation();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при оформлении заказа')),
        );
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Заказ успешно оформлен!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Мы уже начали готовить вашу посылку.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/orders');
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Перейти к заказам'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeItem(String productId) async {
    try {
      await ApiClient.instance.dio.delete('/cart/items/$productId');
      _loadData();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final items = (_cart?['items'] as List<dynamic>?) ?? [];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Корзина'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading && _cart == null
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? _buildEmptyCart()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAddressSection(),
                      const SizedBox(height: 16),
                      ...items.map((item) => _buildCartItem(item as Map<String, dynamic>)),
                      _buildSummary(),
                    ],
                  ),
      ),
      bottomNavigationBar: items.isNotEmpty ? _buildBottomAction() : null,
    );
  }

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _showAddressPicker(),
        leading: const Icon(Icons.location_on_outlined, color: Colors.red),
        title: const Text('Адрес доставки', style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          _selectedAddress != null 
            ? '${_selectedAddress!.city}, ${_selectedAddress!.street}'
            : 'Выберите адрес доставки',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Выберите адрес', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_addresses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('У вас нет сохраненных адресов', textAlign: TextAlign.center),
              ),
            ..._addresses.map((addr) => ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(addr.label ?? 'Адрес'),
              subtitle: Text('${addr.city}, ${addr.street}'),
              onTap: () {
                setState(() => _selectedAddress = addr);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/addresses');
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить новый адрес'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('В корзине пока пусто', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/feed'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Перейти к покупкам'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (item['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(imageUrl: item['imageUrl'], width: 60, height: 60, fit: BoxFit.cover),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] ?? 'Товар', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${item['lineTotal']} ₸', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), onPressed: () => _removeItem(item['productId'])),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSummaryRow('Товары', '${_cart?['totalAmount'] ?? 0} ₸'),
          _buildSummaryRow('Доставка', 'Бесплатно', isGreen: true),
          const Divider(height: 24),
          _buildSummaryRow('Итого', '${_cart?['totalAmount'] ?? 0} ₸', isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : null)),
          Text(value, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : null, color: isGreen ? Colors.green : null)),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: FilledButton(
          onPressed: _loading ? null : _checkout,
          style: FilledButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text('Оформить заказ на ${_cart?['totalAmount'] ?? 0} ₸'),
        ),
      ),
    );
  }
}
