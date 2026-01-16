import 'package:flutter/material.dart';
import '../repositories/explore_repository.dart';
import '../../../core/models/api_response.dart';

class ExploreProvider with ChangeNotifier {
  final ExploreRepository _repository;

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _nextCursor;
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};

  ExploreProvider(this._repository);

  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get filters => _filters;
  bool get hasActiveFilters => _filters.isNotEmpty;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadUsers({bool refresh = true}) async {
    if (_isLoading) return;

    if (refresh) {
      _users.clear();
      _hasMore = true;
      _nextCursor = null;
    } else if (!_hasMore) {
      return;
    }

    _setLoading(true);
    debugPrint('[EXPLORE] ========== LOADING USERS ==========');
    debugPrint('[EXPLORE] Cursor: $_nextCursor');
    debugPrint('[EXPLORE] Search: $_searchQuery');
    debugPrint('[EXPLORE] Filters: $_filters');

    try {
      ApiResponse<List<dynamic>> response;
      List<Map<String, dynamic>> newUsers = [];
      String? nextCursor;

      if (_searchQuery.isNotEmpty) {
        response = await _repository.searchUsers(query: _searchQuery, page: 1);
      } else if (_filters.isNotEmpty) {
        response = await _repository.getFeedWithFilters(
          filters: _filters,
          page: 1,
        );
      } else {
        response = await _repository.getFeed(cursor: _nextCursor);
      }

      if (response.success && response.data != null) {
        newUsers = List<Map<String, dynamic>>.from(response.data!);
        nextCursor = response.nextCursor;

        // Apply client-side filtering if backend doesn't support it
        if (_filters.isNotEmpty && newUsers.isNotEmpty) {
          newUsers = _applyClientSideFilters(newUsers);
          debugPrint('[EXPLORE] After client filter: ${newUsers.length} users');
        } else {
          debugPrint('[EXPLORE] Returned ${newUsers.length} users');
        }
      } else {
        debugPrint('[EXPLORE] Failed: ${response.message}');
      }

      if (newUsers.isEmpty) {
        if (refresh) _users.clear();
        _hasMore = false;
        debugPrint('[EXPLORE] No more users to load');
      } else {
        if (refresh) {
          _users = newUsers;
        } else {
          _users.addAll(newUsers);
        }

        _nextCursor = nextCursor;
        if (_nextCursor == null) {
          _hasMore = false;
        }
      }
    } catch (e) {
      debugPrint('[EXPLORE] Exception: $e');
    }

    _setLoading(false);
  }

  List<Map<String, dynamic>> _applyClientSideFilters(
    List<Map<String, dynamic>> users,
  ) {
    return users.where((user) {
      // Age filter
      if (_filters.containsKey('minAge') || _filters.containsKey('maxAge')) {
        final age = user['age'] as int?;
        if (age == null) return false;

        final minAge = _filters['minAge'] as int? ?? 0;
        final maxAge = _filters['maxAge'] as int? ?? 100;
        if (age < minAge || age > maxAge) return false;
      }

      // Height filter
      if (_filters.containsKey('minHeight') ||
          _filters.containsKey('maxHeight')) {
        final heightStr = user['height']?.toString() ?? '';
        // Parse height like "5'6" to numeric
        final height = _parseHeight(heightStr);
        if (height == null) return false;

        final minHeight = (_filters['minHeight'] as num?)?.toDouble() ?? 0;
        final maxHeight = (_filters['maxHeight'] as num?)?.toDouble() ?? 10;
        if (height < minHeight || height > maxHeight) return false;
      }

      // Religion filter
      if (_filters.containsKey('religion')) {
        final religion = user['religion']?.toString().toLowerCase() ?? '';
        final filterReligion =
            (_filters['religion'] as String?)?.toLowerCase() ?? '';
        if (filterReligion.isNotEmpty && religion != filterReligion)
          return false;
      }

      // City filter
      if (_filters.containsKey('city')) {
        final city = user['city']?.toString().toLowerCase() ?? '';
        final filterCity = (_filters['city'] as String?)?.toLowerCase() ?? '';
        if (filterCity.isNotEmpty && !city.contains(filterCity)) return false;
      }

      return true;
    }).toList();
  }

  double? _parseHeight(String heightStr) {
    // Parse formats like "5'6" or "5.6"
    if (heightStr.contains("'")) {
      final parts = heightStr.replaceAll('"', '').split("'");
      if (parts.length >= 1) {
        final feet = double.tryParse(parts[0]) ?? 0;
        final inches = parts.length > 1 ? (double.tryParse(parts[1]) ?? 0) : 0;
        return feet + (inches / 12);
      }
    }
    return double.tryParse(heightStr);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await loadUsers(refresh: false);
  }

  Future<void> searchUsers(String query) async {
    _searchQuery = query.trim();
    debugPrint('[EXPLORE] Search query updated: $_searchQuery');
    await loadUsers(refresh: true);
  }

  Future<void> applyFilters(Map<String, dynamic> filters) async {
    _filters = Map.from(filters);
    debugPrint('[EXPLORE] Filters applied: $_filters');
    await loadUsers(refresh: true);
  }

  Future<void> removeFilter(String filterKey) async {
    if (filterKey == 'age') {
      _filters.remove('minAge');
      _filters.remove('maxAge');
    } else if (filterKey == 'height') {
      _filters.remove('minHeight');
      _filters.remove('maxHeight');
    } else {
      _filters.remove(filterKey);
    }

    debugPrint('[EXPLORE] Filter removed: $filterKey');
    await loadUsers(refresh: true);
  }

  Future<void> clearFilters() async {
    _filters.clear();
    debugPrint('[EXPLORE] All filters cleared');
    await loadUsers(refresh: true);
  }

  void reset() {
    _users.clear();
    _nextCursor = null;
    _hasMore = true;
    _searchQuery = '';
    _filters.clear();
    notifyListeners();
  }
}
