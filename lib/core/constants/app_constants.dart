class AppConstants {
  static const String baseUrl =
      'https://weddingzon-backend.onrender.com/api'; // Android Emulator localhost

  // Auth Constants
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // Endpoints
  static const String authGoogle = '/auth/google';
  static const String authSendOtp = '/auth/send-otp';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authMe = '/auth/me';
  static const String refreshToken = '/auth/refresh';
  static const String authRegisterDetails = '/auth/register-details';
  static const String authLogout = '/auth/logout';
  static const String usersUploadPhotos = '/users/upload-photos';
  static const String usersPhotos = '/users/photos';
  static const String usersFeed = '/users/feed';
  static const String usersSearch = '/users/search';
  static const String usersProfile = '/users'; // GET /users/:username
  static const String users = '/users'; // Base users endpoint

  // Connections
  static const String connectionsSend = '/connections/send';
  static const String connectionsAccept = '/connections/accept';
  static const String connectionsReject = '/connections/reject';

  static const String connectionsCancel = '/connections/cancel';

  static const String connectionsRequestPhotoAccess =
      '/connections/request-photo-access';
  static const String connectionsRequestDetailsAccess =
      '/connections/request-details-access';

  static const String connectionsRespondPhoto = '/connections/respond-photo';
  static const String connectionsRespondDetails =
      '/connections/respond-details';

  static const String connectionsRequests = '/connections/requests';
  static const String connectionsMyConnections = '/connections/my-connections';
  static const String connectionsNotifications = '/connections/notifications';

  static const String connectionsStatus = '/connections/status';

  // Chat
  static const String chatConversations = '/chat/conversations';
  static const String chatHistory = '/chat/history';
  static const String chatUpload = '/chat/upload';
  static const String chatMarkRead = '/chat/read';

  // Socket.IO
  static const String socketUrl = 'https://weddingzon-backend.onrender.com';

  // Admin
  static const String adminUsers = '/admin/users';
  static const String adminStats = '/admin/stats';
}
