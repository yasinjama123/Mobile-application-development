import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairprice/models/models.dart';

void main() {
  group('PricePoint', () {
    test('fromMap / toMap works correctly', () {
      final now = DateTime.now();
      final map = {'date': Timestamp.fromDate(now), 'price': 85.5};
      final point = PricePoint.fromMap(map);
      expect(point.date, now);
      expect(point.price, 85.5);
      expect(point.toMap()['price'], 85.5);
    });
  });

  group('Product', () {
    test('isPriceRising / isPriceFalling', () {
      final rising = Product(
        id: '1',
        name: 'Rising',
        category: '',
        unit: '',
        emoji: '',
        minPrice: 0,
        maxPrice: 0,
        avgPrice: 0,
        changePercent: 2.5,
        reportCount: 0,
        priceHistory: [],
      );
      final falling = Product(
        id: '2',
        name: 'Falling',
        category: '',
        unit: '',
        emoji: '',
        minPrice: 0,
        maxPrice: 0,
        avgPrice: 0,
        changePercent: -2.5,
        reportCount: 0,
        priceHistory: [],
      );
      expect(rising.isPriceRising, true);
      expect(falling.isPriceFalling, true);
    });
  });

  group('AppUser', () {
    test('isAdmin returns true for role admin', () {
      final admin = AppUser(
        uid: '1',
        displayName: 'Admin',
        email: 'a@a.com',
        reportCount: 0,
        verifyCount: 0,
        points: 0,
        role: 'admin',
      );
      expect(admin.isAdmin, true);
    });
  });

  group('WatchlistItem', () {
    test('alertTriggered when currentPrice <= targetPrice', () {
      final item = WatchlistItem(
        id: '1',
        productId: 'p1',
        productName: 'Test',
        emoji: '🛒',
        targetPrice: 100,
        currentPrice: 95,
      );
      expect(item.alertTriggered, true);
    });
  });
}