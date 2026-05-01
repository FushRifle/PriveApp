class ApiConfig {
  // Base URL
  static const String baseUrl = 'https://prive-backend.onrender.com/api';

  // API prefix (your endpoints already include /api in the path, so baseUrl is clean)
  static const String apiPrefix = '/api';

  // Clerk
  static const String clerkPublishableKey =
      'pk_test_ZXF1aXBwZWQtY3Jhd2RhZC05NC5jbGVyay5hY2NvdW50cy5kZXYk';
  static const String clerkSecretKey =
      'sk_test_COYzxTLdu3o78vqD2bt2CrQeGHhNawMCCaXqYkNHLH';

  // Supabase
  static const String supabaseUrl = 'https://fswzotrcqplrrmnsyhtg.supabase.co';
  static const String supabaseAnonKey = 'your-supabase-anon-key';
  static const String supabaseRestUrl = '$supabaseUrl/rest/v1';

  // Cloudinary
  static const String cloudinaryCloudName = 'dug6225go';
  static const String cloudinaryApiKey = '434425869392128';
  static const String cloudinaryApiSecret = 'vhNG8KA2wJJfbSaqfza8xCGPupk';
  static const String cloudinaryUploadPreset = 'prive-app';

  // Web-specific: Use a CORS proxy during development
  static String get effectiveBaseUrl {
    // For web development, you can use a CORS proxy
    // Uncomment if you have CORS issues on web:
    // return 'https://cors-anywhere.herokuapp.com/$baseUrl';
    return baseUrl;
  }

  // Endpoints
  static const String usersEndpoint = '/users';
  static const String profilesEndpoint = '/profiles';
  static const String postsEndpoint = '/posts';
  static const String feedEndpoint = '/feed';
  static const String reelsEndpoint = '/reels';
  static const String chatEndpoint = '/chat';
  static const String friendsEndpoint = '/friends';
  static const String exploreEndpoint = '/explore';
  static const String matchesEndpoint = '/matches';
  static const String insightsEndpoint = '/insights';
  static const String notificationsEndpoint = '/notifications';
  static const String subscriptionEndpoint = '/subscription';
  static const String healthEndpoint = '/health';
}
