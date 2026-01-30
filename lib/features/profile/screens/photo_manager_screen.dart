import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/profile_provider.dart';
import '../providers/photo_upload_provider.dart';
import '../models/photo_upload_item.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/photo_model.dart';
import '../../../shared/widgets/image_viewer.dart';
import '../../../core/services/api_service.dart';

class PhotoManagerScreen extends StatefulWidget {
  const PhotoManagerScreen({super.key});

  @override
  State<PhotoManagerScreen> createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _wasUploading = false;

  @override
  void initState() {
    super.initState();
    final uploadProvider = context.read<PhotoUploadProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      uploadProvider.clearCompleted();
    });

    uploadProvider.addListener(_onUploadStateChanged);
  }

  @override
  void dispose() {
    context.read<PhotoUploadProvider>().removeListener(_onUploadStateChanged);
    super.dispose();
  }

  void _onUploadStateChanged() {
    final provider = context.read<PhotoUploadProvider>();
    final isUploadingNow = provider.queue.any(
      (i) =>
          i.status == UploadStatus.pending ||
          i.status == UploadStatus.uploading,
    );

    if (_wasUploading && !isUploadingNow) {
      debugPrint('[PHOTO_MANAGER] Batch upload finished. Refreshing user...');
      context.read<AuthProvider>().refreshUser().then((_) {
        provider.clearCompleted();
      });
    }

    _wasUploading = isUploadingNow;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showPhotoGuidelines,
          ),
        ],
      ),
      body: Consumer2<AuthProvider, PhotoUploadProvider>(
        builder: (context, authProvider, uploadProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          final serverPhotos = user.photos;
          final uploadQueue = uploadProvider.queue;

          final validQueueCount = uploadQueue
              .where((i) => i.status != UploadStatus.error)
              .length;
          final totalPhotos = serverPhotos.length + validQueueCount;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photos: $totalPhotos / 10',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalPhotos == 0
                              ? 'Add at least 1 photo'
                              : 'You can add ${10 - totalPhotos} more photos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (totalPhotos < 10)
                      ElevatedButton.icon(
                        onPressed: () => _pickAndUploadPhotos(10 - totalPhotos),
                        icon: const Icon(Icons.add_photo_alternate, size: 20),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: (serverPhotos.isEmpty && uploadQueue.isEmpty)
                    ? _buildEmptyState()
                    : GridView(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                        children: [
                          ...serverPhotos.asMap().entries.map((entry) {
                            return _buildServerPhotoCard(
                              entry.value,
                              entry.key == 0,
                            );
                          }),

                          ...uploadQueue.map((item) {
                            return _buildUploadCard(item);
                          }),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No photos yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos to make your profile stand out!',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _pickAndUploadPhotos(10),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Photos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerPhotoCard(Photo photo, bool isFirstPhoto) {
    final isProfilePhoto =
        photo.isProfile ||
        (context.read<AuthProvider>().currentUser?.profilePhoto == photo.url);

    return InkWell(
      onTap: () {
        _openImageViewer(photo);
      },
      child: FutureBuilder<Map<String, String>>(
        future: _getAuthHeaders(),
        builder: (context, snapshot) {
          final headers = snapshot.data ?? {};

          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: photo.url,
                  httpHeaders: headers,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => _buildErrorWidget(),
                ),
              ),
              if (isProfilePhoto)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUploadCard(PhotoUploadItem item) {

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(item.file, fit: BoxFit.cover),
        ),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withOpacity(0.3),
          ),
        ),

        Center(child: _buildStatusIndicator(item)),

        if (item.status == UploadStatus.error)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () =>
                      context.read<PhotoUploadProvider>().retry(item.id),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.refresh, color: Colors.blue, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () =>
                      context.read<PhotoUploadProvider>().remove(item.id),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.close, color: Colors.red, size: 20),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator(PhotoUploadItem item) {
    switch (item.status) {
      case UploadStatus.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.white, size: 32);
      case UploadStatus.uploading:
        return const CircularProgressIndicator(color: Colors.white);
      case UploadStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 48);
      case UploadStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 48);
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey.shade300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Failed to load',
            style: TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openImageViewer(Photo photo) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final unrestrictedPhotos = user.photos
        .map((p) => p.copyWith(restricted: false, isProfile: false))
        .toList();
    final currentIndex = unrestrictedPhotos.indexWhere(
      (p) => p.url == photo.url,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          photos: unrestrictedPhotos,
          initialIndex: currentIndex >= 0 ? currentIndex : 0,
          hasAccess: true,
          canSetProfile: true,
          canDelete: true,
          currentProfileImageUrl: user.profilePhoto,
          onSetAsProfile: (index) async {
            final photo = user.photos[index];
            final photoId = photo.publicId;
            if (photoId != null) {
              final success = await _setAsProfilePhoto(photoId);
              if (success && mounted) {
                Navigator.pop(context);
              }
            } else {
              Fluttertoast.showToast(msg: "Error: Cannot identify photo");
            }
          },
          onDelete: (index) async {
            final photo = user.photos[index];
            final photoId = photo.publicId;
            if (photoId != null) {
              final success = await _deletePhoto(photoId, index);
              if (success && mounted) {
                Navigator.pop(context);
              }
            } else {
              Fluttertoast.showToast(msg: "Error: Cannot identify photo");
            }
          },
        ),
      ),
    );
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final apiService = context.read<ApiService>();
      final cookieString = await apiService.getCookieString();
      if (cookieString.isNotEmpty) {
        return {'Cookie': cookieString};
      }
    } catch (e) {
      debugPrint('Error getting auth headers: $e');
    }
    return {};
  }

  Future<bool> _deletePhoto(String photoId, int index) async {
    final provider = context.read<ProfileProvider>();
    final success = await provider.deletePhoto(photoId);

    if (!mounted) return false;

    if (success) {
      await context.read<AuthProvider>().refreshUser();
      Fluttertoast.showToast(
        msg: 'Photo deleted',
        backgroundColor: Colors.green,
      );
      return true;
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to delete photo',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<void> _pickAndUploadPhotos(int maxPhotos) async {
    try {
      if (maxPhotos <= 0) {
        Fluttertoast.showToast(
          msg: 'Maximum 10 photos allowed',
          backgroundColor: Colors.orange,
        );
        return;
      }

      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        limit: maxPhotos,
      );

      if (pickedFiles.isEmpty) return;

      final filesToUpload = pickedFiles.take(maxPhotos).toList();
      if (filesToUpload.length < pickedFiles.length) {
        Fluttertoast.showToast(
          msg: 'Only ${filesToUpload.length} photos added (limit reached)',
          backgroundColor: Colors.orange,
        );
      }

      final files = filesToUpload.map((xFile) => File(xFile.path)).toList();

      if (mounted) {
        context.read<PhotoUploadProvider>().addFiles(files);



      }
    } catch (e) {
      debugPrint('[PHOTO_MANAGER] Error picking/uploading: $e');
      Fluttertoast.showToast(
        msg: 'Error picking photos',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<bool> _setAsProfilePhoto(String photoId) async {
    final provider = context.read<ProfileProvider>();
    final success = await provider.setProfilePhoto(photoId);

    if (!mounted) return false;

    if (success) {
      await context.read<AuthProvider>().refreshUser();
      Fluttertoast.showToast(
        msg: 'Profile photo updated',
        backgroundColor: Colors.green,
      );
      return true;
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to update profile photo',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  void _showPhotoGuidelines() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Photo Guidelines'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Upload clear, recent photos'),
            Text('• Face should be clearly visible'),
            Text('• Avoid group photos'),
            Text('• Maximum 10 photos allowed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}