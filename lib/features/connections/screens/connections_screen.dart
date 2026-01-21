import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connections_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import 'invites_tab.dart';
import 'notifications_tab.dart';

class ConnectionsScreen extends StatefulWidget {
  final int initialIndex;

  const ConnectionsScreen({super.key, this.initialIndex = 0});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionsProvider>().loadIncomingRequests();
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE91E63), // Pink
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE91E63),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Consumer<ConnectionsProvider>(
              builder: (context, provider, _) {
                final count = provider.incomingRequests.length;
                return Tab(text: 'Invites ($count)');
              },
            ),
            Consumer<NotificationsProvider>(
              builder: (context, provider, _) {
                final count = provider.notifications.length;
                return Tab(text: 'Notifications ($count)');
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [InvitesTab(), NotificationsTab()],
      ),
    );
  }
}
