import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class MapScreen extends StatefulWidget {
  final Shop? focusShop;
  const MapScreen({super.key, this.focusShop});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapCtrl = MapController();
  Position? _myPos;
  Shop? _selectedShop;
  String _filter = 'all'; // all | open | rated

  // Addis Ababa centre
  static const LatLng _addisCenter = LatLng(9.0248, 38.7469);

  @override
  void initState() {
    super.initState();
    _selectedShop = widget.focusShop;
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() => _myPos = pos);
        _mapCtrl.move(
            LatLng(pos.latitude, pos.longitude), 14);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {
              if (_myPos != null) {
                _mapCtrl.move(
                    LatLng(_myPos!.latitude, _myPos!.longitude), 15);
              } else {
                _getLocation();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Shop>>(
        stream: db.shopsStream(),
        builder: (ctx, snap) {
          final shops = snap.data ?? [];
          final filtered = _applyFilter(shops);
          return Stack(children: [
            // Map
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: widget.focusShop != null
                    ? LatLng(widget.focusShop!.lat, widget.focusShop!.lng)
                    : _addisCenter,
                initialZoom: 13,
                onTap: (_, __) => setState(() => _selectedShop = null),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.group5.fairprice',
                ),
                // My location marker
                if (_myPos != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(_myPos!.latitude, _myPos!.longitude),
                      width: 40, height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(
                              color: AppColors.blue.withOpacity(0.4),
                              blurRadius: 8)],
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ]),
                // Shop markers
                MarkerLayer(
                  markers: filtered.map((shop) {
                    final isSelected = _selectedShop?.id == shop.id;
                    return Marker(
                      point: LatLng(shop.lat, shop.lng),
                      width: isSelected ? 56 : 44,
                      height: isSelected ? 56 : 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedShop = shop),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : shop.isOpen
                                    ? Colors.white
                                    : AppColors.gray100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.primary,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Icon(Icons.store_rounded,
                              color: isSelected
                                  ? Colors.white
                                  : shop.isOpen
                                      ? AppColors.primary
                                      : AppColors.gray400,
                              size: isSelected ? 26 : 20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Filter chips top
            Positioned(top: 10, left: 12, right: 12,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _FilterChip(label: 'All Shops',   value: 'all',    cur: _filter, onTap: () => setState(() => _filter = 'all')),
                  const SizedBox(width: 8),
                  _FilterChip(label: '🟢 Open Now', value: 'open',   cur: _filter, onTap: () => setState(() => _filter = 'open')),
                  const SizedBox(width: 8),
                  _FilterChip(label: '⭐ Top Rated', value: 'rated', cur: _filter, onTap: () => setState(() => _filter = 'rated')),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                            blurRadius: 4)]),
                    child: Text('${filtered.length} shops',
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w500, color: AppColors.gray400)),
                  ),
                ]),
              ),
            ),

            // Selected shop bottom card
            if (_selectedShop != null)
              Positioned(
                bottom: 20, left: 16, right: 16,
                child: _ShopCard(
                  shop: _selectedShop!,
                  myPos: _myPos,
                  onClose: () => setState(() => _selectedShop = null),
                ),
              ),

            // Legend
            if (_selectedShop == null)
              Positioned(
                bottom: 20, right: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _LegendItem(color: AppColors.primary, label: 'Open'),
                  const SizedBox(height: 4),
                  _LegendItem(color: AppColors.gray400, label: 'Closed'),
                  const SizedBox(height: 4),
                  _LegendItem(color: AppColors.blue, label: 'You'),
                ]),
              ),
          ]);
        },
      ),
    );
  }

  List<Shop> _applyFilter(List<Shop> shops) {
    switch (_filter) {
      case 'open':  return shops.where((s) => s.isOpen).toList();
      case 'rated': return shops.where((s) => s.rating >= 4.0).toList();
      default:      return shops;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, cur;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.value,
      required this.cur, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sel = value == cur;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: Text(label, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : AppColors.gray800)),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final Shop shop;
  final Position? myPos;
  final VoidCallback onClose;
  const _ShopCard({required this.shop, this.myPos, required this.onClose});

  @override
  Widget build(BuildContext context) {
    double? dist;
    if (myPos != null) {
      dist = Geolocator.distanceBetween(
          myPos!.latitude, myPos!.longitude, shop.lat, shop.lng) / 1000;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.store_rounded,
                color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shop.name, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
            Row(children: [
              const Icon(Icons.location_on_rounded,
                  size: 12, color: AppColors.gray400),
              const SizedBox(width: 2),
              Text(shop.area, style: const TextStyle(
                  fontSize: 12, color: AppColors.gray400)),
              if (dist != null) ...[
                const Text(' · ', style: TextStyle(color: AppColors.gray400)),
                Text('${dist.toStringAsFixed(1)} km away',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ],
            ]),
          ])),
          IconButton(onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          StarRating(rating: shop.rating),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: shop.isOpen ? AppColors.primaryLight : AppColors.accentLight,
              borderRadius: BorderRadius.circular(10)),
            child: Text(shop.isOpen
                ? 'Open · closes ${shop.closingTime}' : 'Closed',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: shop.isOpen
                        ? AppColors.primaryDark : AppColors.accent)),
          ),
          const Spacer(),
          Text('${shop.reportCount} reports',
              style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
        ]),
        if (shop.prices.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Divider(height: 0),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6,
            children: shop.prices.entries.take(4).map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.gray50, borderRadius: BorderRadius.circular(8)),
              child: Text('ETB ${e.value.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: AppColors.gray800)),
            )).toList(),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Launch maps directions
              },
              icon: const Icon(Icons.directions_rounded, size: 16),
              label: const Text('Directions', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3)]),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(
          color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}
