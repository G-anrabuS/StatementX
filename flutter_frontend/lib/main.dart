import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final bool loggedIn = await AuthService.isLoggedIn();
  runApp(StatementXApp(initialRoute: loggedIn ? const HomeScreen() : const LoginScreen()));
}

class StatementXApp extends StatefulWidget {
  final Widget initialRoute;
  const StatementXApp({super.key, required this.initialRoute});

  @override
  State<StatementXApp> createState() => _StatementXAppState();
}

class _StatementXAppState extends State<StatementXApp> {
  late Widget _currentRoute;

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;
    
    // Listen for Google Auth changes (for Web GIS button support)
    AuthService.onUserChanged.listen((user) async {
      if (user != null) {
        final userData = await AuthService.syncWithBackend(user);
        if (userData != null && mounted) {
          setState(() {
            _currentRoute = const HomeScreen();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StatementX',
      home: _currentRoute,
    );
  }
}
