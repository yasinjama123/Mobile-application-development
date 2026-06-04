import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query    = '';
  String _category = 'All';
  double _minPrice = 0;
  double _maxPrice = 1000;
  String _sortBy   = 'relevance'; // relevance | price_asc | price_desc | distance
  bool _showFilters = false;
  List<String> _recentSearches = [];

  static const cats = ['All','Grains','Essentials','Vegetables','Dairy','Bakery','Beverages','Meat','Other'];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final r = await context.read<AppProvider>().local.getRecentSearches();
    if (mounted) setState(() => _recentSearches = r);
  }

  Future<void> _onSearch(String v) async {
    setState(() => _query = v);
    if (v.trim().isNotEmpty) {
      await context.read<AppProvider>().local.addRecentSearch(v.trim());
    }
  }

  List<Product> _filter(List<Product> all) {
    var list = all;
    if (_category != 'All') list = list.where((p) => p.category == _category).toList();
    list = list.where((p) => p.avgPrice >= _minPrice && p.avgPrice <= _maxPrice).toList();
    switch (_sortBy) {
      case 'price_asc':  list.sort((a, b) => a.avgPrice.compareTo(b.avgPrice)); break;
      case 'price_desc': list.sort((a, b) => b.avgPrice.compareTo(a.avgPrice)); break;
      case 'distance':   list.sort((a, b) => b.reportCount.compareTo(a.reportCount)); break;
    }
    return list;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Search products, barcodes…',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray400, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.gray400, size: 18),
                    onPressed: () { _ctrl.clear(); setState(() => _query = ''); })
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true, fillColor: AppColors.gray50, contentPadding: EdgeInsets.zero,
          ),
        ),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded,
                color: _showFilters ? AppColors.primary : AppColors.gray800),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(children: [
        // Category chips
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = cats[i]; final sel = c == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? AppColors.primary : const Color(0x18000000), width: 0.5)),
                  child: Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: sel ? Colors.white : AppColors.gray400)),
                ),
              );
            },
          ),
        ),

        // Filter panel
        if (_showFilters) _buildFilters(context),

        // Sort chips
        if (_query.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SortChip(label: 'Best Match', value: 'relevance', current: _sortBy,
                    onTap: () => setState(() => _sortBy = 'relevance')),
                const SizedBox(width: 8),
                _SortChip(label: 'Cheapest', value: 'price_asc', current: _sortBy,
                    onTap: () => setState(() => _sortBy = 'price_asc')),
                const SizedBox(width: 8),
                _SortChip(label: 'Most Expensive', value: 'price_desc', current: _sortBy,
                    onTap: () => setState(() => _sortBy = 'price_desc')),
                const SizedBox(width: 8),
                _SortChip(label: 'Most Reported', value: 'distance', current: _sortBy,
                    onTap: () => setState(() => _sortBy = 'distance')),
              ],
            ),
          ),

        // Results / Recent
        Expanded(
          child: _query.isEmpty
              ? _buildRecentSearches(context)
              : StreamBuilder<List<Product>>(
                  stream: db.searchProductsStream(_query),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary));
                    }
                    final results = _filter(snap.data ?? []);
                    if (results.isEmpty) return _buildEmpty();
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(children: [
                          Text('${results.length} products',
                              style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                        ]),
                      ),
                      Expanded(
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) => const Divider(indent: 70),
                            itemBuilder: (c, i) => ProductListTile(
                              product: results[i],
                              onTap: () => Navigator.push(c, MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: results[i]))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Price Range (ETB)', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray800)),
        const SizedBox(height: 4),
        Row(children: [
          Text('ETB ${_minPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
          Expanded(
            child: RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0, max: 1000,
              divisions: 20,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() {
                _minPrice = v.start; _maxPrice = v.end;
              }),
            ),
          ),
          Text('ETB ${_maxPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
        ]),
      ]),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🔍', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Search for any product', style: TextStyle(
              fontSize: 15, color: AppColors.gray400, fontWeight: FontWeight.w500)),
        ]),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          const Text('RECENT SEARCHES', style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600, color: AppColors.gray400, letterSpacing: 0.5)),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await context.read<AppProvider>().local.clearRecentSearches();
              setState(() => _recentSearches = []);
            },
            child: const Text('Clear', style: TextStyle(
                fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: _recentSearches.asMap().entries.map((e) {
              final q = e.value;
              return Column(children: [
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: AppColors.gray400, size: 18),
                  title: Text(q, style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.north_west_rounded,
                      color: AppColors.gray400, size: 16),
                  onTap: () {
                    _ctrl.text = q;
                    _onSearch(q);
                  },
                ),
                if (e.key < _recentSearches.length - 1)
                  const Divider(indent: 52),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🔍', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text('No results for "$_query"', style: const TextStyle(
          fontSize: 15, color: AppColors.gray400, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _SortChip extends StatelessWidget {
  final String label, value, current; final VoidCallback onTap;
  const _SortChip({required this.label, required this.value,
      required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? AppColors.primary : const Color(0x18000000), width: 0.5)),
        child: Text(label, style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w500,
            color: sel ? Colors.white : AppColors.gray400)),
      ),
    );
  }
}
