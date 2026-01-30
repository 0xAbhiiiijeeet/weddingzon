import 'package:flutter/material.dart';
import '../models/feed_user.dart';
import '../repositories/feed_repository.dart';

class FeedProvider extends ChangeNotifier {
  final FeedRepository _feedRepository;

  FeedProvider(this._feedRepository);

  List<FeedUser> _users = [];
  String? _nextCursor;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _hasMore = true;
  String? _currentViewAs;

  List<FeedUser> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isEmpty => _users.isEmpty && !_isLoading;
  String? get currentViewAs => _currentViewAs;

  Future<void> loadFeed({String? viewAs}) async {
    if (_isLoading) return;

    if (viewAs != _currentViewAs) {
      _users = [];
      _nextCursor = null;
      _currentViewAs = viewAs;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('[FEED] Loading initial feed...');

    debugPrint('[FEED] Loading initial feed... ViewAs: $_currentViewAs');

    final response = await _feedRepository.getFeed(viewAs: _currentViewAs);

    if (response.success && response.data != null) {
      _users = response.data!.users;
      _nextCursor = response.data!.nextCursor;
      _hasMore = response.data!.hasMore;
      debugPrint('[FEED] Loaded ${_users.length} users, hasMore: $_hasMore');
    } else {
      _error = response.message ?? 'Failed to load feed';
      debugPrint('[FEED ERROR] $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    _isLoadingMore = true;
    notifyListeners();

    debugPrint('[FEED] Loading more with cursor: $_nextCursor');

    final response = await _feedRepository.getFeed(
      cursor: _nextCursor,
      viewAs: _currentViewAs,
    );

    if (response.success && response.data != null) {
      _users.addAll(response.data!.users);
      _nextCursor = response.data!.nextCursor;
      _hasMore = response.data!.hasMore;
      debugPrint(
        '[FEED] Loaded ${response.data!.users.length} more users, total: ${_users.length}',
      );
    } else {
      debugPrint('[FEED ERROR] Failed to load more: ${response.message}');
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    debugPrint('[FEED] Refreshing feed...');
    _nextCursor = null;
    _hasMore = true;
    await loadFeed();
  }

  void reset() {
    _users = [];
    _nextCursor = null;
    _isLoading = false;
    _isLoadingMore = false;
    _error = null;
    _hasMore = true;
    notifyListeners();
  }
}