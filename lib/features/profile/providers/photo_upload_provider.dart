import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../repositories/user_repository.dart';
import '../models/photo_upload_item.dart';

class PhotoUploadProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final List<PhotoUploadItem> _queue = [];
  bool _isProcessing = false;
  final _uuid = const Uuid();

  PhotoUploadProvider(this._userRepository);

  List<PhotoUploadItem> get queue => List.unmodifiable(_queue);
  bool get isProcessing => _isProcessing;

  /// Add new files to the upload queue and start processing
  void addFiles(List<File> files) {
    if (files.isEmpty) return;

    for (var file in files) {
      final id = _uuid.v4();
      _queue.add(PhotoUploadItem(id: id, file: file));
    }

    notifyListeners();
    _processQueue();
  }

  /// Recursively process the queue
  Future<void> _processQueue() async {
    if (_isProcessing) return;

    // Find next pending item
    final pendingIndex = _queue.indexWhere(
      (item) => item.status == UploadStatus.pending,
    );

    // If no pending items found, we check if there are any that were stuck in uploading state (maybe app crash recovery?)
    // But for now, we just stop if nothing is pending.
    if (pendingIndex == -1) {
      _isProcessing = false;
      return;
    }

    _isProcessing = true;
    final item = _queue[pendingIndex];

    // Update status to uploading
    _updateItemStatus(item.id, UploadStatus.uploading);

    try {
      debugPrint('[PHOTO_UPLOAD] Uploading item: ${item.id}');

      // We pass a single file as a list because the repo method expects a list
      // But we want to upload sequentially, so we wrap it.
      // However, the repo returns List<Photo>. We take the first one.

      final response = await _userRepository.uploadPhotos(
        [item.file],
        onProgress: (sent, total) {
          // Optional: Implement progress tracking if Repository supports it per-file or overall.
          // Current repo interface uses `onSendProgress` for the whole batch.
          // Since we are sending 1 file, this is accurate for this item.
          final progress = total > 0 ? sent / total : 0.0;
          _updateItemProgress(item.id, progress);
        },
      );

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final uploadedPhoto = response.data!.first;

        // Update item with success info
        final index = _queue.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _queue[index] = _queue[index].copyWith(
            status: UploadStatus.success,
            uploadedUrl: uploadedPhoto.url,
            publicId: uploadedPhoto.publicId,
            progress: 1.0,
          );
          notifyListeners();
        }
      } else {
        // Handle API failure
        _markAsError(item.id, response.message ?? 'Upload failed');
      }
    } catch (e) {
      // Handle Network/Exception failure
      debugPrint('[PHOTO_UPLOAD] Exception: $e');
      _markAsError(item.id, 'Network error');
    }

    // Continue to next item
    _isProcessing = false;
    _processQueue();
  }

  void _updateItemStatus(String id, UploadStatus status) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void _updateItemProgress(String id, double progress) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(progress: progress);
      notifyListeners();
    }
  }

  void _markAsError(String id, String message) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: UploadStatus.error,
        errorMessage: message,
      );
      notifyListeners();
    }
  }

  /// Retry a failed upload
  void retry(String id) {
    _updateItemStatus(id, UploadStatus.pending);
    _processQueue();
  }

  /// Remove an item from the queue (e.g. cancel or remove finished/failed item)
  void remove(String id) {
    _queue.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Clear all completed items (success)
  void clearCompleted() {
    _queue.removeWhere((item) => item.status == UploadStatus.success);
    notifyListeners();
  }
}
