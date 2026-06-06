import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalService {
  static const _favKey        = 'favorites';
  static const _recentKey     = 'recent_searches';
  static const _shoppingKey   = 'shopping_list';
  static const _themeKey      = 'dark_mode';
  static const _langKey       = 'locale';

  // ── Dark Mode ───────────────────────────────────────────────────────────
  Future<bool> getDarkMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_themeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_themeKey, value);
  }

  // ── Language ───────────────────────────────────────────────────────────
  Future<String> getLocale() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_langKey) ?? 'en';
  }

  Future<void> setLocale(String locale) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_langKey, locale);
  }

  // ── Favorites ──────────────────────────────────────────────────────────
  Future<List<String>> getFavoriteIds() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_favKey) ?? [];
  }

  Future<void> addFavorite(String productId) async {
    final p    = await SharedPreferences.getInstance();
    final list = p.getStringList(_favKey) ?? [];
    if (!list.contains(productId)) {
      list.add(productId);
      await p.setStringList(_favKey, list);
    }
  }

  Future<void> removeFavorite(String productId) async {
    final p    = await SharedPreferences.getInstance();
    final list = p.getStringList(_favKey) ?? [];
    list.remove(productId);
    await p.setStringList(_favKey, list);
  }

  Future<bool> isFavorite(String productId) async {
    final list = await getFavoriteIds();
    return list.contains(productId);
  }

  // ── Recent Searches ────────────────────────────────────────────────────
  Future<List<String>> getRecentSearches() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_recentKey) ?? [];
  }

  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final p    = await SharedPreferences.getInstance();
    final list = p.getStringList(_recentKey) ?? [];
    list.remove(query);
    list.insert(0, query);
    if (list.length > 10) list.removeLast();
    await p.setStringList(_recentKey, list);
  }

  Future<void> clearRecentSearches() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_recentKey);
  }

  // ── Shopping List ──────────────────────────────────────────────────────
  Future<List<ShoppingListItem>> getShoppingList() async {
    final p    = await SharedPreferences.getInstance();
    final raw  = p.getStringList(_shoppingKey) ?? [];
    return raw.map((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return ShoppingListItem(
        id: m['id'] as String,
        name: m['name'] as String,
        emoji: m['emoji'] as String? ?? '🛒',
        checked: m['checked'] as bool? ?? false,
        estimatedPrice: (m['estimatedPrice'] as num?)?.toDouble(),
      );
    }).toList();
  }

  Future<void> saveShoppingList(List<ShoppingListItem> items) async {
    final p   = await SharedPreferences.getInstance();
    final raw = items.map((i) => jsonEncode({
      'id': i.id, 'name': i.name, 'emoji': i.emoji,
      'checked': i.checked,
      if (i.estimatedPrice != null) 'estimatedPrice': i.estimatedPrice,
    })).toList();
    await p.setStringList(_shoppingKey, raw);
  }

  Future<void> addShoppingItem(ShoppingListItem item) async {
    final list = await getShoppingList();
    list.add(item);
    await saveShoppingList(list);
  }

  Future<void> toggleShoppingItem(String id) async {
    final list = await getShoppingList();
    final idx  = list.indexWhere((i) => i.id == id);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(checked: !list[idx].checked);
      await saveShoppingList(list);
    }
  }

  Future<void> removeShoppingItem(String id) async {
    final list = await getShoppingList();
    list.removeWhere((i) => i.id == id);
    await saveShoppingList(list);
  }
}
