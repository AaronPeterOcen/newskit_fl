// Saved stories screen for viewing and removing bookmarked articles.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/article.dart';
import '../../providers/bookmarks_provider.dart';
import 'article_detail_screen.dart';

/// Screen that displays all saved/bookmarked articles.
/// Allows users to view their collection and remove articles.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch bookmarks state for real-time updates
    final bookmarks = ref.watch(bookmarksProvider);

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Saved'),
            trailing: bookmarks.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () => _confirmClear(context, ref),
                  )
                : null,
          ),
          if (bookmarks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: CupertinoColors.secondarySystemBackground
                            .resolveFrom(context),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.bookmark,
                        size: 36,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Saved Stories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Tap the bookmark icon on any story to save it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _BookmarkTile(article: bookmarks[i]),
                childCount: bookmarks.length,
              ),
            ),
        ],
      ),
    );
  }

  /// Shows confirmation dialog before clearing all bookmarks.
  void _confirmClear(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Clear All Saved Stories?'),
        content: const Text('This will remove all your saved articles.'),
        actions: [
          // Destructive action to clear all bookmarks
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(bookmarksProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          // Cancel action
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a single bookmark tile with swipe-to-delete functionality.
class _BookmarkTile extends ConsumerWidget {
  /// The article to display
  final Article article;
  const _BookmarkTile({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(article.url),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.systemRed,
        child: const Icon(
          CupertinoIcons.trash,
          color: CupertinoColors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) => ref.read(bookmarksProvider.notifier).remove(article),
      child: Column(
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.bookmark_fill,
                              size: 12,
                              color: CupertinoColors.systemRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              article.source.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.systemRed,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          article.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
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
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 80,
                          height: 80,
                          color: CupertinoColors.systemGrey5.resolveFrom(
                            context,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
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
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 0.5, thickness: 0.5),
          ),
        ],
      ),
    );
  }
}
