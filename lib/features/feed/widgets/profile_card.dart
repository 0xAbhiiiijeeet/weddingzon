import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:provider/provider.dart';
import '../models/feed_user.dart';
import '../providers/connection_provider.dart';

class ProfileCard extends StatefulWidget {
  final FeedUser user;

  const ProfileCard({super.key, required this.user});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  final PageController _photoController = PageController();

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.user.photos.isNotEmpty
        ? widget.user.photos
        : []; // Will show placeholder if empty

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/profile/user',
          arguments: widget.user.username,
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Carousel
            _buildPhotoCarousel(photos),

            // User Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Age
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.user.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.user.age != null)
                        Text(
                          '${widget.user.age}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  if (widget.user.location != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.user.location!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Occupation
                  if (widget.user.occupation != null)
                    Row(
                      children: [
                        const Icon(Icons.work, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.user.occupation!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Religion
                  if (widget.user.religion != null)
                    Row(
                      children: [
                        const Icon(Icons.church, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.user.religion!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // About Me
                  if (widget.user.aboutMe != null)
                    Text(
                      widget.user.aboutMe!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel(List photos) {
    if (photos.isEmpty) {
      return _buildPlaceholderPhoto();
    }

    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          PageView.builder(
            controller: _photoController,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _buildPhotoItem(photo);
            },
          ),

          // Dots Indicator
          if (photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _photoController,
                  count: photos.length,
                  effect: const WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: Colors.white,
                    dotColor: Colors.white54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(photo) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final photoStatus = connectionProvider.getStatus(widget.user.username);
        final hasPhotoAccess =
            photoStatus == 'granted' || photoStatus == 'accepted';
        final isRestricted = photo.restricted && !hasPhotoAccess;
        final isRequesting = connectionProvider.isRequesting(
          widget.user.username,
        );

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: photo.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 64, color: Colors.grey),
                ),
              ),

              // Blur effect for restricted photos without access
              if (isRestricted)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Icon(Icons.lock, size: 40, color: Colors.white),
                    ),
                  ),
                ),

              // Request Access Button - only show for restricted photos without access
              if (isRestricted)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: () {
                      if (photoStatus == 'pending') {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Request Pending',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ElevatedButton.icon(
                        onPressed: isRequesting
                            ? null
                            : () => connectionProvider.requestAccess(
                                widget.user.username,
                              ),
                        icon: isRequesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.lock_open),
                        label: Text(
                          isRequesting ? 'Requesting...' : 'Request Access',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      );
                    }(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderPhoto() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        height: 400,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.person, size: 100, color: Colors.grey),
        ),
      ),
    );
  }
}
