import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import 'report_price_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _checkFav();
  }

  Future<void> _checkFav() async {
    final isFav = await context.read<AppProvider>().local
        .isFavorite(widget.product.id);
    if (mounted) setState(() => _isFav = isFav);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return StreamBuilder<Product?>(
      stream: provider.db.productStream(widget.product.id),
      builder: (ctx, snap) {
        final p = snap.data ?? widget.product;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 200, pinned: true,
                actions: [
                  // Favorite toggle
                  IconButton(
                    icon: Icon(_isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFav ? AppColors.accent : AppColors.gray800),
                    onPressed: () async {
                      final local = provider.local;
                      if (_isFav) { await local.removeFavorite(p.id); }
                      else        { await local.addFavorite(p.id); }
                      setState(() => _isFav = !_isFav);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(_isFav
                              ? '${p.name} added to favorites'
                              : '${p.name} removed from favorites'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.gray800,
                        ));
                      }
                    },
                  ),
                  // Watchlist
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.gray800),
                    onPressed: () => _showWatchlistDialog(context, provider, p),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(height: 60),
                      Text(p.emoji, style: const TextStyle(fontSize: 52)),
                      const SizedBox(height: 8),
                      Text(p.name, style: const TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${p.category} · ${p.unit}',
                            style: const TextStyle(fontSize: 13, color: AppColors.gray400)),
                        if (p.barcode != null) ...[
                          const Text(' · ', style: TextStyle(color: AppColors.gray400)),
                          const Icon(Icons.qr_code_rounded,
                              size: 13, color: AppColors.gray400),
                          const SizedBox(width: 2),
                          Text(p.barcode!, style: const TextStyle(
                              fontSize: 11, color: AppColors.gray400,
                              fontFamily: 'monospace')),
                        ],
                      ]),
                    ]),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _priceSummary(p)),
              SliverPersistentHeader(pinned: true,
                delegate: _TabBarDelegate(TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.gray400,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [Tab(text: 'Price Trend'), Tab(text: 'Shops'), Tab(text: 'Reports')],
                )),
              ),
            ],
            body: TabBarView(
              controller: _tabs,
              children: [
                _PriceTrendTab(product: p),
                _ShopsTab(product: p),
                _ReportsTab(product: p),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ReportPriceScreen(product: p))),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Report a Price'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _priceSummary(Product p) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(children: [
        Expanded(child: _PriceStat('Lowest',   'ETB ${p.minPrice.toStringAsFixed(0)}', AppColors.primary)),
        Container(width: 0.5, height: 40, color: AppColors.gray100),
        Expanded(child: _PriceStat('Average',  'ETB ${p.avgPrice.toStringAsFixed(0)}', AppColors.gray800)),
        Container(width: 0.5, height: 40, color: AppColors.gray100),
        Expanded(child: _PriceStat('Highest',  'ETB ${p.maxPrice.toStringAsFixed(0)}', AppColors.accent)),
        Container(width: 0.5, height: 40, color: AppColors.gray100),
        Expanded(child: _PriceStat('Save up to',
            'ETB ${(p.maxPrice - p.minPrice).toStringAsFixed(0)}', AppColors.amber)),
      ]),
    );
  }

  void _showWatchlistDialog(BuildContext context, AppProvider provider, Product p) {
    final uid = provider.firebaseUser?.uid;
    if (uid == null) return;
    final ctrl = TextEditingController(
        text: (p.avgPrice * 0.95).toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Watch ${p.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Current avg: ETB ${p.avgPrice.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.gray400)),
          const SizedBox(height: 12),
          TextField(controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Alert me when price drops to (ETB)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final target = double.tryParse(ctrl.text);
              if (target == null) return;
              await provider.db.addWatchlistItem(
                uid: uid, productId: p.id, productName: p.name,
                emoji: p.emoji, targetPrice: target, currentPrice: p.avgPrice,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Price alert set!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Set Alert'),
          ),
        ],
      ),
    );
  }
}

class _PriceStat extends StatelessWidget {
  final String label, value; final Color color;
  const _PriceStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
  ]);
}

// ── Price Trend Tab ───────────────────────────────────────────────────────
class _PriceTrendTab extends StatefulWidget {
  final Product product;
  const _PriceTrendTab({required this.product});
  @override
  State<_PriceTrendTab> createState() => _PriceTrendTabState();
}

class _PriceTrendTabState extends State<_PriceTrendTab> {
  int _days = 30;
  @override
  Widget build(BuildContext context) {
    final history = widget.product.priceHistory;
    final slice = history.length > _days
        ? history.sublist(history.length - _days) : history;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (final d in [7, 14, 30])
            Padding(padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _days = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _days == d ? AppColors.primary : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _days == d
                        ? AppColors.primary : const Color(0x18000000), width: 0.5)),
                  child: Text('${d}d', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _days == d ? Colors.white : AppColors.gray400)),
                ),
              ),
            ),
          const Spacer(),
          TrendBadge(changePercent: widget.product.changePercent),
        ]),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16),
          child: SizedBox(height: 200,
            child: slice.length < 2
                ? const Center(child: Text('Not enough data yet',
                    style: TextStyle(color: AppColors.gray400)))
                : LineChart(LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                            color: Color(0x0C000000), strokeWidth: 0.5)),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                          reservedSize: 46, getTitlesWidget: (v, _) =>
                              Text('ETB ${v.toInt()}', style: const TextStyle(
                                  fontSize: 9, color: AppColors.gray400)))),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                          interval: (_days / 4).ceilToDouble(),
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= slice.length) return const SizedBox.shrink();
                            final d = slice[i].date;
                            return Text('${d.month}/${d.day}', style: const TextStyle(
                                fontSize: 9, color: AppColors.gray400));
                          })),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [LineChartBarData(
                      spots: slice.asMap().entries.map((e) =>
                          FlSpot(e.key.toDouble(), e.value.price)).toList(),
                      isCurved: true, curveSmoothness: 0.3,
                      color: AppColors.primary, barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true,
                          color: AppColors.primary.withOpacity(0.07)),
                    )],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.gray800,
                        getTooltipItems: (spots) => spots.map((s) =>
                            LineTooltipItem('ETB ${s.y.toStringAsFixed(0)}',
                                const TextStyle(color: Colors.white, fontSize: 11,
                                    fontWeight: FontWeight.w600))).toList()),
                    ),
                  )),
          ),
        )),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Analysis', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (slice.isNotEmpty) ...[
              _Row('Period low',  'ETB ${slice.map((p)=>p.price).reduce((a,b)=>a<b?a:b).toStringAsFixed(0)}', AppColors.primary),
              const Divider(height: 16),
              _Row('Period high', 'ETB ${slice.map((p)=>p.price).reduce((a,b)=>a>b?a:b).toStringAsFixed(0)}', AppColors.accent),
              const Divider(height: 16),
            ],
            _Row('Total reports', '${widget.product.reportCount}', AppColors.blue),
          ]),
        )),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String l, v; final Color c;
  const _Row(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(l, style: const TextStyle(fontSize: 13, color: AppColors.gray400)),
    const Spacer(),
    Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
  ]);
}

// ── Shops Tab ─────────────────────────────────────────────────────────────
class _ShopsTab extends StatelessWidget {
  final Product product;
  const _ShopsTab({required this.product});
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return StreamBuilder<List<Shop>>(
      stream: db.shopsForProductStream(product.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary));
        }
        final shops = snap.data ?? [];
        if (shops.isEmpty) return const Center(child: Text('No shop data yet',
            style: TextStyle(color: AppColors.gray400)));
        final best  = shops.first.prices[product.id] ?? 0;
        final worst = shops.last.prices[product.id]  ?? 0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.savings_rounded, color: AppColors.primaryDark, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Buying at cheapest saves ETB ${(worst - best).toStringAsFixed(0)} vs most expensive',
                  style: const TextStyle(fontSize: 13, color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500))),
              ]),
            ),
            const SizedBox(height: 12),
            Card(child: Column(
              children: shops.asMap().entries.map((e) => Column(children: [
                ShopTile(shop: e.value, productId: product.id, isBestPrice: e.key == 0),
                if (e.key < shops.length - 1) const Divider(indent: 62),
              ])).toList(),
            )),
          ]),
        );
      },
    );
  }
}

// ── Reports Tab ──────────────────────────────────────────────────────────
class _ReportsTab extends StatelessWidget {
  final Product product;
  const _ReportsTab({required this.product});
  @override
  Widget build(BuildContext context) {
    final db  = context.read<AppProvider>().db;
    final uid = context.read<AppProvider>().firebaseUser?.uid;
    return StreamBuilder<List<PriceReport>>(
      stream: db.reportsForProductStream(product.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary));
        }
        final reports = snap.data ?? [];
        if (reports.isEmpty) return Center(child: Column(
            mainAxisSize: MainAxisSize.min, children: const [
          Text('📋', style: TextStyle(fontSize: 40)),
          SizedBox(height: 10),
          Text('No reports yet', style: TextStyle(fontSize: 15,
              color: AppColors.gray400, fontWeight: FontWeight.w500)),
          Text('Be the first to report a price!',
              style: TextStyle(fontSize: 13, color: AppColors.gray400)),
        ]));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _ReportTile(report: reports[i],
              currentUid: uid, onVote: (isAccurate) async {
            if (uid == null) return;
            await db.voteOnReport(reports[i].id, uid, isAccurate);
          }),
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  final PriceReport report;
  final String? currentUid;
  final void Function(bool) onVote;
  const _ReportTile({required this.report, required this.currentUid, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final isOwn = currentUid == report.reporterUid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(report.reporterName, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
            Text(timeago.format(report.reportedAt),
                style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('ETB ${report.price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            Text(report.shopName, style: const TextStyle(
                fontSize: 11, color: AppColors.gray400)),
          ]),
        ]),
        if (report.note != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8)),
            child: Text(report.note!, style: const TextStyle(
                fontSize: 12, color: AppColors.gray400)),
          ),
        ],
        const SizedBox(height: 8),
        // Verification votes
        if (!isOwn) Row(children: [
          const Text('Is this accurate?',
              style: TextStyle(fontSize: 12, color: AppColors.gray400)),
          const SizedBox(width: 8),
          _VoteBtn(label: '👍 ${report.verifyCount}',
              color: AppColors.primary, onTap: () => onVote(true)),
          const SizedBox(width: 6),
          _VoteBtn(label: '👎 ${report.noCount}',
              color: AppColors.accent, onTap: () => onVote(false)),
        ]) else
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 14),
            const SizedBox(width: 4),
            Text('${report.verifyCount} verified · ${report.noCount} disputed',
                style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
          ]),
      ]),
    );
  }
}

class _VoteBtn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _VoteBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5)),
      child: Text(label, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w500, color: color)),
    ),
  );
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Theme.of(context).colorScheme.surface, child: tabBar);
  @override double get maxExtent => tabBar.preferredSize.height;
  @override double get minExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(_) => false;
}
