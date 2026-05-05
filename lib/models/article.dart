// Article model used across the app to represent news content.
class Article {
  final String title;
  final String? description;
  final String? imageUrl;
  final String url;
  final String source;
  final DateTime publishedAt;

  const Article({
    required this.title,
    this.description,
    this.imageUrl,
    required this.url,
    required this.source,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String? ?? 'No title',
      description: json['description'] as String?,
      imageUrl: json['urlToImage'] as String?,
      url: json['url'] as String? ?? '',
      source:
          (json['source'] as Map<String, dynamic>?)?['name'] as String? ??
          'Unknown',
      publishedAt:
          DateTime.tryParse(json['publishedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'urlToImage': imageUrl,
    'url': url,
    'source': {'name': source},
    'publishedAt': publishedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Article && url == other.url;

  @override
  int get hashCode => url.hashCode;
}
