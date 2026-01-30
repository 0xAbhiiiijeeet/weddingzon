import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../connections/screens/connections_screen.dart';
import '../providers/feed_provider.dart';
import '../providers/connection_provider.dart';
import '../widgets/profile_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/empty_feed_state.dart';
import '../../shell/providers/badge_provider.dart';
import '../../../shared/widgets/notification_badge.dart';

class FeedScreen extends StatefulWidget {
  final String? viewAsUserId;
  final String? viewAsUserName;

  const FeedScreen({super.key, this.viewAsUserId, this.viewAsUserName});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<FeedProvider>().loadFeed(viewAs: widget.viewAsUserId);
      if (mounted) {
        final users = context.read<FeedProvider>().users;
        context.read<ConnectionProvider>().updateStatusesFromFeed(users);
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() async {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      await context.read<FeedProvider>().loadMore();
      if (mounted) {
        final users = context.read<FeedProvider>().users;
        context.read<ConnectionProvider>().updateStatusesFromFeed(users);
      }
    }
  }

  Future<void> _onRefresh() async {
    await context.read<FeedProvider>().refresh();
    if (mounted) {
      final users = context.read<FeedProvider>().users;
      context.read<ConnectionProvider>().updateStatusesFromFeed(users);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WeddingZon'),
        centerTitle: true,
        elevation: 0,
        actions: widget.viewAsUserId != null
            ? []
            : [
                Consumer<BadgeProvider>(
                  builder: (context, badgeProvider, _) {
                    return IconButton(
                      icon: NotificationBadge(
                        count: badgeProvider.connectionBadgeCount,
                        child: const Icon(Icons.people, size: 22),
                      ),
                      tooltip: 'Connections',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConnectionsScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 22),
                  tooltip: 'Logout',
                  onPressed: _showLogoutDialog,
                ),
              ],
      ),
      body: Column(
        children: [
          if (widget.viewAsUserId != null)
            Container(
              width: double.infinity,
              color: Colors.blue.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.visibility, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Viewing as ${widget.viewAsUserName ?? "Member"}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<FeedProvider>(
              builder: (context, feedProvider, _) {
                return _buildFeedContent(feedProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent(FeedProvider feedProvider) {
    if (feedProvider.isLoading && feedProvider.users.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => const ShimmerCard(),
      );
    }

    if (feedProvider.error != null && feedProvider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              feedProvider.error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => feedProvider.loadFeed(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (feedProvider.isEmpty) {
      return const EmptyFeedState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount:
            feedProvider.users.length + (feedProvider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == feedProvider.users.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final user = feedProvider.users[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ProfileCard(
              user: user,
              readOnly: widget.viewAsUserId != null,
            ),
          );
        },
      ),
    );
  }
}