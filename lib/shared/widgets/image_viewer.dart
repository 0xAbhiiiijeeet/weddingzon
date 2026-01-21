import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../core/models/photo_model.dart';

class ImageViewer extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final bool hasAccess;
  final bool canSetProfile;
  final bool canDelete;
  final String? currentProfileImageUrl;
  final Function(int)? onSetAsProfile;
  final Function(int)? onDelete;

  const ImageViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.hasAccess = false,
    this.canSetProfile = false,
    this.canDelete = false,
    this.currentProfileImageUrl,
    this.onSetAsProfile,
    this.onDelete,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Determine if a photo should be shown blurred
  bool _shouldBlur(Photo photo) {
    // Don't blur if user has access or if it's a profile photo
    if (widget.hasAccess || photo.isProfile) {
      return false;
    }
    // Blur non-profile photos without access
    // We default to true to match ProfileCard logic where all non-profile
    // photos are treated as restricted if access is not granted.
    return true;
  }

  /// Get the appropriate URL to display
  String _getDisplayUrl(Photo photo) {
    if (_shouldBlur(photo)) {
      // Always return original URL
      return photo.url;
    }
    return photo.url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image Gallery
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final photo = widget.photos[index];
              final photoShouldBlur = _shouldBlur(photo);
              final photoDisplayUrl = _getDisplayUrl(photo);

              return PhotoViewGalleryPageOptions.customChild(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PhotoView(
                      imageProvider: CachedNetworkImageProvider(
                        photoDisplayUrl,
                      ),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                      heroAttributes: PhotoViewHeroAttributes(tag: photo.url),
                      errorBuilder: (context, error, stackTrace) {
                        if (photoShouldBlur) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Colors.white70,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Restricted Content",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Request access to view this photo",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 50,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Failed to load image",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Client-side blur overlay
                    if (photoShouldBlur)
                      Positioned.fill(
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: const Center(
                                child: Icon(
                                  Icons.lock,
                                  size: 64,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            itemCount: widget.photos.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),

          // Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      '${_currentIndex + 1}/${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Actions
          if (widget.canSetProfile || widget.canDelete)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.canSetProfile && widget.onSetAsProfile != null)
                        _buildActionButton(
                          icon: Icons.person_pin,
                          label: 'Set Profile',
                          onTap: () => widget.onSetAsProfile!(_currentIndex),
                          isEnabled:
                              widget.photos[_currentIndex].url !=
                              widget.currentProfileImageUrl,
                        ),
                      if (widget.canDelete && widget.onDelete != null)
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          onTap: () => _confirmDelete(context),
                          color: Colors.redAccent,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    bool isEnabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint(
            '[IMAGE_VIEWER] Button tapped: $label, isEnabled: $isEnabled',
          );
          if (isEnabled) {
            onTap();
          } else {
            debugPrint('[IMAGE_VIEWER] Button disabled');
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.white.withAlpha(51)
                : Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEnabled
                  ? color.withAlpha(128)
                  : Colors.grey.withAlpha(76),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isEnabled ? color : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isEnabled ? color : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!(_currentIndex);
    }
  }
}
