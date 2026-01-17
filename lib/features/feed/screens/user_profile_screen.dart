import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/feed_user.dart';
import '../providers/connection_provider.dart';
import '../../../shared/widgets/image_viewer.dart';
import '../../profile/repositories/user_repository.dart';
import '../../../core/services/api_service.dart';
import '../../../core/routes/app_routes.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final PageController _photoController = PageController();
  FeedUser? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = context.read<ApiService>();
      final userRepository = UserRepository(apiService);
      final response = await userRepository.getUserByUsername(widget.username);

      if (response.success && response.data != null) {
        setState(() {
          _user = FeedUser.fromJson(response.data!);
          _isLoading = false;
        });

        // Fetch connection status
        if (mounted) {
          context.read<ConnectionProvider>().fetchStatus(widget.username);
        }
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'User not found', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadUserProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_user!.fullName),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Profile Photo and Basic Info
            _buildHeaderSection(),

            const SizedBox(height: 16),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // About Me Section
                  if (_user!.aboutMe != null && _user!.aboutMe!.isNotEmpty)
                    _buildSectionCard(
                      icon: Icons.person_outline,
                      title: 'About Me',
                      child: Text(
                        _user!.aboutMe!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),

                  // Photos Section
                  _buildPhotosSection(),

                  // Details Sections (Career, Family, Lifestyle, Attributes)
                  // Show locked state if details access not granted
                  Consumer<ConnectionProvider>(
                    builder: (context, connectionProvider, _) {
                      final detailsStatus = connectionProvider.getDetailsStatus(
                        widget.username,
                      );
                      final hasDetailsAccess =
                          detailsStatus == 'granted' ||
                          detailsStatus == 'accepted';

                      if (!hasDetailsAccess) {
                        return _buildDetailsLockedSection(connectionProvider);
                      }

                      // Show all details sections if access granted
                      return Column(
                        children: [
                          _buildCareerSection(),
                          _buildFamilySection(),
                          _buildLifestyleSection(),
                          _buildAttributesSection(),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _user!.profilePhoto != null
                    ? CachedNetworkImageProvider(_user!.profilePhoto!)
                    : null,
                child: _user!.profilePhoto == null
                    ? Text(
                        _user!.fullName.isNotEmpty
                            ? _user!.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (_user!.location != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _user!.location!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_user!.occupation != null)
                      _buildChip(_user!.occupation!, Colors.blue),
                    if (_user!.religion != null)
                      _buildChip(_user!.religion!, Colors.orange),
                    if (_user!.maritalStatus != null)
                      _buildChip(_user!.maritalStatus!, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    final photos = _user!.photos;

    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final photoStatus = connectionProvider.getStatus(widget.username);
        final hasPhotoAccess =
            photoStatus == 'granted' || photoStatus == 'accepted';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.photo_library,
                        size: 20,
                        color: Colors.deepPurple,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  if (!hasPhotoAccess && photos.isNotEmpty)
                    _buildRequestAccessButton(connectionProvider),
                ],
              ),
              const SizedBox(height: 12),
              if (photos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No photos available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _photoController,
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          final photo = photos[index];

                          // NEW LOGIC: Profile photos always visible, others require access
                          String imageUrl;
                          bool shouldApplyLocalBlur = false;

                          if (photo.isProfile) {
                            // Profile photos are ALWAYS visible
                            imageUrl = photo.url;
                          } else if (hasPhotoAccess) {
                            // User has permission - show original
                            imageUrl = photo.url;
                          } else {
                            // User DOESN'T have permission - blur non-profile photos
                            if (photo.blurredUrl != null &&
                                photo.blurredUrl!.isNotEmpty) {
                              // Backend provided pre-blurred version
                              imageUrl = photo.blurredUrl!;
                            } else {
                              // Fallback: use original with client-side blur
                              imageUrl = photo.url;
                              shouldApplyLocalBlur = true;
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ImageViewer(
                                            photos: photos,
                                            initialIndex: index,
                                            hasAccess: hasPhotoAccess,
                                            canSetProfile: false,
                                            canDelete: false,
                                          ),
                                        ),
                                      );
                                    },
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.error,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    ),
                                  ),
                                  // Apply blur overlay only if needed (fallback)
                                  if (shouldApplyLocalBlur)
                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 15,
                                        sigmaY: 15,
                                      ),
                                      child: Container(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.lock,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (photos.length > 1)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _photoController,
                              count: photos.length,
                              effect: const WormEffect(
                                dotHeight: 8,
                                dotWidth: 8,
                                activeDotColor: Colors.deepPurple,
                                dotColor: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestAccessButton(ConnectionProvider connectionProvider) {
    final status = connectionProvider.getStatus(widget.username);
    final isRequesting = connectionProvider.isRequesting(widget.username);
    final isCancelling = connectionProvider.isCancellingRequest(
      widget.username,
    );

    if (status == 'pending') {
      return OutlinedButton.icon(
        onPressed: isCancelling
            ? null
            : () =>
                  connectionProvider.cancelPhotoAccessRequest(widget.username),
        icon: isCancelling
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.close, size: 16),
        label: Text(isCancelling ? 'Cancelling...' : 'Cancel Request'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      );
    }

    return TextButton.icon(
      onPressed: isRequesting
          ? null
          : () => connectionProvider.requestAccess(widget.username),
      icon: isRequesting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.lock_open, size: 16),
      label: Text(isRequesting ? 'Requesting...' : 'Request Access'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildDetailsLockedSection(ConnectionProvider connectionProvider) {
    final detailsStatus = connectionProvider.getDetailsStatus(widget.username);
    final isRequestingDetails = connectionProvider.isRequestingDetails(
      widget.username,
    );
    final isCancelling = connectionProvider.isCancellingRequest(
      widget.username,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 40,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Details Locked',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Request access to view this user\'s full\npersonal, family, and lifestyle details.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          if (detailsStatus == 'pending')
            OutlinedButton.icon(
              onPressed: isCancelling
                  ? null
                  : () => connectionProvider.cancelDetailsAccessRequest(
                      widget.username,
                    ),
              icon: isCancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Icon(Icons.close),
              label: Text(isCancelling ? 'Cancelling...' : 'Cancel Request'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: isRequestingDetails
                  ? null
                  : () => connectionProvider.requestDetailsAccess(
                      widget.username,
                    ),
              icon: isRequestingDetails
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
                isRequestingDetails
                    ? 'Requesting...'
                    : 'Request Details Access',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCareerSection() {
    final hasCareerInfo =
        _user!.highestEducation != null ||
        _user!.employedIn != null ||
        _user!.personalIncome != null;

    if (!hasCareerInfo) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.work_outline,
      title: 'CAREER',
      child: Column(
        children: [
          if (_user!.highestEducation != null)
            _buildInfoRow('Education', _user!.highestEducation!),
          if (_user!.employedIn != null)
            _buildInfoRow('Employed In', _user!.employedIn!),
          if (_user!.personalIncome != null)
            _buildInfoRow('Income', _user!.personalIncome!),
        ],
      ),
    );
  }

  Widget _buildFamilySection() {
    final hasFamilyInfo =
        _user!.familyType != null ||
        _user!.familyStatus != null ||
        _user!.fatherStatus != null ||
        _user!.motherStatus != null;

    if (!hasFamilyInfo) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.family_restroom,
      title: 'FAMILY',
      child: Column(
        children: [
          if (_user!.familyType != null)
            _buildInfoRow('Type', _user!.familyType!),
          if (_user!.familyStatus != null)
            _buildInfoRow('Status', _user!.familyStatus!),
          if (_user!.fatherStatus != null)
            _buildInfoRow('Father', _user!.fatherStatus!),
          if (_user!.motherStatus != null)
            _buildInfoRow('Mother', _user!.motherStatus!),
        ],
      ),
    );
  }

  Widget _buildLifestyleSection() {
    final hasLifestyleInfo =
        _user!.eatingHabits != null ||
        _user!.drinkingHabits != null ||
        _user!.smokingHabits != null;

    if (!hasLifestyleInfo) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.favorite_outline,
      title: 'LIFESTYLE',
      child: Column(
        children: [
          if (_user!.eatingHabits != null)
            _buildInfoRow('Diet', _user!.eatingHabits!),
          if (_user!.drinkingHabits != null)
            _buildInfoRow('Drink', _user!.drinkingHabits!),
          if (_user!.smokingHabits != null)
            _buildInfoRow('Smoke', _user!.smokingHabits!),
        ],
      ),
    );
  }

  Widget _buildAttributesSection() {
    final hasAttributesInfo =
        _user!.height != null || _user!.motherTongue != null;

    if (!hasAttributesInfo) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.accessibility_new,
      title: 'ATTRIBUTES',
      child: Column(
        children: [
          if (_user!.height != null) _buildInfoRow('Height', _user!.height!),
          if (_user!.motherTongue != null)
            _buildInfoRow('Mother Tongue', _user!.motherTongue!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final connectionStatus = connectionProvider.getConnectionStatus(
          widget.username,
        );
        final isSendingInterest = connectionProvider.isSendingInterest(
          widget.username,
        );
        final isCancelling = connectionProvider.isCancellingRequest(
          widget.username,
        );

        if (connectionStatus == 'accepted') {
          return Column(
            children: [
              // Connected badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
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
              ),
              const SizedBox(height: 12),
              // Chat button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: {
                        'userId': _user!.id,
                        'username': _user!.username,
                        'firstName': _user!.firstName,
                        'lastName': _user!.lastName,
                        'profilePhoto': _user!.profilePhoto,
                      },
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (connectionStatus == 'pending') {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Interest Sent',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isCancelling
                      ? null
                      : () => connectionProvider.cancelConnectionRequest(
                          widget.username,
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Default: Show Connect button
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isSendingInterest
                ? null
                : () => connectionProvider.sendInterest(widget.username),
            icon: isSendingInterest
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.favorite),
            label: Text(isSendingInterest ? 'Sending...' : 'Connect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}
