// Search screen allows users to enter keywords and discover articles.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/article.dart';
import '../../providers/news_provider.dart';
import 'article_detail_screen.dart';

/// Screen that allows users to search for articles by keyword.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

/// State for [SearchScreen] that manages search input and results display.
class _SearchScreenState extends ConsumerState<SearchScreen> {
  /// Controller for the search text field
  final _controller = TextEditingController();

  /// Current search query
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoSearchTextField(
          controller: _controller,
          placeholder: 'Search stories, topics...',
          onChanged: (val) => setState(() => _query = val.trim()),
          onSubmitted: (val) => setState(() => _query = val.trim()),
        ),
        leading: const SizedBox.shrink(),
        trailing: _query.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
                onPressed: () {
                  _controller.clear();
                  setState(() => _query = '');
                  FocusScope.of(context).unfocus();
                },
              )
            : null,
      ),
      child: SafeArea(
        child: _query.isEmpty
            ? const _SearchEmptyState()
            : _SearchResults(query: _query),
      ),
    );
  }
}

/// Widget that shows suggested topics when search field is empty.
class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  /// List of suggested search topics
  static const _suggestions = [
    'Technology',
    'Climate',
    'AI',
    'Markets',
    'Sports',
    'Space',
    'Health',
    'Politics',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Suggested Topics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((s) {
            return GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemBackground.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Widget that displays search results for a given query.
class _SearchResults extends ConsumerWidget {
  /// The search query to find articles for
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchNewsProvider(query));

    return resultsAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: CupertinoColors.secondaryLabel),
        ),
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.search,
                  size: 56,
                  color: CupertinoColors.systemGrey3,
                ),
                const SizedBox(height: 16),
                Text(
                  'No results for "$query"',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try a different keyword',
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 8),
          itemCount: articles.length,
          separatorBuilder: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 0.5, thickness: 0.5),
          ),
          itemBuilder: (context, i) => _SearchResultTile(article: articles[i]),
        );
      },
    );
  }
}

/// Widget for displaying a single search result as a tile.
class _SearchResultTile extends StatelessWidget {
  /// The article to display
  final Article article;
  const _SearchResultTile({required this.article});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => ArticleDetailScreen(article: article),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.source.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemRed,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.color,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(article.publishedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.tertiaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            if (article.imageUrl != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  width: 80,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 80,
                    height: 64,
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 64,
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                    child: const Icon(
                      CupertinoIcons.photo,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
