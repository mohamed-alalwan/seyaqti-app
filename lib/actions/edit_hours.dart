import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/classes/utils.dart';
import 'package:seyaqti_app/widgets/loading.dart';

class EditHours extends StatefulWidget {
  const EditHours({super.key, required this.traineeID});
  final String traineeID;
  @override
  State<EditHours> createState() => _EditHoursState();
}

class _EditHoursState extends State<EditHours> {
  final formKey = GlobalKey<FormState>();
  final hoursController = TextEditingController();

  int previousHours = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getPreviousHours();
  }

  Future getPreviousHours() async {
    try {
      final snapshot = await getHoursDoc().get();
      if (snapshot.exists) {
        final hours = snapshot.data()!['hours'] as int;
        previousHours = hours;
        hoursController.text = previousHours.toString();
      }
      setState(() {
        isLoading = false;
      });
    } on FirebaseException catch (_) {
      debugPrint(_.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onTapDown: (_) => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Update Hours'), centerTitle: true),
        body: isLoading
            ? const Loading(color: Colors.white10)
            : Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: hoursController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.schedule),
                          labelText: 'Training Hours',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required.';
                          }
                          try {
                            int x = int.parse(value);
                            if (x < 0) {
                              return 'Hours must be more than 0.';
                            } else if (x > 22) {
                              return 'Hours must not exceed 22.';
                            }
                          } catch (_) {
                            return 'This field is must be in digit numbers.';
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
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          final isValid = formKey.currentState!.validate();
                          if (isValid) {
                            debugPrint('Valid Submit');
                            editHours();
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future editHours() async {
    try {
      setState(() {
        isLoading = true;
      });
      int editedHours = int.parse(hoursController.text.trim());
      previousHours != editedHours
          ? await getHoursDoc().set({'hours': editedHours})
          : null;
      Utils.ShowSuccessBar('Trainee\'s hours have been updated successfully.');
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (_) {
      debugPrint(_.message);
      Utils.ShowErrorBar('Something went wrong...');
      Navigator.pop(context);
    }
  }

  DocumentReference<Map<String, dynamic>> getHoursDoc() {
    final userID = widget.traineeID;
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .collection('hours')
        .doc(userID);
    return doc;
  }
}
