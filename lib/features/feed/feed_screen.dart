import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/network/api_client.dart';
import 'product.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _products = <Product>[];
  final _recentProducts = <Product>[];
  final _discountProducts = <Product>[];
  String? _cursor;
  bool _loading = true;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _products.clear();
      _cursor = null;
    });
    try {
      final response = await ApiClient.instance.dio.get(
        '/products',
        queryParameters: {
          if (_selectedCategoryId != null) 'category': _selectedCategoryId,
        },
      );
      final items = (response.data['items'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _products.addAll(items);
        if (_discountProducts.isEmpty) {
          _discountProducts.addAll(items.where((p) => p.exclusive).toList());
        }
        _cursor = response.data['nextCursor'] as String?;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_cursor == null || _loading) return;
    setState(() => _loading = true);
    final response = await ApiClient.instance.dio.get(
      '/products',
      queryParameters: {
        'cursor': _cursor,
        if (_selectedCategoryId != null) 'category': _selectedCategoryId,
      },
    );
    final items = (response.data['items'] as List<dynamic>)
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
    setState(() {
      _products.addAll(items);
      _cursor = response.data['nextCursor'] as String?;
      _loading = false;
    });
  }

  void _onProductTap(Product product) {
    setState(() {
      if (!_recentProducts.any((p) => p.id == product.id)) {
        _recentProducts.insert(0, product);
        if (_recentProducts.length > 10) _recentProducts.removeLast();
      }
    });
    context.push('/product-details', extra: product);
  }

  void _selectCategory(String id, String name) {
    if (_selectedCategoryId == id) {
      setState(() {
        _selectedCategoryId = null;
        _selectedCategoryName = null;
      });
    } else {
      setState(() {
        _selectedCategoryId = id;
        _selectedCategoryName = name;
      });
    }
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            _buildBanners(),
            _buildCategories(),
            if (_recentProducts.isNotEmpty)
              _buildHorizontalSection('Вы недавно смотрели', _recentProducts),
            _buildHorizontalSection('Большие скидки', _discountProducts),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  _selectedCategoryName != null
                      ? 'Категория: $_selectedCategoryName'
                      : 'Рекомендации для вас',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_loading && _products.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _buildRecommendationsGrid(),
            if (_cursor != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FilledButton(
                    onPressed: _loading ? null : _loadMore,
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Показать еще'),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.location_on_outlined, color: Colors.black),
              onPressed: () => context.push('/addresses'),
            ),
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) => _loadInitialData(),
                  decoration: const InputDecoration(
                    hintText: 'Поиск в Магазине',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Icon(Icons.camera_alt_outlined, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanners() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: PageView(
          children: [
            _buildBannerCard(
              'Жума Мубарак',
              'Специальные предложения к пятнице',
              const Color(0xFF006D35),
            ),
            _buildBannerCard(
              'Электроника',
              'Кэшбэк до 10% на все гаджеты',
              const Color(0xFFE31E24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard(String title, String sub, Color color,
      {Color textColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
                color: textColor, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'id': 'mens-shirts', 'name': 'Одежда', 'icon': Icons.checkroom},
      {'id': 'mens-shoes', 'name': 'Обувь', 'icon': Icons.ice_skating},
      {'id': 'laptops', 'name': 'Ноутбуки', 'icon': Icons.laptop},
      {'id': 'mens-watches', 'name': 'Часы', 'icon': Icons.watch},
      {'id': 'mobile-accessories', 'name': 'Аксессуары', 'icon': Icons.headphones},
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final id = cat['id'] as String;
            final name = cat['name'] as String;
            final isSelected = _selectedCategoryId == id;
            return GestureDetector(
              onTap: () => _selectCategory(id, name),
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[100] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        size: 28,
                        color: isSelected ? Colors.red : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.red : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHorizontalSection(String title, List<Product> items) {
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ProductCard(
                    product: items[index],
                    compact: true,
                    onTap: () => _onProductTap(items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childCount: _products.length,
        itemBuilder: (context, index) {
          return _ProductCard(
            product: _products[index],
            onTap: () => _onProductTap(_products[index]),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, this.compact = false, required this.onTap});

  final Product product;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.8 * 255).toInt()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, color: Colors.black54, size: 18),
                  ),
                ),
                if (product.exclusive)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '-20%',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.price} ₸',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 2),
                      const Text(
                        '5.0',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(124)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
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
