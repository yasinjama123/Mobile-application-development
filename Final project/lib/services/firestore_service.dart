import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class FirestoreService {
  late final FirebaseFirestore _db;
  late final CollectionReference _users;
  late final CollectionReference _products;
  late final CollectionReference _shops;
  late final CollectionReference _reports;
  late final CollectionReference _adminRequests;
  late final CollectionReference _watchlist;

  FirestoreService() {
    _db = FirebaseFirestore.instance;
    _users = _db.collection('users');
    _products = _db.collection('products');
    _shops = _db.collection('shops');
    _reports = _db.collection('reports');
    _adminRequests = _db.collection('admin_requests');
    _watchlist = _db.collection('watchlist');
  }

  // ==================== USERS ====================
  Stream<List<AppUser>> allUsersStreamFull() {
    return _users
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AppUser.fromDoc(doc)).toList());
  }

  Stream<List<AppUser>> allUsersStream() => allUsersStreamFull();

  Future<void> setUserRole(String uid, String role) async {
    await _users.doc(uid).update({'role': role});
  }

  Future<void> banUser(String uid, bool banned) async {
    await _users.doc(uid).update({'banned': banned});
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Stream<List<LeaderboardEntry>> leaderboardStream({int limit = 20}) {
    return _users
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .asMap()
            .entries
            .map((e) => LeaderboardEntry.fromDoc(e.value, e.key + 1))
            .toList());
  }

  // ==================== PRODUCTS ====================
  Stream<List<Product>> productsStream() {
    return _products
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Product.fromDoc(doc)).toList());
  }

  Stream<List<Product>> allProductsStream() => productsStream();

  Stream<Product?> productStream(String id) {
    return _products
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Product.fromDoc(doc) : null);
  }

  Stream<List<Product>> searchProductsStream(String query) {
    if (query.isEmpty) return productsStream();
    final lower = query.toLowerCase();
    return productsStream().map((list) => list
        .where((p) =>
            p.name.toLowerCase().contains(lower) ||
            p.category.toLowerCase().contains(lower))
        .toList());
  }

  Stream<List<Product>> topCheapestStream({int limit = 5}) {
    return _products
        .orderBy('avgPrice')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Product.fromDoc(doc)).toList());
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final snap =
        await _products.where('barcode', isEqualTo: barcode).limit(1).get();
    return snap.docs.isEmpty ? null : Product.fromDoc(snap.docs.first);
  }

  // Single addProduct method with default parameters
  Future<void> addProduct({
    required String name,
    required String category,
    String unit = '1 unit',
    String emoji = '🛒',
    String creatorUid = 'system',
    String? barcode,
  }) async {
    await _products.add({
      'name': name,
      'category': category,
      'unit': unit,
      'emoji': emoji,
      'minPrice': 0,
      'maxPrice': 0,
      'avgPrice': 0,
      'changePercent': 0,
      'reportCount': 0,
      'priceHistory': [],
      'createdBy': creatorUid,
      'createdAt': FieldValue.serverTimestamp(),
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
    });
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  // ==================== SHOPS ====================
  Stream<List<Shop>> shopsStream() {
    return _shops
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Shop.fromDoc(doc)).toList());
  }

  Stream<List<Shop>> allShopsStream() => shopsStream();

  Future<void> addShop({
    required String name,
    required String area,
    String closingTime = '8:00 PM',
    String creatorUid = 'system',
    double lat = 9.0248,
    double lng = 38.7469,
  }) async {
    await _shops.add({
      'name': name,
      'area': area,
      'distanceKm': 0.0,
      'rating': 0.0,
      'isOpen': true,
      'closingTime': closingTime,
      'reportCount': 0,
      'ratingCount': 0,
      'lat': lat,
      'lng': lng,
      'prices': {},
      'createdBy': creatorUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleShopOpen(String id, bool isOpen) async {
    await _shops.doc(id).update({'isOpen': isOpen});
  }

  Future<void> deleteShop(String id) async {
    await _shops.doc(id).delete();
  }

  Future<void> rateShop(String shopId, String userId, double rating) async {
    final ratingRef = _shops.doc(shopId).collection('ratings').doc(userId);
    await ratingRef
        .set({'rating': rating, 'ratedAt': FieldValue.serverTimestamp()});
    final ratingsSnap = await _shops.doc(shopId).collection('ratings').get();
    final avg = ratingsSnap.docs
            .map((d) => d['rating'] as num)
            .fold(0.0, (a, b) => a + b) /
        ratingsSnap.docs.length;
    await _shops.doc(shopId).update({
      'rating': avg,
      'ratingCount': ratingsSnap.docs.length,
    });
  }

  Future<double?> getUserRatingForShop(String shopId, String userId) async {
    final doc =
        await _shops.doc(shopId).collection('ratings').doc(userId).get();
    return doc.exists ? (doc.data()?['rating'] as num?)?.toDouble() : null;
  }

  Stream<List<Shop>> shopsForProductStream(String productId) {
    return _shops.snapshots().map((snap) {
      final shopsList = snap.docs.map((doc) => Shop.fromDoc(doc)).toList();
      return shopsList.where((s) => s.prices.containsKey(productId)).toList()
        ..sort((a, b) => a.prices[productId]!.compareTo(b.prices[productId]!));
    });
  }

  // ==================== REPORTS ====================
  Stream<List<PriceReport>> allReportsStreamFull() {
    return _reports.orderBy('reportedAt', descending: true).snapshots().map(
        (snap) => snap.docs.map((doc) => PriceReport.fromDoc(doc)).toList());
  }

  Stream<List<PriceReport>> recentReportsStream() {
    return _reports
        .orderBy('reportedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PriceReport.fromDoc(doc)).toList());
  }

  Stream<List<PriceReport>> reportsForProductStream(String productId) {
    return _reports
        .where('productId', isEqualTo: productId)
        .orderBy('reportedAt', descending: true)
        .limit(15)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PriceReport.fromDoc(doc)).toList());
  }

  Future<void> submitReport({
    required String productId,
    required String productName,
    required String shopId,
    required String shopName,
    required double price,
    required String reporterUid,
    required String reporterName,
    String? note,
    bool fromBarcode = false,
  }) async {
    final batch = _db.batch();
    final reportRef = _reports.doc();
    batch.set(reportRef, {
      'productId': productId,
      'productName': productName,
      'shopId': shopId,
      'shopName': shopName,
      'price': price,
      'reporterUid': reporterUid,
      'reporterName': reporterName,
      'reportedAt': FieldValue.serverTimestamp(),
      'verifyCount': 0,
      'noCount': 0,
      'type': fromBarcode ? 'scanned' : 'reported',
      if (note != null && note.isNotEmpty) 'note': note,
    });

    // Update product stats
    final productRef = _products.doc(productId);
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(productRef);
      final data = doc.data() as Map<String, dynamic>?;
      final oldAvg = (data?['avgPrice'] as num?)?.toDouble() ?? 0.0;
      final oldCount = (data?['reportCount'] as num?)?.toInt() ?? 0;
      final newCount = oldCount + 1;
      final newAvg = ((oldAvg * oldCount) + price) / newCount;
      final oldMin = (data?['minPrice'] as num?)?.toDouble() ?? price;
      final oldMax = (data?['maxPrice'] as num?)?.toDouble() ?? price;
      final newMin = price < oldMin ? price : oldMin;
      final newMax = price > oldMax ? price : oldMax;
      transaction.update(productRef, {
        'avgPrice': newAvg,
        'reportCount': newCount,
        'minPrice': newMin,
        'maxPrice': newMax,
        'priceHistory': FieldValue.arrayUnion([
          {
            'date': Timestamp.now(),
            'price': price,
          }
        ]),
      });
    });

    batch.update(_shops.doc(shopId), {
      'prices.$productId': price,
      'reportCount': FieldValue.increment(1),
    });

    batch.update(_users.doc(reporterUid), {
      'reportCount': FieldValue.increment(1),
      'points': FieldValue.increment(10),
    });

    await batch.commit();
  }

  Future<void> deleteReport(String id) async {
    await _reports.doc(id).delete();
  }

  Future<void> voteOnReport(
      String reportId, String userId, bool isAccurate) async {
    final batch = _db.batch();
    if (isAccurate) {
      batch.update(_reports.doc(reportId), {
        'verifyCount': FieldValue.increment(1),
        'type': 'verified',
      });
      batch.update(_users.doc(userId), {
        'verifyCount': FieldValue.increment(1),
        'points': FieldValue.increment(5),
      });
    } else {
      batch
          .update(_reports.doc(reportId), {'noCount': FieldValue.increment(1)});
    }
    await batch.commit();
  }

  // ==================== ADMIN REQUESTS ====================
  Stream<List<AdminRequest>> pendingAdminRequestsStream() {
    return _adminRequests
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AdminRequest.fromDoc(doc)).toList());
  }

  Stream<List<AdminRequest>> allAdminRequestsStream() {
    return _adminRequests
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AdminRequest.fromDoc(doc)).toList());
  }

  Future<void> approveAdminRequest(String uid, String reviewerUid) async {
    final batch = _db.batch();
    final request =
        await _adminRequests.where('uid', isEqualTo: uid).limit(1).get();
    if (request.docs.isNotEmpty) {
      batch.update(request.docs.first.reference, {
        'status': 'approved',
        'reviewedBy': reviewerUid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.update(_users.doc(uid), {'role': 'admin'});
    await batch.commit();
  }

  Future<void> rejectAdminRequest(
      String uid, String reviewerUid, String reason) async {
    final batch = _db.batch();
    final request =
        await _adminRequests.where('uid', isEqualTo: uid).limit(1).get();
    if (request.docs.isNotEmpty) {
      batch.update(request.docs.first.reference, {
        'status': 'rejected',
        'reviewedBy': reviewerUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });
    }
    await batch.commit();
  }

  // ==================== WATCHLIST ====================
  Stream<List<WatchlistItem>> watchlistStream(String uid) {
    return _watchlist.where('userId', isEqualTo: uid).snapshots().map(
        (snap) => snap.docs.map((doc) => WatchlistItem.fromDoc(doc)).toList());
  }

  // Unified addWatchlistItem – supports both full and minimal parameters
  Future<void> addWatchlistItem({
    required String uid,
    required String productId,
    required String productName,
    String? emoji,
    double? targetPrice,
    double? currentPrice,
  }) async {
    // If minimal info provided, fetch the missing data from product doc
    final needFetch =
        emoji == null || targetPrice == null || currentPrice == null;
    String finalEmoji = emoji ?? '🛒';
    double finalTarget = targetPrice ?? 0.0;
    double finalCurrent = currentPrice ?? 0.0;

    if (needFetch) {
      final productDoc = await _products.doc(productId).get();
      if (productDoc.exists) {
        final data = productDoc.data() as Map<String, dynamic>?;
        finalEmoji = data?['emoji'] as String? ?? '🛒';
        finalCurrent = (data?['avgPrice'] as num?)?.toDouble() ?? 0.0;
        finalTarget = finalCurrent; // default target = current price
      }
    }

    await _watchlist.add({
      'userId': uid,
      'productId': productId,
      'productName': productName,
      'emoji': finalEmoji,
      'targetPrice': finalTarget,
      'currentPrice': finalCurrent,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeWatchlistItem(String userId, String productId) async {
    final snap = await _watchlist
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ==================== STATISTICS & SEED ====================
  Future<Map<String, int>> getStatistics() async {
    final results = await Future.wait([
      _products.count().get(),
      _shops.count().get(),
      _reports.count().get(),
      _users.count().get(),
      _shops.where('isOpen', isEqualTo: true).count().get(),
      _reports.where('type', isEqualTo: 'verified').count().get(),
    ]);
    return {
      'products': results[0].count ?? 0,
      'shops': results[1].count ?? 0,
      'reports': results[2].count ?? 0,
      'users': results[3].count ?? 0,
      'openShops': results[4].count ?? 0,
      'verifiedReports': results[5].count ?? 0,
    };
  }

  Future<void> seedIfEmpty() async {
    final count = await _products.count().get();
    if ((count.count ?? 0) > 0) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'system';
    final samples = [
      ('Teff', 'Grains', '1 kg', '🌾'),
      ('Cooking Oil', 'Essentials', '1 L', '🫙'),
      ('Rice', 'Grains', '1 kg', '🍚'),
      ('Sugar', 'Essentials', '500 g', '🧂'),
      ('Bread', 'Bakery', '400 g', '🍞'),
      ('Milk', 'Dairy', '1 L', '🥛'),
      ('Tomatoes', 'Vegetables', '1 kg', '🍅'),
      ('Onions', 'Vegetables', '1 kg', '🧅'),
    ];
    for (final s in samples) {
      await addProduct(
        name: s.$1,
        category: s.$2,
        unit: s.$3,
        emoji: s.$4,
        creatorUid: uid,
      );
    }

    await addShop(
        name: 'Merkato Bazaar',
        area: 'Addis Ketema',
        closingTime: '8:00 PM',
        creatorUid: uid);
    await addShop(
        name: 'Kera Supermarket',
        area: 'Kera',
        closingTime: '9:00 PM',
        creatorUid: uid);
    await addShop(
        name: 'Bole Mini Mart',
        area: 'Bole',
        closingTime: '10:00 PM',
        creatorUid: uid);
  }
}
