import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:isi_event/features/app/splash_screen/splash_screen.dart';
import 'package:isi_event/features/notifications/firebase_api.dart';
import 'package:isi_event/features/user_auth/presentation/pages/login_page.dart';
import 'package:provider/provider.dart';
import 'features/user_auth/presentation/pages/home_page.dart';
import 'features/user_auth/presentation/pages/signup_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<String>.value(
      value: 'USER',
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Firebase',
        routes: {
          '/': (context) => SplashScreen(child: LoginPage()),
          '/login': (context) => LoginPage(),
          '/signUp': (context) => SignUpPage(),
          '/home': (context) => HomePage(),
        },
      ),
    );
  }
}







