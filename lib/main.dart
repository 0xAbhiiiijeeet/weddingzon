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
import 'features/connections/repositories/connections_repository.dart';
import 'features/connections/providers/connections_provider.dart';
import 'features/profile/repositories/user_repository.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/explore/repositories/explore_repository.dart';
import 'features/explore/providers/explore_provider.dart';
import 'features/chat/repository/chat_repository.dart';
import 'features/chat/provider/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  final apiService = ApiService();

  // Initialize API service with persistent cookie storage
  await apiService.init();

  final navigationService = NavigationService();
  final authRepository = AuthRepository(apiService, storageService);
  final onboardingProfileRepository = ProfileRepository(apiService);
  final feedRepository = FeedRepository(apiService);
  final connectionsRepository = ConnectionsRepository(apiService);
  final userRepository = UserRepository(apiService);
  final exploreRepository = ExploreRepository(apiService);
  final chatRepository = ChatRepository(apiService);
  final socketService = SocketService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<StorageService>.value(value: storageService),
        Provider<NavigationService>.value(value: navigationService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository, navigationService),
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
        ChangeNotifierProvider(create: (_) => ProfileProvider(userRepository)),
        ChangeNotifierProvider(
          create: (_) => ExploreProvider(exploreRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(chatRepository, socketService),
        ),
        Provider<SocketService>.value(value: socketService),
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
        initialRoute: AppRoutes.landing,
        routes: AppRoutes.routes,
      ),
    );
  }
}
