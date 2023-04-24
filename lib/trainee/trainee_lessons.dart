import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seyaqti_app/actions/lessons/view_lesson.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/widgets/loading.dart';

class TraineeLessons extends StatefulWidget {
  const TraineeLessons({super.key, this.requests});
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
  State<TraineeLessons> createState() => _TraineeLessonsState();
}

class _TraineeLessonsState extends State<TraineeLessons> {
  Future<Widget>? pendingLessons;
  Future<Widget>? finishedLessons;
  List<StreamSubscription> lessonListeners = [];
  Map<String, Map<int, int>> lessonsCount = {};
  Future<bool>? lessonsBuilder;
  Timer? timer;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    timer?.cancel();
    timer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => setState(() {}),
    );
    lessonsBuilder = setListeners(widget.requests);
  }

  @override
  void dispose() {
    super.dispose();
    for (var listener in lessonListeners) {
      listener.cancel();
    }
    timer?.cancel();
  }

  Future<bool> setListeners(QuerySnapshot<Request>? requests) async {
    for (var listener in lessonListeners) {
      await listener.cancel();
    }
    if (requests != null) {
      for (var doc in requests.docs) {
        final id = doc.id;
        StreamSubscription listener = getLessons(id).snapshots().listen(
          (snapshot) async {
            int completed = 0;
            int pending = 0;
            for (var doc in snapshot.docs) {
              final lesson = doc.data();
              final now = DateTime.now();
              final date = DateTime(
                lesson.date!.year,
                lesson.date!.month,
                lesson.date!.day,
                lesson.date!.hour + lesson.duration!,
                lesson.date!.minute,
              );
              if (date.isBefore(now) && !lesson.isComplete!) {
                try {
                  //update lesson
                  final lessonDoc = FirebaseFirestore.instance
                      .collection('requests/$id/lessons')
                      .doc(lesson.id);
                  lesson.isComplete = true;
                  await lessonDoc.set(lesson.toJson());
                  //update trainee hours
                  final userDoc = FirebaseFirestore.instance
                      .collection('users')
                      .doc(lesson.traineeID);
                  final hourDoc = await userDoc
                      .collection('hours')
                      .doc(lesson.traineeID)
                      .get();
                  int hours = lesson.duration!;
                  if (hourDoc.exists) {
                    hours += hourDoc.data()!['hours'] as int;
                  }
                  hours = hours > 22 ? 22 : hours;
                  await hourDoc.reference.set({'hours': hours});
                } on FirebaseException catch (_) {
                  debugPrint(_.message);
                }
              }
              lesson.isComplete! ? completed++ : pending++;
            }
            lessonsCount[id] = {completed: pending};
            completed = 0;
            pending = 0;
            lessonsCount.forEach(
              (key, value) => value.forEach(
                (c, p) {
                  completed += c;
                  pending += p;
                },
              ),
            );
            LessonTracker.lessons.setPending(pending);
            LessonTracker.lessons.setCompleted(completed);
            setState(() {
              pendingLessons = lessons(isPending: true);
              finishedLessons = lessons(isPending: false);
            });
          },
        );
        lessonListeners.add(listener);
      }
    }
    return true;
  }

  Query<Lesson> getLessons(String id) {
    Query query = FirebaseFirestore.instance.collection('requests/$id/lessons');
    query = query.orderBy('date');
    return query.withConverter(
        fromFirestore: (snapshot, _) => Lesson.fromJson(snapshot.data()!),
        toFirestore: (lesson, _) => lesson.toJson());
  }

  viewLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewLesson(
          lesson: lesson,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int completed = 0;
    int pending = 0;
    lessonsCount.forEach(
      (key, value) => value.forEach(
        (c, p) {
          completed += c;
          pending += p;
        },
      ),
    );
    return Scaffold(
      body: FirebaseAuth.instance.currentUser!.isAnonymous
          ? const Center(
              child: Text('You need to register to use this functionality.'))
          : widget.requests == null || widget.getApproved().isEmpty
              ? const Center(
                  child: Text('No active instructor to view lessons.'))
              : FutureBuilder(
                  future: setListeners(widget.requests),
                  builder: (context, snapshot) => snapshot.hasData
                      ? DefaultTabController(
                          length: 2,
                          child: Scaffold(
                            appBar: AppBar(
                              toolbarHeight: 0,
                              bottom: TabBar(
                                onTap: (index) =>
                                    setState(() => currentIndex = index),
                                tabs: [
                                  Tab(text: 'Pending ($pending)'),
                                  Tab(text: 'Finished ($completed)'),
                                ],
                              ),
                            ),
                            body: IndexedStack(
                              index: currentIndex,
                              children: [
                                //pending
                                pendingLessons == null
                                    ? const Center(
                                        child: Text('No pending lessons.'))
                                    : Scaffold(
                                        body: FutureBuilder(
                                          future: pendingLessons,
                                          builder: (context, snapshot) =>
                                              !snapshot.hasData
                                                  ? const Loading(
                                                      color: Colors.white10)
                                                  : snapshot.data!,
                                        ),
                                      ),
                                //finished
                                finishedLessons == null
                                    ? const Center(
                                        child: Text('No finished lessons.'))
                                    : Scaffold(
                                        body: FutureBuilder(
                                          future: finishedLessons,
                                          builder: (context, snapshot) =>
                                              !snapshot.hasData
                                                  ? const Loading(
                                                      color: Colors.white10)
                                                  : snapshot.data!,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        )
                      : const Loading(color: Colors.white10),
                ),
    );
  }

  Future<Widget> lessons({required bool isPending}) async {
    List<Lesson> lessons = [];
    try {
      for (var doc in widget.getApproved()) {
        final id = doc.id;
        final snapshot = isPending
            ? await getLessons(id).where('isComplete', isEqualTo: false).get()
            : await getLessons(id).where('isComplete', isEqualTo: true).get();
        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            lessons.add(doc.data());
          }
        }
      }
    } on FirebaseException catch (_) {
      debugPrint(_.message);
    }
    if (lessons.isEmpty) {
      if (isPending) {
        return const Center(child: Text('No pending lessons.'));
      } else {
        return const Center(child: Text('No finished lessons.'));
      }
    } else {
      isPending
          ? lessons.sort((a, b) => a.date!.compareTo(b.date!))
          : lessons.sort((a, b) => b.date!.compareTo(a.date!));
      return Padding(
        padding: const EdgeInsets.only(top: 0),
        child: ListView.builder(
          itemCount: lessons.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return buildLesson(lessons[index], isPending);
          },
        ),
      );
    }
  }

  Widget buildLesson(Lesson lesson, bool isPending) {
    //get date text
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final fromDate = lesson.date!;
    final aDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final dateText = aDate == today
        ? 'Today'
        : aDate == yesterday
            ? 'Yesterday'
            : aDate == tomorrow
                ? 'Tomorrow'
                : DateFormat.yMEd().format(fromDate);
    //time and duration texts
    final fromTimeText = DateFormat.jm().format(fromDate);
    final toDate = DateTime(fromDate.year, fromDate.month, fromDate.day,
        fromDate.hour + lesson.duration!, fromDate.minute);
    final toTimeText = DateFormat.jm().format(toDate);
    final durationText = lesson.duration! > 1
        ? '${lesson.duration!.toString()} hours'
        : '${lesson.duration!.toString()} hour';

    return Card(
      margin: const EdgeInsets.only(right: 10, left: 10, top: 5, bottom: 5),
      color: Colors.white,
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(lesson.title!)),
            if (lesson.isPickup!)
              Container(
                padding: const EdgeInsets.only(
                  top: 5,
                  bottom: 5,
                  right: 7.5,
                  left: 7.5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Pick Up',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 5),
                StreamBuilder(
                  stream: getUserDoc(lesson.instructorID!).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final instructor = snapshot.data!.data()!;
                      return CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.red,
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(instructor.imageURL!),
                          radius: 13.5,
                        ),
                      );
                    } else {
                      return const Loading();
                    }
                  },
                ),
                const SizedBox(width: 5),
                StreamBuilder(
                  stream: getUserDoc(lesson.traineeID!).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final trainee = snapshot.data!.data()!;
                      return CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.blue,
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(trainee.imageURL!),
                          radius: 13.5,
                        ),
                      );
                    } else {
                      return const Loading();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[700]),
                      children: [
                        const WidgetSpan(
                          child: Icon(Icons.calendar_today, size: 15),
                        ),
                        TextSpan(
                          text: " $dateText",
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[700]),
                      children: [
                        const WidgetSpan(
                          child: Icon(Icons.schedule, size: 15),
                        ),
                        TextSpan(
                          text: " $fromTimeText - $toTimeText",
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[700]),
                      children: [
                        const WidgetSpan(
                          child: Icon(Icons.hourglass_full, size: 15),
                        ),
                        TextSpan(
                          text: " $durationText",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
        onTap: () => viewLesson(lesson),
        contentPadding: const EdgeInsets.all(10),
      ),
    );
  }

  DocumentReference<AppUser> getUserDoc(String id) {
    final doc = FirebaseFirestore.instance.collection('users').doc(id);
    return doc.withConverter(
      fromFirestore: (snapshot, options) => AppUser.fromJson(snapshot.data()!),
      toFirestore: (user, options) => user.toJson(),
    );
  }
}
