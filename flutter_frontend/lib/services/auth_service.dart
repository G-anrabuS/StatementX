import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static GoogleSignIn? _instance;

  static void _ensureInitialized() {
    if (_instance == null) {
      // Small safety check for Web/Hot Reload
      if (!dotenv.isInitialized) {
        print('Warning: DotEnv not initialized yet. Skipping GoogleSignIn init.');
        return;
      }
      final String? clientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      print('Initializing GoogleSignIn with Client ID: ${clientId?.substring(0, 10)}...');
      
      _instance = GoogleSignIn(
        clientId: clientId,
        // serverClientId must be null on Web, but is needed for Android to get an idToken
        serverClientId: kIsWeb ? null : clientId,
        scopes: ['email', 'profile'],
      );
    }
  }

  static GoogleSignIn get _googleSignIn {
    _ensureInitialized();
    return _instance!;
  }

  /// Stream to listen for user changes (needed for Web GIS button)
  static Stream<GoogleSignInAccount?> get onUserChanged => _googleSignIn.onCurrentUserChanged;

  static String get authBaseUrl {
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return 'http://10.149.147.205:8000/api/auth';
    }
    return 'http://127.0.0.1:8000/api/auth';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Syncs a Google User with our backend (exchanges ID Token for JWT)
  static Future<Map<String, dynamic>?> syncWithBackend(GoogleSignInAccount googleUser) async {
    try {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      print('Syncing with Backend: idToken ${idToken != null ? "RECEIVED" : "MISSING"}');

      if (idToken == null) {
        print('Error: No ID Token. Ensure you are using the GIS button on Web.');
        return null;
      }

      final response = await http.post(
        Uri.parse('$authBaseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['access_token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_data', jsonEncode(data['user']));

        print('Successfully synced with backend as ${data['user']['email']}');
        return data['user'];
      } else {
        print('Backend sync failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Sync Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Try silent sign-in first
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // On Web, if silent fails, we DO NOT call signIn() manually (discouraged).
      // On Mobile, we do.
      if (googleUser == null && !kIsWeb) {
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) return null;

      return await syncWithBackend(googleUser);
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Sign out warning: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }
}
