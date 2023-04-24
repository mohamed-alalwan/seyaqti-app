import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/widgets/loading.dart';

class AddLesson extends StatefulWidget {
  const AddLesson({super.key, this.traineeID, this.requests});
  final String? traineeID;
  final QuerySnapshot<Request>? requests;

  List<QueryDocumentSnapshot<Request>> getApproved() {
    List<QueryDocumentSnapshot<Request>> approved = [];
    if (requests != null) {
      approved = requests!.docs.toList();
      approved.removeWhere((doc) => doc.data().approval == null);
    }
    return approved;
  }

  @override
  State<AddLesson> createState() => _AddLessonState();
}

class _AddLessonState extends State<AddLesson> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final durationController = TextEditingController();

  DateTime now = DateTime.now();
  List<DropdownMenuItem<String>> trainees = [];
  bool isLoading = true;
  bool isAddingLesson = false;
  bool isPickup = false;

  DateTime? selectedDate;
  String? selectedTrainee;

  @override
  void initState() {
    super.initState();
    declareTrainees();
    selectedTrainee = widget.traineeID;
  }

  Future declareTrainees() async {
    if (widget.requests != null || widget.getApproved().isNotEmpty) {
      for (var doc in widget.getApproved()) {
        try {
          final traineeID = doc.data().senderID!;
          final snapshot = await getUserDoc(traineeID).get();
          if (snapshot.exists) {
            final user = snapshot.data()!;
            DropdownMenuItem<String> trainee = DropdownMenuItem(
              value: user.id!,
              child: Text(user.fullName()!),
            );
            trainees.add(trainee);
          }
        } on FirebaseException catch (_) {
          debugPrint(_.message);
          Utils.ShowErrorBar('Something went wrong...');
          if (!mounted) return;
          Navigator.pop(context);
        }
      }
      setState(() => isLoading = false);
    } else {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  DocumentReference<AppUser> getUserDoc(String id) {
    final doc = FirebaseFirestore.instance.collection('users').doc(id);
    return doc.withConverter(
      fromFirestore: (snapshot, options) => AppUser.fromJson(snapshot.data()!),
      toFirestore: (user, options) => user.toJson(),
    );
  }

  Future addNewLesson() async {
    try {
      FocusScope.of(context).unfocus();
      setState(() => isAddingLesson = true);
      //prepare submitted data
      final title = titleController.text.trim();
      final duration = int.parse(durationController.text.trim());
      final instructorID = AppUser.currentUser!.id!;
      final id = (instructorID + selectedDate!.toString()).hashCode.toString();
      //get request id
      String requestID = widget
          .getApproved()
          .firstWhere((doc) => doc.data().senderID == selectedTrainee)
          .id;
      //set lesson
      final lesson = Lesson(
        id: id,
        requestID: requestID,
        title: title,
        date: selectedDate,
        duration: duration,
        instructorID: instructorID,
        traineeID: selectedTrainee,
        isComplete: false,
        isPickup: isPickup,
      );
      final collection =
          FirebaseFirestore.instance.collection('requests/$requestID/lessons');
      await collection.doc(id).set(lesson.toJson());
      Utils.ShowSuccessBar('Lesson successfully added.');
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (_) {
      Utils.ShowErrorBar('Something went wrong...');
      debugPrint(_.message);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onTapDown: (_) => FocusScope.of(context).unfocus(),
      child: isAddingLesson
          ? const Scaffold(body: Loading(color: Colors.white10))
          : Scaffold(
              appBar:
                  AppBar(title: const Text('Add Lesson'), centerTitle: true),
              body: isLoading
                  ? const Loading(color: Colors.white10)
                  : Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            TextFormField(
                              textCapitalization: TextCapitalization.sentences,
                              autocorrect: true,
                              enableSuggestions: true,
                              controller: titleController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.title),
                                labelText: 'Title',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Title cannot be empty.';
                                } else if (value.length > 60) {
                                  return 'Title is too long.';
                                } else {
                                  return null;
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField(
                              value: selectedTrainee,
                              items: trainees,
                              onChanged: (trainee) => setState(() {
                                selectedTrainee = trainee;
                              }),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.perm_identity),
                                labelText: 'Trainee',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Trainee is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              readOnly: true,
                              controller: dateController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.calendar_today),
                                labelText: 'Date',
                              ),
                              onTap: () async {
                                DateTime? pickDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(
                                      now.year, now.month, now.day + 1),
                                  firstDate: now,
                                  lastDate: DateTime(
                                      now.year + 1, now.month, now.day),
                                );
                                if (pickDate != null) {
                                  dateController.text =
                                      DateFormat.yMEd().format(pickDate);
                                  selectedDate = pickDate;
                                  timeController.clear();
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'This field is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              readOnly: true,
                              controller: timeController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.schedule),
                                labelText: 'Time',
                              ),
                              enabled: selectedDate == null ? false : null,
                              onTap: () async {
                                TimeOfDay? pickTime = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      const TimeOfDay(hour: 7, minute: 0),
                                );
                                if (pickTime != null && selectedDate != null) {
                                  selectedDate = DateTime(
                                      selectedDate!.year,
                                      selectedDate!.month,
                                      selectedDate!.day,
                                      pickTime.hour,
                                      pickTime.minute);

                                  timeController.text =
                                      DateFormat.jm().format(selectedDate!);
                                }
                              },
                              validator: (value) {
                                if (selectedDate == null) {
                                  return 'A date is required.';
                                } else if (value == null || value.isEmpty) {
                                  return 'This field is required.';
                                } else if (selectedDate!.compareTo(now) < 0) {
                                  return 'Time can\'t be in the past.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              enabled: timeController.text.isNotEmpty,
                              controller: durationController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.hourglass_full),
                                labelText: 'Duration (1-3 Hours)',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'This field is required.';
                                }
                                try {
                                  int x = int.parse(value);
                                  if (x <= 0) {
                                    return 'Duration must be more than 0 hours.';
                                  } else if (x > 3) {
                                    return 'Duration must not exceed 3 hours.';
                                  }
                                } catch (_) {
                                  return 'This field is must be in digit numbers.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text('Pick Up'),
                              value: isPickup,
                              onChanged: (value) {
                                setState(() => isPickup = value!);
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
                                final isValid =
                                    formKey.currentState!.validate();
                                if (isValid) {
                                  debugPrint('Valid Submit');
                                  addNewLesson();
                                }
                              },
                              child: const Text('ADD LESSON'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
    );
  }
}
