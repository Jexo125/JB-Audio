class PaginatedResult<T> {
  final List<T> items;
  final int? totalCount;

  PaginatedResult({
    required this.items,
    this.totalCount,
  });
}
