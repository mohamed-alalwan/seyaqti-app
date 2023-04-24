import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/classes/utils.dart';
import 'package:seyaqti_app/auth/register_widget.dart';
import 'package:seyaqti_app/auth/reset_password_page.dart';
import 'package:seyaqti_app/main.dart';
import 'package:seyaqti_app/widgets/loading.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Log In'),
                centerTitle: true,
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterWidget(),
                          ));
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.person, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Register', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  )
                ],
              ),
              body: Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  reverse: true,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email',
                        ),
                        validator: (value) {
                          if (value != null &&
                              !EmailValidator.validate(value)) {
                            return 'Enter a valid email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != null && value.length < 8) {
                            return 'Enter atleast 8 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResetPasswordPage(),
                            ),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text(
                          'LOGIN',
                        ),
                        onPressed: () {
                          final isValidForm = formKey.currentState!.validate();
                          if (isValidForm) {
                            login();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Future login() async {
    try {
      setState(() => loading = true);
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      navigatorKey.currentState!.popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() {
        Utils.ShowErrorBar("Error: ${e.message}");
        loading = false;
      });
    }
  }
}
