import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/trainee/trainee_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seyaqti_app/auth/auth_page.dart';
import 'package:seyaqti_app/auth/verify_email_page.dart';
import 'package:seyaqti_app/firebase_options.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:timezone/data/latest.dart' as tz;

Future main() async {
  tz.initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationsApi.init();
  await UserPreferences.init();
  //await UserPreferences.instance.clear();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: Utils.messengerKey,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Seyaqti App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isAnonymous) {
              return const TraineePage();
            } else {
              return const VerifyEmailPage();
            }
          } else {
            return const AuthPage();
          }
        },
      ),
    );
  }
}
