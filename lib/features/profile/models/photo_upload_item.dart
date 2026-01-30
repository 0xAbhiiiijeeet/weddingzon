import 'dart:io';

enum UploadStatus { pending, uploading, success, error }

class PhotoUploadItem {
  final String id;
  final File file;
  UploadStatus status;
  double progress;
  String? errorMessage;
  String? uploadedUrl;
  String? publicId;

  PhotoUploadItem({
    required this.id,
    required this.file,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
    this.uploadedUrl,
    this.publicId,
  });

  PhotoUploadItem copyWith({
    String? id,
    File? file,
    UploadStatus? status,
    double? progress,
    String? errorMessage,
    String? uploadedUrl,
    String? publicId,
  }) {
    return PhotoUploadItem(
      id: id ?? this.id,
      file: file ?? this.file,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      publicId: publicId ?? this.publicId,
    );
  }
}