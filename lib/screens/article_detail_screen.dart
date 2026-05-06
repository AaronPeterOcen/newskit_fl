// Article detail screen that loads the web article and supports sharing/bookmarking.
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

/// Screen widget that displays the full article in a WebView.
/// Provides functionality to share and bookmark articles.
class ArticleDetailScreen extends ConsumerStatefulWidget {
  /// The article to display
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

/// State for [ArticleDetailScreen] that manages WebView and loading state.
class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  /// Controller for managing the WebView widget
  WebViewController? _webController;

  /// Tracks whether the article is currently loading
  bool _isLoading = false;

  /// Progress indicator for page loading (0.0 to 1.0)
  double _loadingProgress = 0;

  /// Determines if the app is running on Linux platform
  bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    // Skip WebView initialization on Linux platform as it's not supported
    if (!_isLinux) {
      _isLoading = true;
      // Initialize the WebView controller with JavaScript support
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        // Set up navigation delegates to track loading progress and state
        ..setNavigationDelegate(
          NavigationDelegate(
            // Update loading progress indicator
            onProgress: (p) => setState(() => _loadingProgress = p / 100),
            // Mark as loading when page starts
            onPageStarted: (_) => setState(() => _isLoading = true),
            // Mark as loaded when page finishes
            onPageFinished: (_) => setState(() => _isLoading = false),
            // Handle loading errors
            onWebResourceError: (_) => setState(() => _isLoading = false),
          ),
        )
        // Load the article URL in the WebView
        ..loadRequest(Uri.parse(widget.article.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch bookmarks state to update UI when bookmarks change
    final bookmarks = ref.watch(bookmarksProvider);
    // Check if current article is bookmarked
    final isBookmarked = bookmarks.any((a) => a.url == widget.article.url);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.article.source,
          style: const TextStyle(fontSize: 15),
        ),
        // Navigation bar action buttons: Share and Bookmark
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Share article button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () => Share.share(widget.article.url),
              child: const Icon(CupertinoIcons.share, size: 22),
            ),
            // Bookmark toggle button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () {
                final notifier = ref.read(bookmarksProvider.notifier);
                // Toggle bookmark state
                if (isBookmarked) {
                  notifier.remove(widget.article);
                  _showToast(context, 'Removed from Saved');
                } else {
                  notifier.add(widget.article);
                  _showToast(context, 'Saved');
                }
                // Provide haptic feedback
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
      // Main content area with conditional WebView or fallback
      child: SafeArea(
        child: Stack(
          children: [
            // Show Linux fallback if on Linux, otherwise show WebView
            if (_isLinux)
              _buildLinuxFallback(context)
            else
              WebViewWidget(controller: _webController!),
            // Show loading progress bar at the top
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

  /// Builds a fallback UI for Linux platform where WebView is not supported.
  /// Allows users to open the article in their external browser.
  Widget _buildLinuxFallback(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Globe icon to indicate web content
            const Icon(
              CupertinoIcons.globe,
              size: 72,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 18),
            // Main message
            const Text(
              'WebView is not supported on Linux yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Instruction text
            const Text(
              'Open the article in your browser instead.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 24),
            // Button to open article in external browser
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

  /// Displays a toast notification with the given message.
  /// The toast automatically disappears after 2 seconds.
  void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    // Create a toast widget entry
    final entry = OverlayEntry(builder: (_) => _ToastWidget(message: message));
    // Insert the toast into the overlay
    overlay.insert(entry);
    // Remove the toast after 2 seconds
    Future.delayed(const Duration(seconds: 2), entry.remove);
  }
}

/// A custom toast notification widget that displays a message with fade animation.
class _ToastWidget extends StatefulWidget {
  /// The message text to display in the toast
  final String message;
  const _ToastWidget({required this.message});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

/// State for [_ToastWidget] that manages fade-in and fade-out animations.
class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  /// Controls the fade animation of the toast
  late AnimationController _anim;

  /// Animation that defines the opacity fade effect
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    // Create animation controller with 300ms duration for fade effect
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Create fade animation with ease-out curve
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    // Start the fade-in animation
    _anim.forward();
    // Start fade-out after 1.6 seconds (toast visible for ~2 seconds total)
    Future.delayed(const Duration(milliseconds: 1600), () => _anim.reverse());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Position toast at bottom of screen with fade animation
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          // Styled container for toast message
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(
                0xDD1C1C1E,
              ), // Dark semi-transparent background
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
