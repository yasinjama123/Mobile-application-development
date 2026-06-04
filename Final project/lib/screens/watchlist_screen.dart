import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final uid      = provider.firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAdd(context, provider),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
            label: const Text('Add', style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to use watchlist',
              style: TextStyle(color: AppColors.gray400)))
          : StreamBuilder<List<WatchlistItem>>(
              stream: provider.db.watchlistStream(uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) return _empty(context, provider);
                return _list(context, provider, uid, items);
              }),
    );
  }

  Widget _empty(BuildContext ctx, AppProvider p) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🔔', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      const Text('No watchlist items', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Add products to get FCM price alerts',
          style: TextStyle(fontSize: 13, color: AppColors.gray400)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: () => _showAdd(ctx, p),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
    ]),
  );

  Widget _list(BuildContext ctx, AppProvider p, String uid, List<WatchlistItem> items) {
    final triggered = items.where((i) => i.alertTriggered).toList();
    final watching  = items.where((i) => !i.alertTriggered).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (triggered.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '${triggered.length} product${triggered.length > 1 ? 's have' : ' has'} hit your target price!',
                style: const TextStyle(fontSize: 13, color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: '🎯 Target Reached'),
          const SizedBox(height: 8),
          Card(child: Column(children: triggered.asMap().entries.map((e) => Column(children: [
            _Tile(item: e.value,
                onRemove: () => p.db.removeWatchlistItem(uid, e.value.productId)),
            if (e.key < triggered.length - 1) const Divider(indent: 60),
          ])).toList())),
          const SizedBox(height: 20),
        ],
        if (watching.isNotEmpty) ...[
          SectionHeader(title: '👁 Watching (${watching.length})'),
          const SizedBox(height: 8),
          Card(child: Column(children: watching.asMap().entries.map((e) => Column(children: [
            _Tile(item: e.value,
                onRemove: () => p.db.removeWatchlistItem(uid, e.value.productId)),
            if (e.key < watching.length - 1) const Divider(indent: 60),
          ])).toList())),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(12)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🔔', style: TextStyle(fontSize: 16)),
            SizedBox(width: 10),
            Expanded(child: Text(
              'Set a target price and we\'ll send a push notification (FCM) when the community reports that price.',
              style: TextStyle(fontSize: 13, color: AppColors.amber, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showAdd(BuildContext ctx, AppProvider p) {
    final uid = p.firebaseUser?.uid;
    if (uid == null) return;
    Product? sel;
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bCtx) => StreamBuilder<List<Product>>(
        stream: p.db.productsStream(),
        builder: (_, snap) {
          final products = snap.data ?? [];
          return StatefulBuilder(builder: (_, setS) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20,
                MediaQuery.of(bCtx).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Add to Watchlist', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SizedBox(height: 100,
                child: ListView(scrollDirection: Axis.horizontal,
                  children: products.map((prod) {
                    final isSel = sel?.id == prod.id;
                    return GestureDetector(
                      onTap: () => setS(() => sel = prod),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryLight : AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSel ? AppColors.primary : const Color(0x18000000),
                              width: isSel ? 1.5 : 0.5)),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(prod.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(prod.name, style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSel ? AppColors.primaryDark : AppColors.gray800)),
                          Text('ETB ${prod.avgPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
                        ]),
                      ),
                    );
                  }).toList()),
              ),
              const SizedBox(height: 14),
              TextField(controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: const InputDecoration(
                  hintText: 'Target price (ETB)',
                  prefixIcon: Icon(Icons.notifications_outlined,
                      color: AppColors.gray400, size: 18))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (sel == null || ctrl.text.isEmpty) return;
                  final t = double.tryParse(ctrl.text);
                  if (t == null) return;
                  await p.db.addWatchlistItem(uid: uid, productId: sel!.id,
                      productName: sel!.name, emoji: sel!.emoji,
                      targetPrice: t, currentPrice: sel!.avgPrice);
                  if (bCtx.mounted) Navigator.pop(bCtx);
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Add to Watchlist'),
              ),
            ]),
          ));
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final WatchlistItem item; final VoidCallback onRemove;
  const _Tile({required this.item, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    final reached = item.alertTriggered;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(
                color: reached ? AppColors.primaryLight : AppColors.gray50,
                borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(item.productName, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
            if (reached) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 10, color: AppColors.primary),
                  SizedBox(width: 3),
                  Text('Hit!', style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                ])),
            ],
          ]),
          const SizedBox(height: 3),
          Row(children: [
            Text('Target: ETB ${item.targetPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
            const Text(' · ', style: TextStyle(color: AppColors.gray400)),
            Text('Now: ETB ${item.currentPrice.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12,
                    color: reached ? AppColors.primary : AppColors.gray400,
                    fontWeight: reached ? FontWeight.w500 : FontWeight.normal)),
          ]),
          if (!reached)
            Text('ETB ${(item.currentPrice - item.targetPrice).toStringAsFixed(0)} above target',
                style: const TextStyle(fontSize: 11, color: AppColors.accent)),
        ])),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.gray400, size: 20),
          style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
      ]),
    );
  }
}
