import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/classes/utils.dart';
import 'package:seyaqti_app/widgets/loading.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();
  bool isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onTapDown: (_) => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
          centerTitle: true,
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
                  controller: passwordController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: newPasswordController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != null && value.length < 8) {
                      return 'Enter atleast 8 characters.';
                    } else if (value == passwordController.text) {
                      return 'Cannot be the same as the old password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: confirmNewPasswordController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (newPasswordController.text !=
                        confirmNewPasswordController.text) {
                      return "Passwords don't match.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: isUpdating
                      ? null
                      : () => formKey.currentState!.validate()
                          ? changePassword()
                          : null,
                  child: const Text(
                    'CHANGE PASSWORD',
                  ),
                ),
                isUpdating
                    ? Column(
                        children: const [
                          SizedBox(height: 20),
                          Loading(color: Colors.white10),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future changePassword() async {
    setState(() {
      isUpdating = true;
    });
    String currentPassword = passwordController.text;
    String newPassword = newPasswordController.text;
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      Utils.ShowSuccessBar("Password updated successfully.");
    } on FirebaseAuthException catch (e) {
      Utils.ShowErrorBar("Error: ${e.message}");
    }
    setState(() {
      isUpdating = false;
    });
  }
}
