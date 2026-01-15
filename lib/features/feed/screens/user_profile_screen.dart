import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/feed_user.dart';
import '../providers/connection_provider.dart';

class UserProfileScreen extends StatefulWidget {
  final FeedUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final PageController _photoController = PageController();

  @override
  void initState() {
    super.initState();
    // Fetch connection status when profile loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().fetchStatus(widget.user.username);
    });
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user.fullName), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Carousel
            _buildPhotoCarousel(),

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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.user.age != null)
                        Text(
                          '${widget.user.age}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Basic Info
                  _buildInfoSection(),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    final photos = widget.user.photos.isNotEmpty ? widget.user.photos : [];

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
    final isRestricted = photo.restricted;

    return Stack(
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

        // Blur effect for restricted photos
        if (isRestricted)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

        // Request Access Button
        if (isRestricted)
          Center(
            child: Consumer<ConnectionProvider>(
              builder: (context, connectionProvider, _) {
                final status = connectionProvider.getStatus(
                  widget.user.username,
                );
                final isRequesting = connectionProvider.isRequesting(
                  widget.user.username,
                );

                if (status == 'pending') {
                  return const Chip(
                    label: Text('Request Pending'),
                    backgroundColor: Colors.orange,
                  );
                }

                if (status == 'accepted' || status == 'granted') {
                  return const Chip(
                    label: Text('Access Granted'),
                    backgroundColor: Colors.green,
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open),
                  label: Text(
                    isRequesting ? 'Requesting...' : 'Request Photo Access',
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
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderPhoto() {
    return Container(
      height: 400,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.person, size: 100, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.user.location != null)
          _buildInfoRow(Icons.location_on, widget.user.location!),
        if (widget.user.occupation != null)
          _buildInfoRow(Icons.work, widget.user.occupation!),
        if (widget.user.religion != null)
          _buildInfoRow(Icons.church, widget.user.religion!),
        if (widget.user.gender != null)
          _buildInfoRow(Icons.person, widget.user.gender!),
        if (widget.user.height != null)
          _buildInfoRow(Icons.height, widget.user.height!),
        if (widget.user.maritalStatus != null)
          _buildInfoRow(Icons.favorite, widget.user.maritalStatus!),
        const SizedBox(height: 16),
        if (widget.user.aboutMe != null) ...[
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(widget.user.aboutMe!, style: const TextStyle(fontSize: 15)),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final detailsStatus = connectionProvider.getDetailsStatus(
          widget.user.username,
        );
        final connectionStatus = connectionProvider.getConnectionStatus(
          widget.user.username,
        );
        final isRequestingDetails = connectionProvider.isRequestingDetails(
          widget.user.username,
        );
        final isSendingInterest = connectionProvider.isSendingInterest(
          widget.user.username,
        );
        final isCancelling = connectionProvider.isCancellingRequest(
          widget.user.username,
        );

        return Column(
          children: [
            // Request Details Access Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    detailsStatus == 'pending' ||
                        detailsStatus == 'granted' ||
                        isRequestingDetails
                    ? null
                    : () => connectionProvider.requestDetailsAccess(
                        widget.user.username,
                      ),
                icon: isRequestingDetails
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        detailsStatus == 'granted'
                            ? Icons.check_circle
                            : detailsStatus == 'pending'
                            ? Icons.pending
                            : Icons.contact_phone,
                      ),
                label: Text(
                  isRequestingDetails
                      ? 'Requesting...'
                      : detailsStatus == 'granted'
                      ? 'Details Access Granted'
                      : detailsStatus == 'pending'
                      ? 'Request Pending'
                      : 'Request Contact Details',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: detailsStatus == 'granted'
                      ? Colors.green
                      : detailsStatus == 'pending'
                      ? Colors.orange
                      : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Send Interest / Cancel Request / Connected Button
            if (connectionStatus == 'accepted')
              // Already connected
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else if (connectionStatus == 'pending')
              // Request sent - show Cancel button
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Request Sent',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isCancelling
                          ? null
                          : () => connectionProvider.cancelConnectionRequest(
                              widget.user.username,
                            ),
                      icon: isCancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close),
                      label: Text(
                        isCancelling ? 'Cancelling...' : 'Cancel Request',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              // No request - show Send Interest button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSendingInterest
                      ? null
                      : () => connectionProvider.sendInterest(
                          widget.user.username,
                        ),
                  icon: isSendingInterest
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.favorite),
                  label: Text(
                    isSendingInterest ? 'Sending...' : 'Send Interest',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
