import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';

class ReportPriceScreen extends StatefulWidget {
  final Product? product;
  final bool fromBarcode;
  const ReportPriceScreen({super.key, this.product, this.fromBarcode = false});

  @override
  State<ReportPriceScreen> createState() => _ReportPriceScreenState();
}

class _ReportPriceScreenState extends State<ReportPriceScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _noteCtrl  = TextEditingController();

  Product? _product;
  Shop?    _shop;
  bool     _submitting = false;
  bool     _submitted  = false;
  List<Product> _products = [];
  List<Shop>    _shops    = [];

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadData();
  }

  Future<void> _loadData() async {
    final db = context.read<AppProvider>().db;
    db.productsStream().listen((p) { if (mounted) setState(() => _products = p); });
    db.shopsStream().listen((s)    { if (mounted) setState(() => _shops = s); });
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_product == null) { _err('Please select a product'); return; }
    if (_shop    == null) { _err('Please select a shop');    return; }
    setState(() => _submitting = true);
    final p = context.read<AppProvider>();
    try {
      await p.db.submitReport(
        productId:    _product!.id,
        productName:  _product!.name,
        shopId:       _shop!.id,
        shopName:     _shop!.name,
        price:        double.parse(_priceCtrl.text),
        reporterUid:  p.firebaseUser?.uid ?? 'anon',
        reporterName: p.appUser?.displayName
            ?? p.firebaseUser?.displayName ?? 'Anonymous',
        note:         _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        fromBarcode:  widget.fromBarcode,
      );
      if (mounted) setState(() { _submitting = false; _submitted = true; });
    } catch (e) {
      if (mounted) { setState(() => _submitting = false); _err('Failed: $e'); }
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessScreen(product: _product, shop: _shop,
        onReportAnother: () => setState(() {
          _submitted = false; _priceCtrl.clear(); _noteCtrl.clear(); _shop = null;
        }));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fromBarcode ? 'Report Scanned Price' : 'Report a Price'),
      ),
      // KEY FIX: resizeToAvoidBottomInset keeps content above keyboard
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              // Banner
              _InfoBanner(fromBarcode: widget.fromBarcode),
              const SizedBox(height: 20),

              // Product picker
              _FieldLabel(text: 'Product *'),
              _PickerTile(
                onTap: _pickProduct,
                leading: _product != null
                    ? Text(_product!.emoji, style: const TextStyle(fontSize: 22))
                    : const Icon(Icons.shopping_basket_outlined,
                        color: AppColors.gray400, size: 22),
                title: _product?.name ?? 'Select a product',
                subtitle: _product != null
                    ? '${_product!.category} · ${_product!.unit}' : null,
                hasValue: _product != null,
              ),
              const SizedBox(height: 14),

              // Shop picker
              _FieldLabel(text: 'Shop / Market *'),
              _PickerTile(
                onTap: _pickShop,
                leading: Icon(Icons.store_outlined,
                    color: _shop != null ? AppColors.primary : AppColors.gray400,
                    size: 22),
                title: _shop?.name ?? 'Select a shop',
                subtitle: _shop != null
                    ? '${_shop!.area} · ${_shop!.distanceKm} km away' : null,
                hasValue: _shop != null,
              ),
              const SizedBox(height: 14),

              // Price
              _FieldLabel(text: 'Price (ETB) *'),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'e.g. 85',
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: const Text('ETB',
                        style: TextStyle(color: AppColors.primary,
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter the price';
                  final price = double.tryParse(v);
                  if (price == null || price <= 0) return 'Enter a valid price';
                  if (price > 100000) return 'Price seems too high';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Note
              _FieldLabel(text: 'Note (optional)'),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. sale price, bulk pack…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Submit Report', style: TextStyle(fontSize: 16)),
                        ]),
              ),

              // Points reminder
              const SizedBox(height: 12),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                SizedBox(width: 4),
                Text('Each report earns you +10 community points',
                    style: TextStyle(fontSize: 12, color: AppColors.gray400)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _pickProduct() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(16),
              child: Text('Select Product', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600))),
          const Divider(height: 0),
          Expanded(child: ListView.separated(
            controller: sc,
            itemCount: _products.length,
            separatorBuilder: (_, __) => const Divider(height: 0, indent: 60),
            itemBuilder: (_, i) {
              final p = _products[i];
              return ListTile(
                leading: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(p.name, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text('${p.category} · ${p.unit}'),
                trailing: _product?.id == p.id
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _product = p);
                  Navigator.pop(context);
                },
              );
            },
          )),
        ]),
      ),
    );
  }

  void _pickShop() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(16),
              child: Text('Select Shop', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600))),
          const Divider(height: 0),
          Expanded(child: ListView.separated(
            controller: sc,
            itemCount: _shops.length,
            separatorBuilder: (_, __) => const Divider(height: 0, indent: 60),
            itemBuilder: (_, i) {
              final s = _shops[i];
              return ListTile(
                leading: Container(width: 40, height: 40,
                    decoration: const BoxDecoration(
                        color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.store_rounded,
                        color: AppColors.primary, size: 20)),
                title: Text(s.name, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text('${s.area} · ${s.distanceKm} km'),
                trailing: _shop?.id == s.id
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _shop = s);
                  Navigator.pop(context);
                },
              );
            },
          )),
        ]),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final bool fromBarcode;
  const _InfoBanner({required this.fromBarcode});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: fromBarcode ? AppColors.blueLight : AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(fromBarcode
          ? Icons.qr_code_scanner_rounded : Icons.info_outline_rounded,
          color: fromBarcode ? AppColors.blue : AppColors.primary, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(
        fromBarcode
            ? 'Price report from barcode scan. Each report earns +10 points!'
            : 'Help shoppers find fair prices. Each community report earns +10 pts!',
        style: TextStyle(fontSize: 13,
            color: fromBarcode ? AppColors.blue : AppColors.primaryDark,
            height: 1.4))),
    ]),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600)),
  );
}

class _PickerTile extends StatelessWidget {
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool hasValue;
  const _PickerTile({required this.onTap, required this.leading,
      required this.title, this.subtitle, required this.hasValue});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor ?? AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: hasValue ? AppColors.primary.withOpacity(0.4) : const Color(0x1A000000),
            width: hasValue ? 1.0 : 0.5)),
      child: Row(children: [
        leading,
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
          Text(title, style: TextStyle(fontSize: 14,
              color: hasValue ? null : AppColors.gray400,
              fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal)),
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(
                fontSize: 12, color: AppColors.gray400)),
        ])),
        Icon(Icons.chevron_right_rounded,
            color: hasValue ? AppColors.primary : AppColors.gray400, size: 20),
      ]),
    ),
  );
}

// ── Success Screen ────────────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  final Product? product;
  final Shop? shop;
  final VoidCallback onReportAnother;
  const _SuccessScreen({this.product, this.shop, required this.onReportAnother});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 88, height: 88,
            decoration: BoxDecoration(
              color: AppColors.primaryLight, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20, offset: const Offset(0, 8))]),
            child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 44)),
        const SizedBox(height: 24),
        const Text('Reported! 🎉', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        if (product != null && shop != null)
          Text('${product!.name} at ${shop!.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.gray400)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('⭐', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text('+10 points earned!', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.amber)),
          ]),
        ),
        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Done', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onReportAnother,
          child: const Text('Report Another Price',
              style: TextStyle(color: AppColors.primary, fontSize: 14)),
        ),
      ]),
    )),
  );
}
