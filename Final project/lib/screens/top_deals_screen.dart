import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import 'product_detail_screen.dart';

class TopDealsScreen extends StatelessWidget {
  const TopDealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏷️ Top Cheapest Products'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: db.topCheapestStream(limit: 20),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary));
          }
          final products = snap.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No data yet',
                style: TextStyle(color: AppColors.gray400)));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Text('💚', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'These are today\'s best-value products sorted by lowest average price reported by the community.',
                    style: TextStyle(fontSize: 13, color: AppColors.primaryDark, height: 1.4),
                  )),
                ]),
              ),
              const SizedBox(height: 16),
              // Top 3 highlight
              ...products.take(3).toList().asMap().entries.map((e) {
                final p     = e.value;
                final medal = e.key == 0 ? '🥇' : e.key == 1 ? '🥈' : '🥉';
                return GestureDetector(
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(e.key == 0 ? 0.12 : 0.06),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2), width: 0.5),
                    ),
                    child: Row(children: [
                      Text(medal, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Text(p.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(p.name, style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppColors.gray800)),
                        Text('${p.category} · ${p.unit}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.gray400)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('ETB ${p.avgPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        Text('Min: ETB ${p.minPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.gray400)),
                        TrendBadge(changePercent: p.changePercent),
                      ]),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 8),
              // Rest of the list
              Card(
                child: Column(
                  children: products.skip(3).toList().asMap().entries.map((e) {
                    final p   = e.value;
                    final num = e.key + 4;
                    return Column(children: [
                      ListTile(
                        leading: Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(width: 24,
                              child: Text('#$num', style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppColors.gray400))),
                          const SizedBox(width: 4),
                          Text(p.emoji, style: const TextStyle(fontSize: 20)),
                        ]),
                        title: Text(p.name, style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text(p.unit,
                            style: const TextStyle(fontSize: 11)),
                        trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Text('ETB ${p.avgPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          TrendBadge(changePercent: p.changePercent),
                        ]),
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: p))),
                      ),
                      if (e.key < products.length - 4)
                        const Divider(indent: 60),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
