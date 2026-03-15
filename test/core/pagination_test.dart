import 'package:flutter_test/flutter_test.dart';
import 'package:gymos_ai/core/pagination.dart';

void main() {
  group('CallbackPagedController', () {
    test('loadInitial loads the first page', () async {
      final controller = CallbackPagedController<int>(
        (offset) async {
          expect(offset, 0);
          return const PagedResult<int>(
            items: [1, 2],
            hasMore: true,
            nextOffset: 2,
            totalCount: 4,
          );
        },
      );

      await controller.loadInitial();

      expect(controller.state.items, [1, 2]);
      expect(controller.state.isInitialLoading, isFalse);
      expect(controller.state.hasMore, isTrue);
      expect(controller.state.nextOffset, 2);
      expect(controller.state.totalCount, 4);
      expect(controller.state.error, isNull);
    });

    test('loadMore appends items and advances offset', () async {
      final controller = CallbackPagedController<int>(
        (offset) async {
          if (offset == 0) {
            return const PagedResult<int>(
              items: [1, 2],
              hasMore: true,
              nextOffset: 2,
              totalCount: 4,
            );
          }

          return const PagedResult<int>(
            items: [3, 4],
            hasMore: false,
            nextOffset: 4,
            totalCount: 4,
          );
        },
      );

      await controller.loadInitial();
      await controller.loadMore();

      expect(controller.state.items, [1, 2, 3, 4]);
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.nextOffset, 4);
      expect(controller.state.isLoadingMore, isFalse);
    });

    test('refresh resets the list from offset zero', () async {
      var refreshRound = false;
      final controller = CallbackPagedController<int>(
        (offset) async {
          expect(offset, 0);
          if (!refreshRound) {
            return const PagedResult<int>(
              items: [1, 2],
              hasMore: true,
              nextOffset: 2,
              totalCount: 2,
            );
          }

          return const PagedResult<int>(
            items: [9],
            hasMore: false,
            nextOffset: 1,
            totalCount: 1,
          );
        },
      );

      await controller.loadInitial();
      refreshRound = true;
      await controller.refresh();

      expect(controller.state.items, [9]);
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.nextOffset, 1);
      expect(controller.state.isRefreshing, isFalse);
    });

    test('loadMore is ignored when there are no more items', () async {
      var callCount = 0;
      final controller = CallbackPagedController<int>(
        (offset) async {
          callCount++;
          return const PagedResult<int>(
            items: [1],
            hasMore: false,
            nextOffset: 1,
            totalCount: 1,
          );
        },
      );

      await controller.loadInitial();
      await controller.loadMore();

      expect(callCount, 1);
      expect(controller.state.items, [1]);
    });

    test('stores fetch errors for retry UI', () async {
      final controller = CallbackPagedController<int>(
        (_) async => throw StateError('boom'),
      );

      await controller.loadInitial();

      expect(controller.state.hasError, isTrue);
      expect(controller.state.items, isEmpty);
      expect(controller.state.isInitialLoading, isFalse);
    });
  });
}
