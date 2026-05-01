// TODO Implement this library.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/article.dart';
import '../services/news_service.dart';

// ── Service singleton ────────────────────────────────────────────────────────
final newsServiceProvider = Provider<NewsService>((ref) => NewsService());

// ── Top headlines (Today tab) ────────────────────────────────────────────────
final topHeadlinesProvider = FutureProvider<List<Article>>((ref) async {
  final service = ref.watch(newsServiceProvider);
  return service.fetchTopHeadlines();
});

// ── Category news (News tab) ─────────────────────────────────────────────────
//
// Keyed by category string so each chip gets its own cached provider.
// Riverpod automatically disposes unused family entries.
final categoryNewsProvider = FutureProvider.family<List<Article>, String>((
  ref,
  category,
) async {
  final service = ref.watch(newsServiceProvider);
  return service.fetchByCategory(category: category);
});

// ── Search (Search tab) ──────────────────────────────────────────────────────
//
// Debounced so we don't fire on every keystroke.
// The screen passes the query; Riverpod caches per unique query string.
final searchNewsProvider = FutureProvider.family<List<Article>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];

  // Small debounce: wait 400 ms before actually hitting the API
  await Future.delayed(const Duration(milliseconds: 400));

  // If the provider was invalidated while we were waiting (new keystroke),
  // this future is abandoned automatically by Riverpod.
  final service = ref.watch(newsServiceProvider);
  return service.search(query: query);
});
