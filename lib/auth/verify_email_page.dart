import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/instructor/instructor_page.dart';
import 'package:seyaqti_app/trainee/trainee_page.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/shared_import.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    if (!isEmailVerified) {
      sendVerificationEmail();
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) {
      return FutureBuilder(
        future: setCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.type == 'Trainee') {
              return const TraineePage();
            } else {
              return const InstructorPage();
            }
          } else {
            return const Loading();
          }
        },
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verify Email'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          reverse: true,
          child: Column(
            children: [
              Text(
                'You need to verify your email.\n\nA verification email has been sent to your email (${FirebaseAuth.instance.currentUser!.email}).',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size.fromHeight(40),
                ),
                onPressed: canResendEmail ? sendVerificationEmail : null,
                child: const Text(
                  'RESEND EMAIL',
                ),
              ),
              if (!canResendEmail)
                Column(
                  children: const [
                    SizedBox(height: 20),
                    Loading(
                      color: Colors.white10,
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }
  }

  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    if (mounted) {
      setState(
        () =>
            isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified,
      );
    }
  }

  Future<AppUser?> setCurrentUser() async {
    try {
      final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
      bool tokenRefreshed = token.claims!['email_verified'];
      if (!tokenRefreshed) {
        await FirebaseAuth.instance.currentUser!.getIdToken(true);
      }
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);
      final snapshot = await userDoc.get();
      if (snapshot.exists) {
        AppUser.currentUser = AppUser.fromJson(snapshot.data()!);
        //Notification Listener Intitialization
        await NotificationsListeners.setListeners();
        //reset lessons tracker
        LessonTracker.lessons.resetValues();
      } else {
        Utils.ShowErrorBar('Something Went Wrong...');
        FirebaseAuth.instance.signOut();
      }
    } on FirebaseException catch (_) {
      debugPrint(_.message);
    }
    return AppUser.currentUser;
  }

  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      if (mounted) {
        setState(() => canResendEmail = false);
      }
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) {
        setState(() => canResendEmail = true);
      }
    } on FirebaseAuthException catch (e) {
      Utils.ShowErrorBar("Error: ${e.code}");
    }
  }
}
