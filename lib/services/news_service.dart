// News service layer for fetching articles from NewsAPI.
// Handles API request building, response parsing, and error handling.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  static const _apiKey =
      '8e4fc77aa9574c3999aaf5d67c967019'; // Replace with your key
  static const _baseUrl = 'https://newsapi.org/v2';

  final http.Client _client;
  NewsService({http.Client? client}) : _client = client ?? http.Client();

  // ── Top headlines (for Today tab) ───────────────────────────────────────────
  Future<List<Article>> fetchTopHeadlines({
    String country = 'us',
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/top-headlines').replace(
      queryParameters: {
        'country': country,
        'pageSize': '$pageSize',
        'apiKey': _apiKey,
      },
    );
    return _get(uri);
  }

  // ── Category feed (for News tab) ─────────────────────────────────────────────
  Future<List<Article>> fetchByCategory({
    required String category,
    String country = 'us',
    int pageSize = 30,
  }) async {
    final uri = Uri.parse('$_baseUrl/top-headlines').replace(
      queryParameters: {
        'country': country,
        'category': category,
        'pageSize': '$pageSize',
        'apiKey': _apiKey,
      },
    );
    return _get(uri);
  }

  // ── Search (for Search tab) ──────────────────────────────────────────────────
  Future<List<Article>> search({
    required String query,
    String sortBy = 'publishedAt',
    int pageSize = 30,
  }) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('$_baseUrl/everything').replace(
      queryParameters: {
        'q': query.trim(),
        'sortBy': sortBy,
        'pageSize': '$pageSize',
        'language': 'en',
        'apiKey': _apiKey,
      },
    );
    return _get(uri);
  }

  // ── Shared HTTP + parse logic ────────────────────────────────────────────────
  Future<List<Article>> _get(Uri uri) async {
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('NewsAPI error ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (body['status'] != 'ok') {
      throw Exception('NewsAPI: ${body['message'] ?? 'unknown error'}');
    }

    final rawArticles = body['articles'] as List<dynamic>;
    return rawArticles
        .cast<Map<String, dynamic>>()
        .where(
          (a) =>
              a['title'] != null &&
              a['title'] != '[Removed]' &&
              a['url'] != null,
        )
        .map(Article.fromJson)
        .toList();
  }
}
