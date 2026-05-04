import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/article.dart';
import '../../providers/bookmarks_provider.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  WebViewController? _webController;
  bool _isLoading = false;
  double _loadingProgress = 0;

  bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    if (!_isLinux) {
      _isLoading = true;
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (p) => setState(() => _loadingProgress = p / 100),
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) => setState(() => _isLoading = false),
            onWebResourceError: (_) => setState(() => _isLoading = false),
          ),
        )
        ..loadRequest(Uri.parse(widget.article.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.any((a) => a.url == widget.article.url);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.article.source,
          style: const TextStyle(fontSize: 15),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () => Share.share(widget.article.url),
              child: const Icon(CupertinoIcons.share, size: 22),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () {
                final notifier = ref.read(bookmarksProvider.notifier);
                if (isBookmarked) {
                  notifier.remove(widget.article);
                  _showToast(context, 'Removed from Saved');
                } else {
                  notifier.add(widget.article);
                  _showToast(context, 'Saved');
                }
                HapticFeedback.lightImpact();
              },
              child: Icon(
                isBookmarked
                    ? CupertinoIcons.bookmark_fill
                    : CupertinoIcons.bookmark,
                size: 22,
                color: isBookmarked ? CupertinoColors.systemRed : null,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (_isLinux)
              _buildLinuxFallback(context)
            else
              WebViewWidget(controller: _webController!),
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  minHeight: 2,
                  backgroundColor: CupertinoColors.systemGrey5.resolveFrom(
                    context,
                  ),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    CupertinoColors.systemRed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinuxFallback(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.globe,
              size: 72,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 18),
            const Text(
              'WebView is not supported on Linux yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Open the article in your browser instead.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () async {
                final uri = Uri.parse(widget.article.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  _showToast(context, 'Unable to open browser');
                }
              },
              child: const Text('Open in Browser'),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(builder: (_) => _ToastWidget(message: message));
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), entry.remove);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  const _ToastWidget({required this.message});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
    Future.delayed(const Duration(milliseconds: 1600), () => _anim.reverse());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xDD1C1C1E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              widget.message,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
