import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'top_deals_screen.dart';
import 'leaderboard_screen.dart';
import 'barcode_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db   = context.read<AppProvider>().db;
    final user = context.watch<AppProvider>().appUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _AppBar(user: user),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Live stats - real Firestore counts
              _LiveStats(),
              const SizedBox(height: 16),

              // Quick action row
              _QuickActions(),
              const SizedBox(height: 20),

              // Top Deals - live stream
              SectionHeader(
                title: '🏷️ Top Deals Today',
                actionLabel: 'See all',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TopDealsScreen())),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Product>>(
                stream: db.topCheapestStream(limit: 3),
                builder: (_, snap) {
                  if (!snap.hasData || snap.data!.isEmpty) return const _Shimmer(height: 120);
                  return _TopDealsRow(products: snap.data!);
                },
              ),
              const SizedBox(height: 20),

              // Trending - live
              SectionHeader(
                title: 'Trending Products',
                actionLabel: 'See all',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Product>>(
                stream: db.productsStream(),
                builder: (_, snap) {
                  if (!snap.hasData || snap.data!.isEmpty) return const _Shimmer(height: 220);
                  return _TrendingCard(products: snap.data!.take(4).toList());
                },
              ),
              const SizedBox(height: 20),

              // Price trend chart - live
              StreamBuilder<List<Product>>(
                stream: db.productsStream(),
                builder: (_, snap) {
                  if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SectionHeader(
                      title: '${snap.data!.first.emoji} ${snap.data!.first.name} — 30 Days',
                      actionLabel: 'All trends',
                      onAction: () {},
                    ),
                    const SizedBox(height: 10),
                    _TrendChart(product: snap.data!.first),
                    const SizedBox(height: 20),
                  ]);
                },
              ),

              // Recent activity - live with timestamps
              SectionHeader(
                title: 'Recent Activity',
                actionLabel: 'Leaderboard',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<PriceReport>>(
                stream: db.recentReportsStream(),
                builder: (_, snap) {
                  if (!snap.hasData || snap.data!.isEmpty) return const _Shimmer(height: 180);
                  final reports = snap.data!.take(5).toList();
                  return Card(
                    child: Column(
                      children: reports.asMap().entries.map((e) => Column(children: [
                        ActivityItem(report: e.value),
                        if (e.key < reports.length - 1)
                          const Divider(indent: 58),
                      ])).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Map preview
              SectionHeader(
                title: '📍 Shops Map',
                actionLabel: 'Open map',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MapScreen())),
              ),
              const SizedBox(height: 10),
              _MapPreview(),
              const SizedBox(height: 20),

              // Nearby shops - live
              SectionHeader(
                title: 'Nearby Shops',
                actionLabel: 'View all',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MapScreen())),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Shop>>(
                stream: db.shopsStream(),
                builder: (_, snap) {
                  if (!snap.hasData) return const _Shimmer(height: 160);
                  final shops = snap.data!.take(4).toList();
                  return Card(
                    child: Column(
                      children: shops.asMap().entries.map((e) => Column(children: [
                        ShopTile(
                          shop: e.value,
                          isBestPrice: e.key == 0,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  MapScreen(focusShop: e.value))),
                        ),
                        if (e.key < shops.length - 1) const Divider(indent: 62),
                      ])).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ])),
          ),
        ],
      ),
    );
  }
}

// ── App Bar ────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final AppUser? user;
  const _AppBar({required this.user});

  @override
  Widget build(BuildContext context) => SliverAppBar(
    floating: true, snap: true, elevation: 0,
    scrolledUnderElevation: 0.5, titleSpacing: 0,
    title: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.currency_exchange_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('FairPrice', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          Text(user != null
              ? 'Hi, ${user!.displayName.split(' ').first} 👋'
              : 'BirrWise · Addis Ababa',
              style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
        ]),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner_rounded),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BarcodeScannerScreen())),
        ),
      ]),
    ),
  );
}

// ── Live Stats ────────────────────────────────────────────────────────────
class _LiveStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return Row(children: [
      Expanded(child: StreamBuilder<List<Product>>(
        stream: db.productsStream(),
        builder: (_, s) => _StatCard(
          label: 'Products',
          value: s.hasData ? '${s.data!.length}' : '—',
          icon: Icons.inventory_2_outlined,
          color: AppColors.primary,
        ),
      )),
      const SizedBox(width: 8),
      Expanded(child: StreamBuilder<List<Shop>>(
        stream: db.shopsStream(),
        builder: (_, s) => _StatCard(
          label: 'Shops',
          value: s.hasData ? '${s.data!.length}' : '—',
          icon: Icons.store_outlined,
          color: AppColors.blue,
        ),
      )),
      const SizedBox(width: 8),
      Expanded(child: StreamBuilder<List<PriceReport>>(
        stream: db.recentReportsStream(),
        builder: (_, s) => _StatCard(
          label: 'Reports',
          value: s.hasData ? '${s.data!.length}+' : '—',
          icon: Icons.receipt_long_outlined,
          color: AppColors.amber,
        ),
      )),
      const SizedBox(width: 8),
      Expanded(child: StreamBuilder<List<Shop>>(
        stream: db.shopsStream(),
        builder: (_, s) {
          final open = s.data?.where((sh) => sh.isOpen).length ?? 0;
          return _StatCard(
            label: 'Open Now',
            value: s.hasData ? '$open' : '—',
            icon: Icons.circle,
            color: AppColors.primary,
            iconSize: 10,
          );
        },
      )),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final double iconSize;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color, this.iconSize = 18});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.15), width: 0.5),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: iconSize),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
          color: color, letterSpacing: -0.3)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
    ]),
  );
}

// ── Quick Actions ─────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    _QBtn(icon: Icons.qr_code_scanner_rounded, label: 'Scan',
        color: AppColors.blue,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()))),
    const SizedBox(width: 8),
    _QBtn(icon: Icons.local_offer_outlined, label: 'Deals',
        color: AppColors.primary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TopDealsScreen()))),
    const SizedBox(width: 8),
    _QBtn(icon: Icons.map_outlined, label: 'Map',
        color: AppColors.amber,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MapScreen()))),
    const SizedBox(width: 8),
    _QBtn(icon: Icons.emoji_events_outlined, label: 'Rank',
        color: AppColors.accent,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
  ]);
}

class _QBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QBtn({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    ),
  );
}

// ── Top Deals Row ─────────────────────────────────────────────────────────
class _TopDealsRow extends StatelessWidget {
  final List<Product> products;
  const _TopDealsRow({required this.products});
  @override
  Widget build(BuildContext context) => Row(
    children: products.asMap().entries.map((e) {
      final p = e.value;
      final medal = ['🥇', '🥈', '🥉'][e.key];
      return Expanded(child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: p))),
        child: Container(
          margin: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: e.key == 0
                    ? AppColors.amber.withOpacity(0.4)
                    : const Color(0x14000000),
                width: e.key == 0 ? 1.0 : 0.5),
          ),
          child: Column(children: [
            Text(medal, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(p.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(p.name, style: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('ETB ${p.avgPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 2),
            TrendBadge(changePercent: p.changePercent),
          ]),
        ),
      ));
    }).toList(),
  );
}

// ── Trending Card ─────────────────────────────────────────────────────────
class _TrendingCard extends StatelessWidget {
  final List<Product> products;
  const _TrendingCard({required this.products});
  @override
  Widget build(BuildContext context) => Card(
    child: Column(children: products.asMap().entries.map((e) => Column(children: [
      ProductListTile(
        product: e.value,
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: e.value))),
      ),
      if (e.key < products.length - 1) const Divider(indent: 70),
    ])).toList()),
  );
}

// ── Trend Chart ───────────────────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  final Product product;
  const _TrendChart({required this.product});
  @override
  Widget build(BuildContext context) {
    final h = product.priceHistory;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            TrendBadge(changePercent: product.changePercent),
            const Spacer(),
            Text('${h.length} data points',
                style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
          ]),
          const SizedBox(height: 12),
          SizedBox(height: 130,
            child: h.length < 2
                ? const Center(child: Column(
                    mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bar_chart_rounded, color: AppColors.gray100, size: 40),
                    Text('Not enough data yet',
                        style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                  ]))
                : LineChart(LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                            color: Color(0x0C000000), strokeWidth: 0.5)),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 46,
                          getTitlesWidget: (v, _) => Text(
                              'ETB ${v.toInt()}',
                              style: const TextStyle(fontSize: 9, color: AppColors.gray400)))),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, interval: 7,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= h.length) return const SizedBox.shrink();
                            final d = h[i].date;
                            return Text('${d.month}/${d.day}',
                                style: const TextStyle(fontSize: 9, color: AppColors.gray400));
                          })),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [LineChartBarData(
                      spots: h.asMap().entries.map((e) =>
                          FlSpot(e.key.toDouble(), e.value.price)).toList(),
                      isCurved: true, curveSmoothness: 0.35,
                      color: AppColors.primary, barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true,
                          color: AppColors.primary.withOpacity(0.07)),
                    )],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.gray800,
                        getTooltipItems: (s) => s.map((sp) => LineTooltipItem(
                            'ETB ${sp.y.toStringAsFixed(0)}',
                            const TextStyle(color: Colors.white, fontSize: 11,
                                fontWeight: FontWeight.w600))).toList()),
                    ),
                  )),
          ),
        ]),
      ),
    );
  }
}

// ── Map Preview ───────────────────────────────────────────────────────────
class _MapPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const MapScreen())),
    child: Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 0.5),
      ),
      child: Stack(children: [
        // Fake map grid lines
        Positioned.fill(child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CustomPaint(painter: _MapGridPainter()),
        )),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12)]),
            child: const Icon(Icons.map_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          const Text('View shops on interactive map',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark)),
          const Text('OpenStreetMap · GPS-powered',
              style: TextStyle(fontSize: 11, color: AppColors.primary)),
        ])),
        // Pin decorations
        ...List.generate(5, (i) => Positioned(
          left: 30.0 + i * 55,
          top: 20.0 + (i % 2 == 0 ? 10 : 40),
          child: const Icon(Icons.location_on_rounded,
              color: AppColors.primary, size: 18),
        )),
      ]),
    ),
  );
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.08)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Shimmer placeholder ───────────────────────────────────────────────────
class _Shimmer extends StatelessWidget {
  final double height;
  const _Shimmer({required this.height});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
        color: AppColors.gray50, borderRadius: BorderRadius.circular(14)),
    child: const Center(child: CircularProgressIndicator(
        strokeWidth: 2, color: AppColors.primary)),
  );
}
