import 'package:equatable/equatable.dart';

final class PaginatedResult<T> with EquatableMixin {
  const PaginatedResult({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
