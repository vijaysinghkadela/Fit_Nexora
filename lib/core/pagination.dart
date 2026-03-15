import 'package:flutter/foundation.dart';
import 'package:state_notifier/state_notifier.dart';

const _errorSentinel = Object();

class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.hasMore,
    required this.nextOffset,
    this.totalCount,
  });

  final List<T> items;
  final bool hasMore;
  final int nextOffset;
  final int? totalCount;
}

@immutable
class PagedListState<T> {
  const PagedListState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.nextOffset = 0,
    this.totalCount,
    this.error,
  });

  factory PagedListState.initial() => const PagedListState(
        isInitialLoading: true,
      );

  final List<T> items;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextOffset;
  final int? totalCount;
  final Object? error;

  bool get hasError => error != null;
  bool get isEmpty => !isInitialLoading && !isRefreshing && items.isEmpty && !hasError;

  PagedListState<T> copyWith({
    List<T>? items,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextOffset,
    int? totalCount,
    Object? error = _errorSentinel,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      totalCount: totalCount ?? this.totalCount,
      error: identical(error, _errorSentinel) ? this.error : error,
    );
  }
}

abstract class PagedStateNotifier<T> extends StateNotifier<PagedListState<T>> {
  PagedStateNotifier() : super(PagedListState<T>.initial());

  bool _busy = false;

  @protected
  Future<PagedResult<T>> fetchPage(int offset);

  Future<void> loadInitial() async {
    if (_busy) return;
    _busy = true;
    state = PagedListState<T>(
      items: const [],
      isInitialLoading: true,
      isRefreshing: false,
      isLoadingMore: false,
      hasMore: true,
      nextOffset: 0,
      error: null,
    );
    try {
      final result = await fetchPage(0);
      state = PagedListState<T>(
        items: result.items,
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        nextOffset: result.nextOffset,
        totalCount: result.totalCount,
        error: null,
      );
    } catch (error) {
      state = PagedListState<T>(
        items: const [],
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: true,
        nextOffset: 0,
        error: error,
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    state = state.copyWith(
      isRefreshing: true,
      error: null,
    );
    try {
      final result = await fetchPage(0);
      state = PagedListState<T>(
        items: result.items,
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        nextOffset: result.nextOffset,
        totalCount: result.totalCount,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        error: error,
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> loadMore() async {
    if (_busy ||
        state.isInitialLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    _busy = true;
    state = state.copyWith(
      isLoadingMore: true,
      error: null,
    );
    try {
      final result = await fetchPage(state.nextOffset);
      state = PagedListState<T>(
        items: [...state.items, ...result.items],
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        nextOffset: result.nextOffset,
        totalCount: result.totalCount ?? state.totalCount,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        error: error,
      );
    } finally {
      _busy = false;
    }
  }
}

class CallbackPagedController<T> extends PagedStateNotifier<T> {
  CallbackPagedController(this._fetcher);

  final Future<PagedResult<T>> Function(int offset) _fetcher;

  @override
  Future<PagedResult<T>> fetchPage(int offset) => _fetcher(offset);
}
