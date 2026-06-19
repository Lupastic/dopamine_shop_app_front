import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final response = await ApiClient.instance.dio.get('/users/me/stats');
    setState(() => _stats = response.data as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final categories = (_stats?['favoriteCategories'] as List<dynamic>?) ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved total',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_stats?['totalSavedAmount'] ?? 0} KZT',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_stats?['totalOrdersCount'] ?? 0} simulated orders',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Адреса доставки'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/addresses'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('История заказов'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/orders'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Favorite categories',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final category in categories)
                  Chip(label: Text(category.toString())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
