import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'shared/widgets/connectivity_wrapper.dart';
import 'core/services/navigation_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/onboarding/repositories/profile_repository.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/feed/repositories/feed_repository.dart';
import 'features/feed/providers/feed_provider.dart';
import 'features/feed/providers/connection_provider.dart';
import 'features/explore/repositories/explore_repository.dart';
import 'features/explore/providers/explore_provider.dart';
import 'features/profile/repositories/user_repository.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/profile/providers/photo_upload_provider.dart';
import 'features/connections/providers/connections_provider.dart';
import 'features/connections/repositories/connections_repository.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/chat/repository/chat_repository.dart';
import 'features/chat/provider/chat_provider.dart';
import 'features/map/repositories/map_repository.dart';
import 'features/map/providers/map_provider.dart';
import 'features/franchise/repositories/franchise_repository.dart';
import 'features/franchise/providers/franchise_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_storage_service.dart';
import 'features/notifications/repositories/notification_repository.dart';
import 'features/shell/providers/badge_provider.dart';

import 'core/services/logging_service.dart';
import 'core/observers/app_navigation_observer.dart';
import 'shared/widgets/interaction_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final storageService = StorageService();
  final notificationStorageService = NotificationStorageService();

  final apiService = ApiService();
  final loggingService = LoggingService();
  loggingService.info('App Started');

  await apiService.init();

  final navigationService = NavigationService();
  final authRepository = AuthRepository(apiService, storageService);
  final onboardingProfileRepository = ProfileRepository(apiService);
  final feedRepository = FeedRepository(apiService);
  final connectionsRepository = ConnectionsRepository(apiService);
  final userRepository = UserRepository(apiService);
  final exploreRepository = ExploreRepository(apiService);
  final chatRepository = ChatRepository(apiService);
  final mapRepository = MapRepository(apiService);
  final franchiseRepository = FranchiseRepository(apiService);
  final socketService = SocketService();
  final deepLinkService = DeepLinkService(navigationService);
  final notificationService = NotificationService(
    navigationService,
    notificationStorageService,
  );
  final notificationRepository = NotificationRepository(apiService);

  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<StorageService>.value(value: storageService),
        Provider<NavigationService>.value(value: navigationService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<DeepLinkService>.value(value: deepLinkService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository,
            navigationService,
            socketService,
            notificationService,
            notificationRepository,
            deepLinkService: deepLinkService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OnboardingProvider(onboardingProfileRepository),
        ),
        ChangeNotifierProvider(create: (_) => FeedProvider(feedRepository)),
        ChangeNotifierProvider(
          create: (_) => ConnectionProvider(connectionsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectionsProvider(connectionsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider(
            notificationStorageService,
            connectionsRepository,
          ),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider(userRepository)),
        ChangeNotifierProvider(
          create: (_) => ExploreProvider(exploreRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => PhotoUploadProvider(userRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ChatProvider(chatRepository, socketService, authRepository),
        ),
        ChangeNotifierProvider(create: (_) => MapProvider(mapRepository)),
        ChangeNotifierProvider(
          create: (_) => FranchiseProvider(franchiseRepository),
        ),
        Provider<SocketService>.value(value: socketService),
        Provider<ProfileRepository>.value(value: onboardingProfileRepository),
        ChangeNotifierProvider(
          create: (context) => BadgeProvider(
            context.read<ChatProvider>(),
            context.read<ConnectionsProvider>(),
            context.read<NotificationsProvider>(),
            socketService,
          ),
        ),
      ],
      child: const WeddingZonApp(),
    ),
  );
}

class WeddingZonApp extends StatelessWidget {
  const WeddingZonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InteractionLogger(
      child: ConnectivityWrapper(
        child: MaterialApp(
          title: 'WeddingZon',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          navigatorObservers: [AppNavigationObserver()],
          navigatorKey: Provider.of<NavigationService>(
            context,
            listen: false,
          ).navigatorKey,
          initialRoute: AppRoutes.franchiseDashboard,
          routes: AppRoutes.routes,
        ),
      ),
    );
  }
}