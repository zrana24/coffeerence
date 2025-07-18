import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_messaging_service.dart'
    show
        getFcmToken,
        setupFirebaseMessagingListeners,
        firebaseMessagingBackgroundHandler;
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgotPassword_screen.dart';
import 'screens/updatePassword_screen.dart';
import 'screens/qr_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint("Firebase başarıyla başlatıldı.");
  }
  catch (e) {
    debugPrint("Firebase başlatılamadı: $e");
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await getFcmToken();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kahve Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          setupFirebaseMessagingListeners(context);
          return const SplashScreen();
        },
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/updatepassword': (context) => const UpdatePasswordScreen(),
        '/qr': (context) => const QrScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
