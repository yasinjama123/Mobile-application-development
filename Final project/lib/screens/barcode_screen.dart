import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import 'product_detail_screen.dart';
import 'report_price_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned  = false;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _loading) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() { _loading = true; _scanned = true; });
    await _ctrl.stop();

    final db = context.read<AppProvider>().db;
    final product = await db.getProductByBarcode(barcode);

    if (!mounted) return;
    setState(() => _loading = false);

    if (product != null) {
      _showProductFound(product, barcode);
    } else {
      _showNotFound(barcode);
    }
  }

  void _showProductFound(Product product, String barcode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(product.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(product.name, style: const TextStyle(fontSize: 20,
              fontWeight: FontWeight.w700, color: AppColors.gray800)),
          Text('${product.category} · ${product.unit}',
              style: const TextStyle(fontSize: 13, color: AppColors.gray400)),
          const SizedBox(height: 6),
          Text('Barcode: $barcode',
              style: const TextStyle(fontSize: 11, color: AppColors.gray400,
                  fontFamily: 'monospace')),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product)));
                },
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('View Details'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (_) => ReportPriceScreen(
                          product: product, fromBarcode: true)));
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Report Price'),
              ),
            ),
          ]),
        ]),
      ),
    ).then((_) => _resetScanner());
  }

  void _showNotFound(String barcode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('Product Not Found', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w700, color: AppColors.gray800)),
          const SizedBox(height: 6),
          Text('Barcode: $barcode',
              style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
          const SizedBox(height: 8),
          const Text('This product isn\'t in our database yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.gray400)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // go back to home
              // Trigger add product — handled by main shell
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add This Product'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _resetScanner(); },
            child: const Text('Scan Again',
                style: TextStyle(color: AppColors.primary)),
          ),
        ]),
      ),
    );
  }

  void _resetScanner() {
    setState(() { _scanned = false; _error = null; });
    _ctrl.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            onPressed: () => _ctrl.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () => _ctrl.switchCamera(),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _ctrl,
          onDetect: _onDetect,
        ),
        // Scan overlay
        Center(
          child: Container(
            width: 260, height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Corner decorators
        ..._buildCorners(),
        // Bottom hint
        Positioned(
          bottom: 60, left: 0, right: 0,
          child: Column(children: [
            if (_loading)
              const CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary)
            else
              const Column(children: [
                Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white54, size: 28),
                SizedBox(height: 8),
                Text('Point camera at a barcode',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(
                  color: AppColors.accent, fontSize: 13)),
            ],
          ]),
        ),
      ]),
    );
  }

  List<Widget> _buildCorners() {
    const size  = 20.0;
    const thick = 3.0;
    const color = AppColors.primary;
    const r     = 12.0;
    Widget corner(AlignmentGeometry align, BorderRadius br) =>
        Align(alignment: align,
            child: Container(
              width: size + 10, height: size + 10,
              margin: EdgeInsets.only(
                left:   align == Alignment.topLeft || align == Alignment.bottomLeft ? 72 : 0,
                right:  align == Alignment.topRight || align == Alignment.bottomRight ? 72 : 0,
                top:    align == Alignment.topLeft || align == Alignment.topRight ? 310 : 0,
                bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight ? 310 : 0,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top:    align == Alignment.topLeft || align == Alignment.topRight
                      ? const BorderSide(color: color, width: thick) : BorderSide.none,
                  bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight
                      ? const BorderSide(color: color, width: thick) : BorderSide.none,
                  left:   align == Alignment.topLeft || align == Alignment.bottomLeft
                      ? const BorderSide(color: color, width: thick) : BorderSide.none,
                  right:  align == Alignment.topRight || align == Alignment.bottomRight
                      ? const BorderSide(color: color, width: thick) : BorderSide.none,
                ),
                borderRadius: br,
              ),
            ));
    return [
      corner(Alignment.topLeft,     const BorderRadius.only(topLeft: Radius.circular(r))),
      corner(Alignment.topRight,    const BorderRadius.only(topRight: Radius.circular(r))),
      corner(Alignment.bottomLeft,  const BorderRadius.only(bottomLeft: Radius.circular(r))),
      corner(Alignment.bottomRight, const BorderRadius.only(bottomRight: Radius.circular(r))),
    ];
  }
}
