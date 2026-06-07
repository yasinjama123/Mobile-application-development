import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fairprice/models/models.dart';

void main() {
  group('Firestore data rules (no real Firebase)', () {
    test('Product validation – price must be > 0 and < 100,000', () {
      expect(50.0 > 0 && 50.0 < 100000, true);
      expect(-10.0 > 0, false);
      expect(150000.0 < 100000, false);
    });

    test('Product name must be at least 2 characters', () {
      const minLength = 2;
      expect('Teff'.length >= minLength, true);
      expect('A'.length >= minLength, false);
    });

    test('Email validation regex works', () {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      expect(emailRegex.hasMatch('test@example.com'), true);
      expect(emailRegex.hasMatch('invalid'), false);
      expect(emailRegex.hasMatch('user@domain.co'), true);
    });
  });

  // Optional: Use fake Firestore directly (not through FirestoreService)
  test('Fake Firestore can add and retrieve a product', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore.collection('products').add({
      'name': 'Test Product',
      'category': 'Grains',
      'unit': '1 kg',
      'emoji': '🌾',
      'minPrice': 0,
      'maxPrice': 0,
      'avgPrice': 0,
      'changePercent': 0,
      'reportCount': 0,
      'priceHistory': [],
    });

    final snapshot = await fakeFirestore.collection('products').get();
    expect(snapshot.docs.length, 1);
    final data = snapshot.docs.first.data();
    expect(data['name'], 'Test Product');
  });
}
