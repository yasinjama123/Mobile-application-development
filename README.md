# FairPrice / BirrWise 🏷️🔥
### Crowdsourced Product Price Tracker — Flutter + Firebase
**Group 5 | Mobile Application Development | AAU | 2025/2026 Sem 2**

---

## 👥 Team
| # | Name | ID | Role |
|---|------|----|------|
| 1 | Getamesay Hailemichael | ATE/5152/13 | Developer |
| 2 | Sisay Leykun | ATE/0493/15 | UI/UX Designer |
| 3 | Tamrat Arage | ATE/8888/15 | Tester |
| 4 | Yasin Jama | ATE/4368/15 | Team Leader |

---

## 🔥 Firebase Integration
| Service | Usage |
|---------|-------|
| **Firebase Auth** | Email/password sign-up, sign-in, password reset |
| **Cloud Firestore** | Real-time products, shops, price reports, watchlist |
| **Firebase Messaging (FCM)** | Push notifications for price alerts & watchlist targets |
| **Firebase Analytics** | Usage tracking |

### Firestore Collections
```
/products/{productId}          — product catalog with price history array
/shops/{shopId}                — shop catalog with prices map
/price_reports/{reportId}      — crowdsourced price reports
/users/{uid}                   — user profile (reportCount, points, fcmToken)
/users/{uid}/watchlist/{id}    — per-user watchlist sub-collection
```

---

## 🚀 Setup (Step-by-Step)

### 1. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click **Add Project** → name it `fairprice-birrwise`
3. Enable **Google Analytics** (optional)

### 2. Enable Firebase Services
- **Authentication** → Sign-in method → Email/Password → Enable
- **Firestore Database** → Create database → Start in **test mode** (then deploy rules)
- **Cloud Messaging** → No extra setup needed for Android

### 3. Register Your App
- Add Android app → package: `com.group5.fairprice`
- Download `google-services.json` → place in `android/app/`
- (iOS) Add iOS app → Bundle ID: `com.group5.fairprice`
- Download `GoogleService-Info.plist` → place in `ios/Runner/`

### 4. Generate firebase_options.dart
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=fairprice-birrwise
```
This **replaces** the placeholder `lib/firebase_options.dart`.

### 5. Deploy Firestore Rules & Indexes
```bash
npm install -g firebase-tools
firebase login
firebase init firestore   # select your project
firebase deploy --only firestore
```

### 6. Run the App
```bash
flutter pub get
flutter run
```

The app will auto-seed Firestore with products and shops on the **first sign-up**.

---

## 🗂️ Project Structure
```
lib/
├── main.dart                      # Firebase init, AuthGate, MainShell
├── firebase_options.dart          # ← Replace with flutterfire configure output
├── utils/theme.dart               # AppColors, AppTheme (Material 3)
├── models/models.dart             # Models + Firestore serialization + SeedData
├── services/
│   ├── auth_service.dart          # FirebaseAuth wrapper
│   ├── firestore_service.dart     # All Firestore CRUD + streams
│   ├── messaging_service.dart     # FCM init, token save, topic subscribe
│   └── app_provider.dart          # ChangeNotifier — auth state + DB access
├── widgets/common.dart            # Shared widgets
└── screens/
    ├── auth_screen.dart           # LoginScreen, SignUpScreen, ForgotPasswordScreen
    ├── home_screen.dart           # Dashboard — live Firestore streams
    ├── search_screen.dart         # Live search stream
    ├── product_detail_screen.dart # Real-time product + shops + reports tabs
    ├── price_trends_screen.dart   # All products, sparkline charts
    ├── nearby_shops_screen.dart   # Shops sorted by distance
    ├── watchlist_screen.dart      # Firestore watchlist sub-collection
    ├── report_price_screen.dart   # Submit to Firestore with batch write
    └── profile_screen.dart        # Live user stats, sign-out
firestore.rules                    # Security rules — deploy to Firebase
firestore.indexes.json             # Composite indexes
```

---

## 🛠️ Tech Stack
| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) ≥ 3.0 |
| Auth | firebase_auth ^5.1.4 |
| Database | cloud_firestore ^5.2.1 |
| Push Notifications | firebase_messaging ^15.0.4 |
| Analytics | firebase_analytics ^11.2.1 |
| Charts | fl_chart ^0.68.0 |
| State | provider ^6.1.1 |
| Location | geolocator ^11.0.0 |

---

## 📱 How Data Flows

```
User signs up
  └─► Firebase Auth creates user
  └─► AppProvider._onAuthChanged fires
  └─► Firestore /users/{uid} doc created
  └─► FirestoreService.seedIfEmpty() called (first time only)
  └─► FCM token saved to user doc
  └─► MainShell shown

User reports a price
  └─► ReportPriceScreen._submit()
  └─► FirestoreService.submitReport() — Firestore batch:
        • /price_reports/{id} — new doc
        • /products/{id} — reportCount++, priceHistory appended
        • /shops/{id} — prices map updated
        • /users/{uid} — reportCount++, points += 10
  └─► All StreamBuilders on HomeScreen auto-refresh
```

---

*Built for AAU Mobile Application Development Course — Group 5*
