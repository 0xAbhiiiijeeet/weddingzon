import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:share_plus/share_plus.dart';
import '../models/feed_user.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/image_viewer.dart';

class ProfileCard extends StatefulWidget {
  final FeedUser user;
  final bool readOnly;

  const ProfileCard({super.key, required this.user, this.readOnly = false});

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
    final photos = widget.user.photos.isNotEmpty ? widget.user.photos : [];

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[ProfileCard] build called');
    debugPrint('[ProfileCard] username: ${widget.user.username}');
    debugPrint('[ProfileCard] readOnly: ${widget.readOnly}');
    debugPrint('═══════════════════════════════════════════════════════');

    return InkWell(
      onTap: () {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('[ProfileCard] Card tapped!');
        debugPrint('[ProfileCard] Navigating to profile');
        debugPrint('[ProfileCard] username: ${widget.user.username}');
        debugPrint('[ProfileCard] readOnly: ${widget.readOnly}');
        debugPrint(
          '[ProfileCard] Arguments: {username: ${widget.user.username}, readOnly: ${widget.readOnly}}',
        );
        debugPrint('═══════════════════════════════════════════════════════');
        Navigator.pushNamed(
          context,
          '/profile/user',
          arguments: {
            'username': widget.user.username,
            'readOnly': widget.readOnly,
          },
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoCarousel(photos),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareProfile(),
                tooltip: 'Share Profile',
              ),
            ),
          ),

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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: InkWell(
        onTap: () {
          int currentIndex = widget.user.photos.indexWhere(
            (p) => p.url == photo.url,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageViewer(
                photos: widget.user.photos,
                initialIndex: currentIndex >= 0 ? currentIndex : 0,
                hasAccess: true,
                canSetProfile: false,
                canDelete: false,
              ),
            ),
          );
        },
        child: CachedNetworkImage(
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
      ),
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

  void _shareProfile() {
    debugPrint('[Share] ========================================');
    debugPrint('[Share] ProfileCard: Share button clicked');
    debugPrint('[Share] User: ${widget.user.fullName}');
    debugPrint('[Share] Username: ${widget.user.username}');

    final profileUrl = AppConstants.getProfileDeepLink(widget.user.username);
    final shareText =
        'Check out ${widget.user.fullName}\'s profile on WeddingZon!\n$profileUrl';

    debugPrint('[Share] Profile URL: $profileUrl');
    debugPrint('[Share] Share text: $shareText');
    debugPrint('[Share] Invoking native share...');

    try {
      Share.share(
        shareText,
        subject: '${widget.user.fullName} - WeddingZon Profile',
      );
      debugPrint('[Share] ✅ Share dialog opened successfully');
    } catch (e, stackTrace) {
      debugPrint('[Share] ❌ Share failed: $e');
      debugPrint('[Share] Stack trace: $stackTrace');
    }
    debugPrint('[Share] ========================================');
  }
}
