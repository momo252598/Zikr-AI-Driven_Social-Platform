import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // import ScreenUtil
import 'package:software_graduation_project/screens/Signup/signup.dart';
import 'package:software_graduation_project/screens/signin/signin.dart';
import 'package:software_graduation_project/components/signup/sign_up_form.dart';
import 'package:software_graduation_project/skeleton.dart';
import 'package:software_graduation_project/screens/prayers/prayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:software_graduation_project/services/auth_service.dart';
// Import the safe animation controller
import 'package:software_graduation_project/utils/safe_animation_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize auth service and check for existing session
  final authService = AuthService();
  final isLoggedIn = await authService.initializeAuth();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true, // this sets _minTextAdapt
      builder: (context, child) {
        return Provider(
          create: (_) => AuthService(),
          child: MaterialApp(
            title: 'Zikr',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              // Use safe page transitions to prevent animation crashes
              pageTransitionsTheme: PageTransitionsTheme(
                builders: {
                  // Use a custom page transition that uses the safe animation controller
                  TargetPlatform.android: SafePageTransitionsBuilder(),
                  TargetPlatform.iOS: SafePageTransitionsBuilder(),
                  TargetPlatform.linux: SafePageTransitionsBuilder(),
                  TargetPlatform.macOS: SafePageTransitionsBuilder(),
                  TargetPlatform.windows: SafePageTransitionsBuilder(),
                },
              ),
            ),
            // Start with either home screen or login screen based on auth status
            initialRoute: isLoggedIn ? '/skeleton' : '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/skeleton': (context) =>
                  Skeleton(key: Skeleton.navigatorKey), // Move key here
              '/signup': (context) => const SignUpScreen(),
              // Other routes...
            },
          ),
        );
      },
    );
  }
}

/// A custom page transitions builder that uses SafeAnimationController
class SafePageTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use a FadeTransition which uses the safe animation controller internally
    return FadeTransition(opacity: animation, child: child);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
