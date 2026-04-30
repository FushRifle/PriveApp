class ApiConfig {
  // Clerk
  static const String clerkPublishableKey = 'pk_test_your-clerk-key';

  // Supabase
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-supabase-anon-key';
  static const String supabaseRestUrl = '$supabaseUrl/rest/v1';

  // Cloudinary
  static const String cloudinaryCloudName = 'your-cloud-name';
  static const String cloudinaryApiKey = 'your-api-key';
  static const String cloudinaryApiSecret = 'your-api-secret';
  static const String cloudinaryUploadPreset = 'your-upload-preset';

  // Endpoints
  static const String usersEndpoint = '/users';
  static const String postsEndpoint = '/posts';
  static const String commentsEndpoint = '/comments';
  static const String likesEndpoint = '/likes';
  static const String followsEndpoint = '/follows';
  static const String notificationsEndpoint = '/notifications';
  static const String messagesEndpoint = '/messages';
  static const String conversationsEndpoint = '/conversations';
}
