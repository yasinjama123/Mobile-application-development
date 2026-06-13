import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── PricePoint ────────────────────────────────────────────────────────────
class PricePoint {
  final DateTime date;
  final double price;
  const PricePoint({required this.date, required this.price});
  factory PricePoint.fromMap(Map<String, dynamic> m) => PricePoint(
        date: (m['date'] as Timestamp).toDate(),
        price: (m['price'] as num).toDouble());
  Map<String, dynamic> toMap() => {'date': Timestamp.fromDate(date), 'price': price};
}

// ─── Product ───────────────────────────────────────────────────────────────
class Product {
  final String id, name, category, unit, emoji;
  final double minPrice, maxPrice, avgPrice, changePercent;
  final int reportCount;
  final List<PricePoint> priceHistory;
  final String? barcode;

  const Product({
    required this.id, required this.name, required this.category,
    required this.unit, required this.emoji,
    required this.minPrice, required this.maxPrice,
    required this.avgPrice, required this.changePercent,
    required this.reportCount, required this.priceHistory,
    this.barcode,
  });

  bool get isPriceRising  => changePercent > 1;
  bool get isPriceFalling => changePercent < -1;

  factory Product.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id, name: d['name'] ?? '', category: d['category'] ?? '',
      unit: d['unit'] ?? '', emoji: d['emoji'] ?? '🛒',
      minPrice: (d['minPrice'] as num? ?? 0).toDouble(),
      maxPrice: (d['maxPrice'] as num? ?? 0).toDouble(),
      avgPrice: (d['avgPrice'] as num? ?? 0).toDouble(),
      changePercent: (d['changePercent'] as num? ?? 0).toDouble(),
      reportCount: (d['reportCount'] as num? ?? 0).toInt(),
      priceHistory: (d['priceHistory'] as List? ?? [])
          .map((e) => PricePoint.fromMap(e as Map<String, dynamic>)).toList(),
      barcode: d['barcode'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name, 'category': category, 'unit': unit, 'emoji': emoji,
    'minPrice': minPrice, 'maxPrice': maxPrice, 'avgPrice': avgPrice,
    'changePercent': changePercent, 'reportCount': reportCount,
    'priceHistory': priceHistory.map((p) => p.toMap()).toList(),
    if (barcode != null) 'barcode': barcode,
  };
}

// ─── Shop ──────────────────────────────────────────────────────────────────
class Shop {
  final String id, name, area, closingTime;
  final double distanceKm, rating, lat, lng;
  final bool isOpen;
  final int reportCount, ratingCount;
  final Map<String, double> prices;

  const Shop({
    required this.id, required this.name, required this.area,
    required this.distanceKm, required this.rating, required this.isOpen,
    required this.closingTime, required this.reportCount,
    required this.prices,
    this.lat = 9.0248, this.lng = 38.7469,
    this.ratingCount = 0,
  });

  factory Shop.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Shop(
      id: doc.id, name: d['name'] ?? '', area: d['area'] ?? '',
      distanceKm: (d['distanceKm'] as num? ?? 0).toDouble(),
      rating: (d['rating'] as num? ?? 0).toDouble(),
      isOpen: d['isOpen'] as bool? ?? false,
      closingTime: d['closingTime'] ?? '', reportCount: (d['reportCount'] as num? ?? 0).toInt(),
      ratingCount: (d['ratingCount'] as num? ?? 0).toInt(),
      lat: (d['lat'] as num? ?? 9.0248).toDouble(),
      lng: (d['lng'] as num? ?? 38.7469).toDouble(),
      prices: (d['prices'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name, 'area': area, 'distanceKm': distanceKm,
    'rating': rating, 'isOpen': isOpen, 'closingTime': closingTime,
    'reportCount': reportCount, 'ratingCount': ratingCount,
    'lat': lat, 'lng': lng, 'prices': prices,
  };
}

// ─── PriceReport ──────────────────────────────────────────────────────────
enum ReportType { reported, verified, alert, scanned }

class PriceReport {
  final String id, productId, productName, shopId, shopName, reporterName, reporterUid;
  final double price;
  final DateTime reportedAt;
  final int verifyCount, noCount;
  final ReportType type;
  final String? note;

  const PriceReport({
    required this.id, required this.productId, required this.productName,
    required this.shopId, required this.shopName, required this.price,
    required this.reporterName, required this.reporterUid,
    required this.reportedAt, required this.verifyCount,
    this.noCount = 0, required this.type, this.note,
  });

  factory PriceReport.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PriceReport(
      id: doc.id, productId: d['productId'] ?? '',
      productName: d['productName'] ?? '', shopId: d['shopId'] ?? '',
      shopName: d['shopName'] ?? '', price: (d['price'] as num? ?? 0).toDouble(),
      reporterName: d['reporterName'] ?? 'Anonymous',
      reporterUid: d['reporterUid'] ?? '',
      reportedAt: d['reportedAt'] != null
          ? (d['reportedAt'] as Timestamp).toDate() : DateTime.now(),
      verifyCount: (d['verifyCount'] as num? ?? 0).toInt(),
      noCount: (d['noCount'] as num? ?? 0).toInt(),
      type: ReportType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'reported'),
        orElse: () => ReportType.reported),
      note: d['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId, 'productName': productName,
    'shopId': shopId, 'shopName': shopName, 'price': price,
    'reporterName': reporterName, 'reporterUid': reporterUid,
    'reportedAt': Timestamp.fromDate(reportedAt),
    'verifyCount': verifyCount, 'noCount': noCount, 'type': type.name,
    if (note != null) 'note': note,
  };
}

// ─── WatchlistItem ────────────────────────────────────────────────────────
class WatchlistItem {
  final String id, productId, productName, emoji;
  final double targetPrice, currentPrice;

  const WatchlistItem({
    required this.id, required this.productId, required this.productName,
    required this.emoji, required this.targetPrice, required this.currentPrice,
  });

  bool get alertTriggered => currentPrice <= targetPrice;

  factory WatchlistItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WatchlistItem(
      id: doc.id, productId: d['productId'] ?? '',
      productName: d['productName'] ?? '', emoji: d['emoji'] ?? '🛒',
      targetPrice: (d['targetPrice'] as num? ?? 0).toDouble(),
      currentPrice: (d['currentPrice'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId, 'productName': productName,
    'emoji': emoji, 'targetPrice': targetPrice, 'currentPrice': currentPrice,
  };
}

// ─── ShoppingListItem ─────────────────────────────────────────────────────
class ShoppingListItem {
  final String id, name, emoji;
  final bool checked;
  final double? estimatedPrice;

  const ShoppingListItem({
    required this.id, required this.name, required this.emoji,
    this.checked = false, this.estimatedPrice,
  });

  ShoppingListItem copyWith({bool? checked}) =>
      ShoppingListItem(id: id, name: name, emoji: emoji,
          checked: checked ?? this.checked, estimatedPrice: estimatedPrice);
}

// ─── AppUser ──────────────────────────────────────────────────────────────
class AppUser {
  final String uid, displayName, email;
  final int reportCount, verifyCount, points;
  final String? fcmToken, photoUrl, location, role;
  final bool banned;

  const AppUser({
    required this.uid, required this.displayName, required this.email,
    required this.reportCount, required this.verifyCount, required this.points,
    this.fcmToken, this.photoUrl, this.location, this.role, this.banned = false,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id, displayName: d['displayName'] ?? 'User',
      email: d['email'] ?? '',
      reportCount: (d['reportCount'] as num? ?? 0).toInt(),
      verifyCount: (d['verifyCount'] as num? ?? 0).toInt(),
      points: (d['points'] as num? ?? 0).toInt(),
      fcmToken: d['fcmToken'] as String?,
      photoUrl: d['photoUrl'] as String?,
      location: d['location'] as String?,
      role: d['role'] as String?,
      banned: d['banned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'displayName': displayName, 'email': email,
    'reportCount': reportCount, 'verifyCount': verifyCount, 'points': points,
    if (fcmToken != null) 'fcmToken': fcmToken,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (location != null) 'location': location,
    if (role != null) 'role': role,
    'banned': banned,
  };
}

// ─── LeaderboardEntry ────────────────────────────────────────────────────
class LeaderboardEntry {
  final String uid, displayName;
  final int reportCount, points;
  final int rank;

  const LeaderboardEntry({
    required this.uid, required this.displayName,
    required this.reportCount, required this.points, required this.rank,
  });

  factory LeaderboardEntry.fromDoc(DocumentSnapshot doc, int rank) {
    final d = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      uid: doc.id, displayName: d['displayName'] ?? 'User',
      reportCount: (d['reportCount'] as num? ?? 0).toInt(),
      points: (d['points'] as num? ?? 0).toInt(),
      rank: rank,
    );
  }
}

// ─── Seed Data ────────────────────────────────────────────────────────────
class SeedData {
  static List<PricePoint> _history(double start, double end, int days) {
    final rng = Random(42);
    double cur = start;
    final step = (end - start) / days;
    return List.generate(days, (i) {
      cur += step + (rng.nextDouble() - 0.45) * 2;
      return PricePoint(
        date: DateTime.now().subtract(Duration(days: days - i)),
        price: double.parse(cur.clamp(
            [start, end].reduce(min) * 0.9,
            [start, end].reduce(max) * 1.1).toStringAsFixed(1)));
    });
  }

  static final List<Map<String, dynamic>> products = [
    {'id':'teff',  'name':'Teff Flour',      'category':'Grains',    'unit':'1 kg', 'emoji':'🌾','barcode':'6001234567890','minPrice':78, 'maxPrice':94, 'avgPrice':85, 'changePercent':6.2, 'reportCount':124,'priceHistory':_history(74,92,30).map((p)=>p.toMap()).toList()},
    {'id':'oil',   'name':'Cooking Oil',     'category':'Essentials','unit':'1 L',  'emoji':'🫙','barcode':'6009876543210','minPrice':195,'maxPrice':230,'avgPrice':210,'changePercent':-3.1,'reportCount':98, 'priceHistory':_history(225,198,30).map((p)=>p.toMap()).toList()},
    {'id':'rice',  'name':'Rice',            'category':'Grains',    'unit':'1 kg', 'emoji':'🍚','barcode':'6005551234567','minPrice':60, 'maxPrice':72, 'avgPrice':65, 'changePercent':0.3, 'reportCount':87, 'priceHistory':_history(63,65,30).map((p)=>p.toMap()).toList()},
    {'id':'sugar', 'name':'Sugar',           'category':'Essentials','unit':'500 g','emoji':'🧂','barcode':'6007890123456','minPrice':38, 'maxPrice':47, 'avgPrice':42, 'changePercent':4.1, 'reportCount':65, 'priceHistory':_history(38,44,30).map((p)=>p.toMap()).toList()},
    {'id':'bread', 'name':'Bread',           'category':'Bakery',    'unit':'400 g','emoji':'🍞','barcode':'6003456789012','minPrice':28, 'maxPrice':35, 'avgPrice':30, 'changePercent':1.8, 'reportCount':53, 'priceHistory':_history(27,31,30).map((p)=>p.toMap()).toList()},
    {'id':'milk',  'name':'Pasteurized Milk','category':'Dairy',     'unit':'1 L',  'emoji':'🥛','barcode':'6002345678901','minPrice':55, 'maxPrice':68, 'avgPrice':60, 'changePercent':-1.5,'reportCount':44, 'priceHistory':_history(63,59,30).map((p)=>p.toMap()).toList()},
    {'id':'tomato','name':'Tomatoes',        'category':'Vegetables','unit':'1 kg', 'emoji':'🍅','barcode':'6008901234567','minPrice':40, 'maxPrice':65, 'avgPrice':50, 'changePercent':-8.0,'reportCount':76, 'priceHistory':_history(68,48,30).map((p)=>p.toMap()).toList()},
    {'id':'onion', 'name':'Onions',          'category':'Vegetables','unit':'1 kg', 'emoji':'🧅','barcode':'6004567890123','minPrice':25, 'maxPrice':40, 'avgPrice':30, 'changePercent':2.5, 'reportCount':59, 'priceHistory':_history(28,31,30).map((p)=>p.toMap()).toList()},
  ];

  static final List<Map<String, dynamic>> shops = [
    {'id':'merkato','name':'Merkato Bazaar',  'area':'Addis Ketema','distanceKm':0.4,'rating':4.3,'isOpen':true, 'closingTime':'8:00 PM','reportCount':312,'ratingCount':45,'lat':9.0326,'lng':38.7468,'prices':{'teff':78.0,'oil':195.0,'rice':60.0,'sugar':38.0,'bread':28.0,'milk':55.0,'tomato':40.0,'onion':25.0}},
    {'id':'kera',   'name':'Kera Supermarket','area':'Kera',        'distanceKm':1.2,'rating':4.5,'isOpen':true, 'closingTime':'9:00 PM','reportCount':248,'ratingCount':62,'lat':9.0148,'lng':38.7369,'prices':{'teff':85.0,'oil':205.0,'rice':63.0,'sugar':42.0,'bread':30.0,'milk':60.0,'tomato':48.0,'onion':28.0}},
    {'id':'bole',   'name':'Bole Mini Mart',  'area':'Bole',        'distanceKm':2.1,'rating':4.1,'isOpen':true, 'closingTime':'10:00 PM','reportCount':180,'ratingCount':33,'lat':9.0248,'lng':38.7869,'prices':{'teff':87.0,'oil':212.0,'rice':66.0,'sugar':44.0,'bread':32.0,'milk':62.0,'tomato':55.0,'onion':32.0}},
    {'id':'lideta', 'name':'Lideta Shop',     'area':'Lideta',      'distanceKm':3.0,'rating':3.8,'isOpen':true, 'closingTime':'8:00 PM','reportCount':95, 'ratingCount':18,'lat':9.0198,'lng':38.7269,'prices':{'teff':94.0,'oil':230.0,'rice':72.0,'sugar':47.0,'bread':35.0,'milk':68.0,'tomato':65.0,'onion':40.0}},
    {'id':'piazza', 'name':'Piazza Market',   'area':'Piazza',      'distanceKm':3.8,'rating':4.0,'isOpen':false,'closingTime':'7:00 PM','reportCount':143,'ratingCount':27,'lat':9.0448,'lng':38.7469,'prices':{'teff':80.0,'oil':200.0,'rice':62.0,'sugar':40.0,'bread':29.0,'milk':58.0,'tomato':44.0,'onion':27.0}},
  ];
}

// ─── AdminRequest ─────────────────────────────────────────────────────────
enum AdminRequestStatus { pending, approved, rejected }

class AdminRequest {
  final String id, uid, displayName, email, reason, organization;
  final AdminRequestStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const AdminRequest({
    required this.id, required this.uid, required this.displayName,
    required this.email, required this.reason, required this.organization,
    required this.status, required this.requestedAt,
    this.reviewedAt, this.reviewedBy,
  });

  factory AdminRequest.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdminRequest(
      id:           doc.id,
      uid:          d['uid'] as String? ?? doc.id,
      displayName:  d['displayName'] as String? ?? '',
      email:        d['email'] as String? ?? '',
      reason:       d['reason'] as String? ?? '',
      organization: d['organization'] as String? ?? '',
      status:       AdminRequestStatus.values.firstWhere(
          (e) => e.name == (d['status'] ?? 'pending'),
          orElse: () => AdminRequestStatus.pending),
      requestedAt: d['requestedAt'] != null
          ? (d['requestedAt'] as Timestamp).toDate() : DateTime.now(),
      reviewedAt: d['reviewedAt'] != null
          ? (d['reviewedAt'] as Timestamp).toDate() : null,
      reviewedBy: d['reviewedBy'] as String?,
    );
  }
}
