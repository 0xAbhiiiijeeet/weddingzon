import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../widgets/profile_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/empty_feed_state.dart';

class ViewAsFeedScreen extends StatefulWidget {
  final String viewAsUserId;

  const ViewAsFeedScreen({super.key, required this.viewAsUserId});

  @override
  State<ViewAsFeedScreen> createState() => _ViewAsFeedScreenState();
}

class _ViewAsFeedScreenState extends State<ViewAsFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadFeed(viewAs: widget.viewAsUserId);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View As Mode'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.orange.shade100,
            child: const Text(
              'Read-Only Mode: Interactions are disabled.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.deepOrange),
            ),
          ),
          Expanded(
            child: Consumer<FeedProvider>(
              builder: (context, feedProvider, _) {
                if (feedProvider.isLoading && feedProvider.users.isEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) => const ShimmerCard(),
                  );
                }

                if (feedProvider.error != null && feedProvider.users.isEmpty) {
                  return Center(child: Text(feedProvider.error!));
                }

                if (feedProvider.isEmpty) {
                  return const EmptyFeedState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount:
                      feedProvider.users.length +
                      (feedProvider.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == feedProvider.users.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final user = feedProvider.users[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ProfileCard(user: user, readOnly: true),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}