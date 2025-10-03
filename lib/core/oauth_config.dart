class OAuthConfig {
  // OAuth configuration
  static const bool isTestMode = false; // Set to false for production

  // Google OAuth Configuration
  static const String googleClientId = '1043973319607-6n9drnalqlnk4bs3nt0d0qgh3ocsqov1.apps.googleusercontent.com';
  static const List<String> googleScopes = ['email', 'profile'];

  // Apple OAuth Configuration
  static const String appleClientId = 'com.example.manna_donate_app';
  static const String appleTeamId = 'your-apple-team-id-here';
  static const String appleKeyId = 'your-apple-key-id-here';
  static const String applePrivateKey = 'your-apple-private-key-here';

  // Redirect URIs
  static const String googleRedirectUri = 'com.example.manna_donate_app:/oauth2redirect';
  static const String appleRedirectUri = 'com.example.manna_donate_app:/oauth2redirect';

  // Production OAuth Configuration
  static const String productionGoogleClientId = '1043973319607-6n9drnalqlnk4bs3nt0d0qgh3ocsqov1.apps.googleusercontent.com';
  static const String productionAppleClientId = 'com.example.manna_donate_app';

  // Get the appropriate client ID based on environment
  static String getGoogleClientId() {
    return isTestMode ? googleClientId : productionGoogleClientId;
  }
  
  static String getAppleClientId() {
    return isTestMode ? appleClientId : productionAppleClientId;
  }
} 