class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResponse<T>(
      items: List<T>.from(json['items'].map((item) => fromJson(item))),
      total: json['total'],
      page: json['page'],
      size: json['size'],
      pages: json['pages'],
    );
  }

  Map<String, dynamic> toJson(T Function(T) toJson) {
    return {
      'items': items.map((item) => toJson(item)).toList(),
      'total': total,
      'page': page,
      'size': size,
      'pages': pages,
    };
  }

  bool get hasMore => page < pages;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}