import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../utils/theme.dart';

// ── TrendBadge ───────────────────────────────────────────────────────────
class TrendBadge extends StatelessWidget {
  final double changePercent;
  const TrendBadge({super.key, required this.changePercent});
  @override
  Widget build(BuildContext context) {
    final up    = changePercent > 1;
    final down  = changePercent < -1;
    final color = up ? AppColors.accent : down ? AppColors.primary : AppColors.gray400;
    final bg    = up ? AppColors.accentLight : down ? AppColors.primaryLight : AppColors.gray50;
    final icon  = up ? Icons.arrow_upward_rounded
                : down ? Icons.arrow_downward_rounded : Icons.remove_rounded;
    final sign  = changePercent > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text('$sign${changePercent.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

// ── SectionHeader ─────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title; final String? actionLabel; final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
        letterSpacing: -0.2)),
    const Spacer(),
    if (actionLabel != null)
      GestureDetector(onTap: onAction, child: Text(actionLabel!,
          style: const TextStyle(fontSize: 13, color: AppColors.primary,
              fontWeight: FontWeight.w500))),
  ]);
}

// ── MetricCard ────────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label, value; final String? subtitle; final Color? subtitleColor;
  const MetricCard({super.key, required this.label, required this.value,
      this.subtitle, this.subtitleColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600,
          letterSpacing: -0.5)),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(subtitle!, style: TextStyle(fontSize: 11,
            color: subtitleColor ?? AppColors.gray400)),
      ],
    ]),
  );
}

// ── ProductListTile ───────────────────────────────────────────────────────
class ProductListTile extends StatelessWidget {
  final Product product; final VoidCallback? onTap;
  const ProductListTile({super.key, required this.product, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.gray50,
                borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(product.emoji,
                style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('${product.category} · ${product.unit} · ${product.reportCount} reports',
              style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('ETB ${product.avgPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${product.minPrice.toStringAsFixed(0)}–${product.maxPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
          const SizedBox(height: 3),
          TrendBadge(changePercent: product.changePercent),
        ]),
      ]),
    ),
  );
}

// ── ShopTile ──────────────────────────────────────────────────────────────
class ShopTile extends StatelessWidget {
  final Shop shop; final String? productId; final bool isBestPrice; final VoidCallback? onTap;
  const ShopTile({super.key, required this.shop, this.productId,
      this.isBestPrice = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final initials = shop.name.split(' ').take(2).map((w) => w[0]).join();
    final colors = [
      [AppColors.blueLight, AppColors.blue], [AppColors.amberLight, AppColors.amber],
      [AppColors.primaryLight, AppColors.primaryDark], [AppColors.accentLight, AppColors.accent],
    ];
    final c = colors[shop.id.hashCode % colors.length];
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(color: c[0], shape: BoxShape.circle),
              child: Center(child: Text(initials, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: c[1])))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(shop.name, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
              if (isBestPrice) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('Best price', style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600, color: AppColors.primaryDark))),
              ],
            ]),
            const SizedBox(height: 2),
            Row(children: [
              Text('${shop.distanceKm} km · ',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: shop.isOpen ? AppColors.primary : AppColors.accent)),
              const SizedBox(width: 3),
              Text(shop.isOpen ? 'Open · ${shop.closingTime}' : 'Closed',
                  style: TextStyle(fontSize: 11,
                      color: shop.isOpen ? AppColors.primary : AppColors.accent)),
            ]),
          ])),
          if (productId != null && shop.prices[productId] != null)
            Text('ETB ${shop.prices[productId]!.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── ActivityItem ──────────────────────────────────────────────────────────
class ActivityItem extends StatelessWidget {
  final PriceReport report;
  const ActivityItem({super.key, required this.report});
  @override
  Widget build(BuildContext context) {
    IconData icon; Color bg, fg; String text;
    switch (report.type) {
      case ReportType.reported:
        icon = Icons.add_rounded; bg = AppColors.blueLight; fg = AppColors.blue;
        text = '${report.reporterName} reported ${report.productName} at ETB ${report.price.toStringAsFixed(0)} — ${report.shopName}';
        break;
      case ReportType.verified:
        icon = Icons.check_rounded; bg = AppColors.primaryLight; fg = AppColors.primary;
        text = '${report.productName} at ${report.shopName} verified by ${report.reporterName}';
        break;
      case ReportType.alert:
        icon = Icons.notifications_rounded; bg = AppColors.amberLight; fg = AppColors.amber;
        text = 'Alert: ${report.productName} dropped to ETB ${report.price.toStringAsFixed(0)} at ${report.shopName}';
        break;
      case ReportType.scanned:
        icon = Icons.qr_code_scanner_rounded; bg = AppColors.accentLight; fg = AppColors.accent;
        text = '${report.reporterName} scanned ${report.productName} — ETB ${report.price.toStringAsFixed(0)}';
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: fg)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 3),
          // Timestamp
          Row(children: [
            Text(timeago.format(report.reportedAt),
                style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
            if (report.verifyCount > 0) ...[
              const Text(' · ', style: TextStyle(color: AppColors.gray400)),
              const Icon(Icons.check_circle_rounded, size: 11, color: AppColors.primary),
              const SizedBox(width: 2),
              Text('${report.verifyCount} verified',
                  style: const TextStyle(fontSize: 11, color: AppColors.primary)),
            ],
          ]),
        ])),
      ]),
    );
  }
}

// ── StarRating ────────────────────────────────────────────────────────────
class StarRating extends StatelessWidget {
  final double rating;
  const StarRating({super.key, required this.rating});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
    const SizedBox(width: 2),
    Text(rating.toStringAsFixed(1), style: const TextStyle(
        fontSize: 12, color: AppColors.gray400, fontWeight: FontWeight.w500)),
  ]);
}
