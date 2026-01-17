import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/photo_model.dart';
import '../../../shared/widgets/image_viewer.dart';
import '../../../core/services/api_service.dart'; // Added import

class PhotoManagerScreen extends StatefulWidget {
  const PhotoManagerScreen({super.key});

  @override
  State<PhotoManagerScreen> createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

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
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          final photos = user.photos;
          final photoCount = photos.length;

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
                          'Photos: $photoCount / 10',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          photoCount == 0
                              ? 'Add at least 1 photo'
                              : 'You can add ${10 - photoCount} more photos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (photoCount < 10)
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadPhotos,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate, size: 20),
                        label: Text(_isUploading ? 'Uploading...' : 'Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),

              // Photos grid
              Expanded(
                child: photos.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          final photo = photos[index];
                          return _buildPhotoCard(photo, index == 0);
                        },
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
            onPressed: _pickAndUploadPhotos,
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

  Widget _buildPhotoCard(Photo photo, bool isFirstPhoto) {
    final isProfilePhoto =
        photo.isProfile ||
        (context.read<AuthProvider>().currentUser?.profilePhoto == photo.url);

    return InkWell(
      onTap: () {
        final user = context.read<AuthProvider>().currentUser;
        if (user == null) return;

        final currentIndex = user.photos.indexWhere((p) => p.url == photo.url);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewer(
              photos: user.photos,
              initialIndex: currentIndex >= 0 ? currentIndex : 0,
              hasAccess: true, // User always has access to their own photos
              canSetProfile: true,
              canDelete: true,
              currentProfileImageUrl: user.profilePhoto,
              onSetAsProfile: (index) async {
                final photo = user.photos[index];
                debugPrint(
                  '[PHOTO_MANAGER] Clicked Set Profile. Index: $index, URL: ${photo.url}',
                );
                debugPrint('[PHOTO_MANAGER] Photo publicId: ${photo.publicId}');

                final photoId = photo.publicId;
                if (photoId != null) {
                  await _setAsProfilePhoto(photoId);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  debugPrint(
                    '[PHOTO_MANAGER] ERROR: publicId is null for photo at index $index',
                  );
                  Fluttertoast.showToast(msg: "Error: Cannot identify photo");
                }
              },
              onDelete: (index) async {
                final photo = user.photos[index];
                debugPrint('[PHOTO_MANAGER] Clicked Delete. Index: $index');

                final photoId = photo.publicId;
                if (photoId != null) {
                  await _deletePhoto(photoId, index);
                } else {
                  debugPrint(
                    '[PHOTO_MANAGER] ERROR: publicId is null for photo at index $index',
                  );
                  Fluttertoast.showToast(msg: "Error: Cannot identify photo");
                }
              },
            ),
          ),
        );
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
                  httpHeaders: headers, // Pass auth headers
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) {
                    debugPrint('[PHOTO_CARD] Error loading: $url');
                    debugPrint('[PHOTO_CARD] Error: $error');
                    return Container(
                      color: Colors.grey.shade300,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
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

  Future<void> _deletePhoto(String photoId, int index) async {
    debugPrint(
      '[PHOTO_MANAGER] Requesting delete for photo: $photoId at index $index',
    );
    final provider = context.read<ProfileProvider>();
    final success = await provider.deletePhoto(photoId);

    if (!mounted) return;

    if (success) {
      debugPrint(
        '[PHOTO_MANAGER] Photo deleted successfully. Refreshing user...',
      );
      await context.read<AuthProvider>().refreshUser();
      Fluttertoast.showToast(
        msg: 'Photo deleted',
        backgroundColor: Colors.green,
      );
    } else {
      debugPrint('[PHOTO_MANAGER] Failed to delete photo');
      Fluttertoast.showToast(
        msg: 'Failed to delete photo',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _pickAndUploadPhotos() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentPhotoCount = authProvider.currentUser?.photos.length ?? 0;
      final remainingSlots = 10 - currentPhotoCount;

      if (remainingSlots <= 0) {
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
      );

      if (pickedFiles.isEmpty) return;

      final filesToUpload = pickedFiles.take(remainingSlots).toList();
      if (filesToUpload.length < pickedFiles.length) {
        Fluttertoast.showToast(
          msg:
              'Only ${filesToUpload.length} photos will be uploaded (max 10 total)',
          backgroundColor: Colors.orange,
        );
      }

      setState(() => _isUploading = true);

      final files = filesToUpload.map((xFile) => File(xFile.path)).toList();
      final provider = context.read<ProfileProvider>();
      final success = await provider.uploadPhotos(files);

      if (!mounted) return;

      if (success) {
        await context.read<AuthProvider>().refreshUser();
        Fluttertoast.showToast(
          msg: '${files.length} photo(s) uploaded successfully',
          backgroundColor: Colors.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to upload photos',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('[PHOTO_MANAGER] Error picking/uploading: $e');
      Fluttertoast.showToast(
        msg: 'Error uploading photos',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _setAsProfilePhoto(String photoId) async {
    debugPrint('[PHOTO_MANAGER] Requesting set as profile for: $photoId');
    final provider = context.read<ProfileProvider>();
    final success = await provider.setProfilePhoto(photoId);

    if (!mounted) return;

    if (success) {
      debugPrint('[PHOTO_MANAGER] Profile photo updated. Refreshing user...');
      await context.read<AuthProvider>().refreshUser();
      Fluttertoast.showToast(
        msg: 'Profile photo updated',
        backgroundColor: Colors.green,
      );
    } else {
      debugPrint('[PHOTO_MANAGER] Failed to update profile photo');
      Fluttertoast.showToast(
        msg: 'Failed to update profile photo',
        backgroundColor: Colors.red,
      );
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
