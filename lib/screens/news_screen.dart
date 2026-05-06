// News screen displays articles grouped by selected categories.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/article.dart';
import '../../providers/news_provider.dart';
import 'article_detail_screen.dart';

/// List of available news categories for filtering articles
const _categories = [
  'general',
  'technology',
  'business',
  'sports',
  'entertainment',
  'health',
  'science',
];

/// Screen that displays news articles filtered by selected category.
class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

/// State for [NewsScreen] that manages category selection and article display.
class _NewsScreenState extends ConsumerState<NewsScreen> {
  /// Currently selected news category
  String _selectedCategory = 'general';

  @override
  Widget build(BuildContext context) {
    // Watch articles for the selected category
    final articlesAsync = ref.watch(categoryNewsProvider(_selectedCategory));

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('News')),
          // Category filter buttons
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  // Category button with animation
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? CupertinoColors.systemRed
                            : CupertinoColors.secondarySystemBackground
                                  .resolveFrom(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _capitalize(cat),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? CupertinoColors.white
                              : CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          // Display articles with loading, error, and data states
          articlesAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const _ArticleSkeletonTile(),
                childCount: 8,
              ),
            ),
            // Error state with retry button
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 48,
                      color: CupertinoColors.systemRed,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load articles',
                      style: TextStyle(color: CupertinoColors.secondaryLabel),
                    ),
                    CupertinoButton(
                      child: const Text('Retry'),
                      onPressed: () => ref.invalidate(
                        categoryNewsProvider(_selectedCategory),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Success state with articles list
            data: (articles) => articles.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No articles found',
                        style: TextStyle(color: CupertinoColors.secondaryLabel),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _NewsArticleTile(article: articles[i]),
                      childCount: articles.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Capitalizes the first letter of a string.
  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

/// Widget for displaying a single news article in list format.
class _NewsArticleTile extends StatelessWidget {
  /// The article to display
  final Article article;
  const _NewsArticleTile({required this.article});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => ArticleDetailScreen(article: article),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        article.source.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemRed,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      timeago.format(article.publishedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: CupertinoTheme.of(
                            context,
                          ).textTheme.textStyle.color,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (article.imageUrl != null) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: article.imageUrl!,
                          width: 90,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 90,
                            height: 70,
                            color: CupertinoColors.systemGrey5.resolveFrom(
                              context,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 90,
                            height: 70,
                            color: CupertinoColors.systemGrey5.resolveFrom(
                              context,
                            ),
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
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 0.5, thickness: 0.5),
        ),
      ],
    );
  }
}

class _ArticleSkeletonTile extends StatelessWidget {
  /// Placeholder tile shown while articles are loading
  const _ArticleSkeletonTile();

  @override
  Widget build(BuildContext context) {
    // Use grey background color for skeleton placeholders
    final bg = CupertinoColors.systemGrey5.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 90,
            height: 70,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
