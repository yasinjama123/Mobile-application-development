import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class NearbyShopsScreen extends StatefulWidget {
  const NearbyShopsScreen({super.key});
  @override
  State<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends State<NearbyShopsScreen> {
  String _sortBy = 'distance';
  Position? _position;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) { setState(() => _locating = false); return; }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() { _position = pos; _locating = false; });
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<Shop> _sort(List<Shop> shops) {
    final list = List<Shop>.from(shops);
    if (_sortBy == 'distance' && _position != null) {
      list.sort((a, b) {
        final da = Geolocator.distanceBetween(
            _position!.latitude, _position!.longitude, a.lat, a.lng);
        final db = Geolocator.distanceBetween(
            _position!.latitude, _position!.longitude, b.lat, b.lng);
        return da.compareTo(db);
      });
    } else if (_sortBy == 'rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'reports') {
      list.sort((a, b) => b.reportCount.compareTo(a.reportCount));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Shops')),
      body: Column(children: [
        // Location banner
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            GestureDetector(
              onTap: _getLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_locating)
                    const SizedBox(width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: AppColors.primary))
                  else
                    const Icon(Icons.my_location_rounded,
                        color: AppColors.primary, size: 14),
                  const SizedBox(width: 5),
                  Text(_position != null
                      ? '${_position!.latitude.toStringAsFixed(3)}, ${_position!.longitude.toStringAsFixed(3)}'
                      : 'Tap to get location',
                      style: const TextStyle(fontSize: 12,
                          color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
            const Spacer(),
            const Text('Addis Ababa, ETH',
                style: TextStyle(fontSize: 12, color: AppColors.gray400)),
          ]),
        ),
        // Sort chips
        SizedBox(height: 48,
          child: ListView(scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _Chip(label: 'Nearest',     icon: Icons.near_me_rounded,  sel: _sortBy=='distance', onTap: ()=>setState(()=>_sortBy='distance')),
              const SizedBox(width: 8),
              _Chip(label: 'Top Rated',   icon: Icons.star_rounded,     sel: _sortBy=='rating',   onTap: ()=>setState(()=>_sortBy='rating')),
              const SizedBox(width: 8),
              _Chip(label: 'Most Reports',icon: Icons.bar_chart_rounded, sel: _sortBy=='reports',  onTap: ()=>setState(()=>_sortBy='reports')),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Shop>>(
            stream: db.shopsStream(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary));
              }
              final shops = _sort(snap.data ?? []);
              if (shops.isEmpty) return const Center(child: Text('No shops found',
                  style: TextStyle(color: AppColors.gray400)));
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: shops.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ShopCard(shop: shops[i]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label; final IconData icon; final bool sel; final VoidCallback onTap;
  const _Chip({required this.label, required this.icon, required this.sel, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: sel ? AppColors.primary : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? AppColors.primary : const Color(0x18000000), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: sel ? Colors.white : AppColors.gray400),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: sel ? Colors.white : AppColors.gray400)),
      ]),
    ),
  );
}

class _ShopCard extends StatefulWidget {
  final Shop shop;
  const _ShopCard({required this.shop});
  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard> {
  double? _myRating;
  bool _rating = false;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final uid = context.read<AppProvider>().firebaseUser?.uid;
    if (uid == null) return;
    final r = await context.read<AppProvider>().db
        .getUserRatingForShop(widget.shop.id, uid);
    if (mounted) setState(() => _myRating = r);
  }

  @override
  Widget build(BuildContext context) {
    final shop     = widget.shop;
    final initials = shop.name.split(' ').take(2).map((w) => w[0]).join();
    final colPairs = [
      [AppColors.blueLight, AppColors.blue],
      [AppColors.amberLight, AppColors.amber],
      [AppColors.primaryLight, AppColors.primaryDark],
      [AppColors.accentLight, AppColors.accent],
      [AppColors.gray50, AppColors.gray400],
    ];
    final c = colPairs[shop.id.hashCode % colPairs.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: c[0], shape: BoxShape.circle),
                child: Center(child: Text(initials, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: c[1])))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shop.name, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray400),
                const SizedBox(width: 2),
                Text('${shop.area} · ${shop.distanceKm} km',
                    style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StarRating(rating: shop.rating),
              Text('(${shop.ratingCount})',
                  style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: shop.isOpen ? AppColors.primaryLight : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10)),
                child: Text(shop.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: shop.isOpen ? AppColors.primaryDark : AppColors.accent)),
              ),
            ]),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 0),
          const SizedBox(height: 8),
          // Price chips
          Wrap(spacing: 6, runSpacing: 6,
            children: shop.prices.entries.take(5).map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('ETB ${e.value.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w500, color: AppColors.gray800)),
            )).toList(),
          ),
          const SizedBox(height: 10),
          // Rate this shop
          Row(children: [
            const Icon(Icons.star_border_rounded, size: 14, color: AppColors.amber),
            const SizedBox(width: 4),
            Text(_myRating != null
                ? 'Your rating: ${_myRating!.toStringAsFixed(1)}'
                : 'Rate this shop',
                style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
            const Spacer(),
            if (!_rating)
              TextButton(
                onPressed: () => setState(() => _rating = true),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Rate',
                    style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ),
          ]),
          if (_rating)
            Row(children: List.generate(5, (i) => GestureDetector(
              onTap: () async {
                final uid = context.read<AppProvider>().firebaseUser?.uid;
                if (uid == null) return;
                final r = (i + 1).toDouble();
                await context.read<AppProvider>().db.rateShop(shop.id, uid, r);
                setState(() { _myRating = r; _rating = false; });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.star_rounded, size: 28,
                    color: _myRating != null && _myRating! > i
                        ? AppColors.amber : AppColors.gray100),
              ),
            ))),
          Row(children: [
            const Icon(Icons.receipt_long_outlined, size: 12, color: AppColors.gray400),
            const SizedBox(width: 4),
            Text('${shop.reportCount} reports',
                style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.directions_rounded, size: 14),
              label: const Text('Directions', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ]),
        ]),
      ),
    );
  }
}
