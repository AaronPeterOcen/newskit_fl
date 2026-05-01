// TODO Implement this library.
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

// ── SharedPreferences instance ───────────────────────────────────────────────
//
// Initialised once in main.dart and overridden here so it's available
// throughout the app without async gaps in widgets.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Override sharedPreferencesProvider in ProviderScope',
  );
});

// ── Bookmarks notifier ───────────────────────────────────────────────────────
class BookmarksNotifier extends Notifier<List<Article>> {
  static const _key = 'bookmarks';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<Article> build() {
    return _load();
  }

  // ── Public API ──────────────────────────────────────────────────────────────
  void add(Article article) {
    if (state.any((a) => a.url == article.url)) return;
    state = [article, ...state];
    _persist();
  }

  void remove(Article article) {
    state = state.where((a) => a.url != article.url).toList();
    _persist();
  }

  void clearAll() {
    state = [];
    _persist();
  }

  bool isBookmarked(String url) => state.any((a) => a.url == url);

  // ── Persistence helpers ─────────────────────────────────────────────────────
  List<Article> _load() {
    final raw = _prefs.getStringList(_key) ?? [];
    return raw
        .map((s) {
          try {
            return Article.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Article>()
        .toList();
  }

  void _persist() {
    final encoded = state.map((a) => jsonEncode(a.toJson())).toList();
    _prefs.setStringList(_key, encoded);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final bookmarksProvider = NotifierProvider<BookmarksNotifier, List<Article>>(
  BookmarksNotifier.new,
);
