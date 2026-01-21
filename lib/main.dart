import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'shared/widgets/connectivity_wrapper.dart';
import 'core/services/navigation_service.dart';
import 'core/services/socket_service.dart';
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
import 'features/connections/providers/connections_provider.dart';
import 'features/connections/repositories/connections_repository.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/chat/repository/chat_repository.dart';
import 'features/chat/provider/chat_provider.dart';
import 'features/map/repositories/map_repository.dart';
import 'features/map/providers/map_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_storage_service.dart';
import 'features/notifications/repositories/notification_repository.dart';
import 'features/shell/providers/badge_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final storageService = StorageService();
  final notificationStorageService = NotificationStorageService();
  final apiService = ApiService();

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
  final socketService = SocketService();
  final notificationService = NotificationService(
    navigationService,
    notificationStorageService,
  );
  final notificationRepository = NotificationRepository(apiService);

  // Note: Firebase.initializeApp() is called at the start of main
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<StorageService>.value(value: storageService),
        Provider<NavigationService>.value(value: navigationService),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository,
            navigationService,
            socketService,
            notificationService,
            notificationRepository,
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
          create: (_) =>
              ChatProvider(chatRepository, socketService, authRepository),
        ),
        ChangeNotifierProvider(create: (_) => MapProvider(mapRepository)),
        Provider<SocketService>.value(value: socketService),
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
    return ConnectivityWrapper(
      child: MaterialApp(
        title: 'WeddingZon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        navigatorKey: Provider.of<NavigationService>(
          context,
          listen: false,
        ).navigatorKey,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
