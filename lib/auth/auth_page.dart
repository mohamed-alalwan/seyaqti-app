import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seyaqti_app/classes/utils.dart';
import 'package:seyaqti_app/auth/login_widget.dart';
import 'package:seyaqti_app/auth/register_widget.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/seyaqti_app_icons.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : SafeArea(
            child: Scaffold(
              backgroundColor: Colors.red,
              body: SingleChildScrollView(
                reverse: true,
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.bottomCenter,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(300),
                          bottomLeft: Radius.circular(300),
                        ),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            SeyaqtiApp.seyaqti_logo,
                            size: 125,
                            color: Colors.red,
                          ),
                          Text(
                            'Seyaqti',
                            style: GoogleFonts.raleway(
                              textStyle: const TextStyle(
                                fontSize: 40,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const SizedBox(height: 25),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginWidget(),
                                  ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterWidget(),
                                  ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: guestLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(
                                  width: 3.0, color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Continue as Guest',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Future requestPermissions() async {
    await Geolocator.requestPermission();
  }

  Future guestLogin() async {
    try {
      setState(() => loading = true);
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      Utils.ShowErrorBar("Error: ${e.code}");
    }
  }
}
