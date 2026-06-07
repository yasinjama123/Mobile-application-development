import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fairprice/widgets/common.dart';
import 'package:fairprice/models/models.dart';
import 'package:fairprice/utils/theme.dart';

void main() {
  testWidgets('TrendBadge displays correct icon and text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TrendBadge(changePercent: 5.0)),
      ),
    );
    expect(find.text('+5.0%'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TrendBadge(changePercent: -3.2)),
      ),
    );
    expect(find.text('-3.2%'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
  });

  testWidgets('ProductListTile displays product info', (tester) async {
    final product = Product(
      id: '1',
      name: 'Test Product',
      category: 'Grains',
      unit: '1 kg',
      emoji: '🌾',
      minPrice: 10,
      maxPrice: 20,
      avgPrice: 15,
      changePercent: 2.0,
      reportCount: 5,
      priceHistory: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductListTile(product: product)),
      ),
    );

    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('Grains · 1 kg · 5 reports'), findsOneWidget);
    expect(find.text('ETB 15'), findsOneWidget);
  });
}