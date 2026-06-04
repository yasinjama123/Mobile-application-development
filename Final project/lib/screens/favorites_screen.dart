import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> _favoriteIds = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await context.read<AppProvider>().local.getFavoriteIds();
    setState(() => _favoriteIds = ids);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Products')),
      body: _favoriteIds.isEmpty
          ? _buildEmpty()
          : StreamBuilder<List<Product>>(
              stream: db.productsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary));
                }
                final all = snap.data ?? [];
                final favs = all.where((p) => _favoriteIds.contains(p.id)).toList();
                if (favs.isEmpty) return _buildEmpty();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('${favs.length} saved product${favs.length != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: favs.asMap().entries.map((e) {
                          final p = e.value;
                          return Column(children: [
                            Dismissible(
                              key: Key(p.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.favorite_border_rounded,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                await context.read<AppProvider>().local
                                    .removeFavorite(p.id);
                                await _load();
                              },
                              child: ProductListTile(
                                product: p,
                                onTap: () => Navigator.push(ctx,
                                    MaterialPageRoute(builder: (_) =>
                                        ProductDetailScreen(product: p))),
                              ),
                            ),
                            if (e.key < favs.length - 1)
                              const Divider(indent: 70),
                          ]);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.blueLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Swipe left to remove a product from favorites.',
                          style: TextStyle(fontSize: 12, color: AppColors.blue),
                        )),
                      ]),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('❤️', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 16),
      const Text('No favorites yet', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
      const SizedBox(height: 6),
      const Text('Tap ❤️ on any product to save it here',
          style: TextStyle(fontSize: 13, color: AppColors.gray400)),
    ]),
  );
}
