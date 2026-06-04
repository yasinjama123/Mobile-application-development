import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import 'product_detail_screen.dart';

class PriceTrendsScreen extends StatefulWidget {
  const PriceTrendsScreen({super.key});
  @override
  State<PriceTrendsScreen> createState() => _PriceTrendsScreenState();
}

class _PriceTrendsScreenState extends State<PriceTrendsScreen> {
  String _filter = 'all';

  List<Product> _filtered(List<Product> all) {
    switch (_filter) {
      case 'rising':  return all.where((p) => p.isPriceRising).toList();
      case 'falling': return all.where((p) => p.isPriceFalling).toList();
      case 'stable':  return all.where((p) => !p.isPriceRising && !p.isPriceFalling).toList();
      default:        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(title: const Text('Price Trends'), backgroundColor: Colors.white),
      body: StreamBuilder<List<Product>>(
        stream: db.productsStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary));
          }
          final all = snap.data ?? [];
          final filtered = _filtered(all);

          return Column(children: [
            // Summary row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(children: [
                _TrendSummary(label: 'Rising',
                    count: all.where((p) => p.isPriceRising).length,
                    color: AppColors.accent, icon: Icons.trending_up_rounded),
                const SizedBox(width: 8),
                _TrendSummary(label: 'Falling',
                    count: all.where((p) => p.isPriceFalling).length,
                    color: AppColors.primary, icon: Icons.trending_down_rounded),
                const SizedBox(width: 8),
                _TrendSummary(
                    label: 'Stable',
                    count: all.where((p) => !p.isPriceRising && !p.isPriceFalling).length,
                    color: AppColors.gray400, icon: Icons.trending_flat_rounded),
              ]),
            ),
            // Filter tabs
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  for (final f in [
                    ['all', 'All'], ['rising', '📈 Rising'],
                    ['falling', '📉 Falling'], ['stable', '➡️ Stable'],
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f[0]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(
                              color: _filter == f[0] ? AppColors.primary : Colors.transparent,
                              width: 2))),
                          child: Text(f[1], textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                  color: _filter == f[0] ? AppColors.primary : AppColors.gray400)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No products in this category',
                      style: TextStyle(color: AppColors.gray400)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (c, i) => _TrendCard(
                        product: filtered[i],
                        onTap: () => Navigator.push(c, MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: filtered[i]))),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _TrendSummary extends StatelessWidget {
  final String label; final int count; final Color color; final IconData icon;
  const _TrendSummary({required this.label, required this.count,
      required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
      ]),
    ),
  );
}

class _TrendCard extends StatelessWidget {
  final Product product; final VoidCallback onTap;
  const _TrendCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final history = product.priceHistory;
    final spots = history.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.price)).toList();
    final lineColor = product.isPriceRising ? AppColors.accent : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              Text(product.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: AppColors.gray800)),
                Text('${product.unit} · ${product.reportCount} reports',
                    style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('ETB ${product.avgPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.gray800)),
                const SizedBox(height: 3),
                TrendBadge(changePercent: product.changePercent),
              ]),
            ]),
            if (spots.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: LineChart(LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [LineChartBarData(
                    spots: spots, isCurved: true, curveSmoothness: 0.35,
                    color: lineColor, barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true,
                        color: lineColor.withOpacity(0.07)),
                  )],
                  lineTouchData: const LineTouchData(enabled: false),
                )),
              ),
            ],
            const SizedBox(height: 8),
            Row(children: [
              _RangePill(label: 'Low', value: 'ETB ${product.minPrice.toStringAsFixed(0)}',
                  color: AppColors.primary),
              const SizedBox(width: 6),
              _RangePill(label: 'High', value: 'ETB ${product.maxPrice.toStringAsFixed(0)}',
                  color: AppColors.accent),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: AppColors.gray400, size: 18),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  final String label, value; final Color color;
  const _RangePill({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}
