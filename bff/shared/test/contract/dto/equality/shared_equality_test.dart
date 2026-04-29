// Wave 0 (RED) — tests for value-equality across the shared wrapper DTOs
// (StandardResponse, PaginatedList, PaginationMeta, BackendError, plus the
// auxiliary types defined next to them: ResponseMeta, IdData,
// ErrorObservability, BackendErrorResponse).
//
// These tests currently FAIL because the DTOs do not mix in Equatable yet.
// Wave 1 implementer will add `with Equatable` + `props` to each class,
// turning this entire file GREEN.
//
// Note: StandardResponse<T> and PaginatedList<T> will only be fully transitive
// when T itself is Equatable. Here we parametrize with primitive types (String,
// int) to exercise the generic path with a type that is naturally Equatable.

import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Shared wrapper DTOs — value equality (Wave 0 RED)', () {
    // ------------------------------------------------------------------ //
    // standard_response.dart                                              //
    // ------------------------------------------------------------------ //
    test('ResponseMeta equals by value', () {
      ResponseMeta build() =>
          ResponseMeta(timestamp: '2026-04-17T10:00:00Z');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('StandardResponse<String> equals by value', () {
      StandardResponse<String> build() => StandardResponse<String>(
        data: 'hello',
        meta: ResponseMeta(timestamp: '2026-04-17T10:00:00Z'),
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('IdData equals by value', () {
      IdData build() => IdData(id: 'id-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // pagination_meta.dart                                                //
    // ------------------------------------------------------------------ //
    test('PaginationMeta equals by value', () {
      PaginationMeta build() => PaginationMeta(
        pageSize: 20,
        totalCount: 100,
        hasMore: true,
        nextCursor: 'cursor-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // paginated_list.dart                                                 //
    // ------------------------------------------------------------------ //
    test('PaginatedList<String> equals by value', () {
      PaginatedList<String> build() => PaginatedList<String>(
        data: ['a', 'b'],
        meta: PaginationMeta(pageSize: 20, totalCount: 2, hasMore: false),
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // backend_error.dart                                                  //
    // ------------------------------------------------------------------ //
    test('BackendError equals by value', () {
      BackendError build() => BackendError(
        id: 'err-1',
        code: 'PAT-001',
        message: 'something broke',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ErrorObservability equals by value', () {
      ErrorObservability build() => ErrorObservability(
        category: 'domain',
        severity: 'error',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('BackendErrorResponse equals by value', () {
      BackendErrorResponse build() => BackendErrorResponse(
        error: BackendError(
          id: 'err-1',
          code: 'PAT-001',
          message: 'something broke',
        ),
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });
  });
}
