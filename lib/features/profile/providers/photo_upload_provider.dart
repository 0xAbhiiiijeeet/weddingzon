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

  void addFiles(List<File> files) {
    if (files.isEmpty) return;

    for (var file in files) {
      final id = _uuid.v4();
      _queue.add(PhotoUploadItem(id: id, file: file));
    }

    notifyListeners();
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;

    final pendingIndex = _queue.indexWhere(
      (item) => item.status == UploadStatus.pending,
    );

    if (pendingIndex == -1) {
      _isProcessing = false;
      return;
    }

    _isProcessing = true;
    final item = _queue[pendingIndex];

    _updateItemStatus(item.id, UploadStatus.uploading);

    try {
      debugPrint('[PHOTO_UPLOAD] Uploading item: ${item.id}');


      final response = await _userRepository.uploadPhotos(
        [item.file],
        onProgress: (sent, total) {
          final progress = total > 0 ? sent / total : 0.0;
          _updateItemProgress(item.id, progress);
        },
      );

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final uploadedPhoto = response.data!.first;

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
        _markAsError(item.id, response.message ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('[PHOTO_UPLOAD] Exception: $e');
      _markAsError(item.id, 'Network error');
    }

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

  void retry(String id) {
    _updateItemStatus(id, UploadStatus.pending);
    _processQueue();
  }

  void remove(String id) {
    _queue.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _queue.removeWhere((item) => item.status == UploadStatus.success);
    notifyListeners();
  }
}