import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/trainee/trainee_dashboard.dart';
import 'package:seyaqti_app/trainee/trainee_instructor.dart';
import 'package:seyaqti_app/trainee/trainee_instructor_search.dart';
import 'package:seyaqti_app/trainee/trainee_lessons.dart';
import 'package:seyaqti_app/widgets/custom_app_bar.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/nav_bar.dart';
import 'package:seyaqti_app/widgets/seyaqti_app_icons.dart';
import 'package:seyaqti_app/shared_import.dart';

class TraineePage extends StatefulWidget {
  const TraineePage({super.key});

  @override
  State<TraineePage> createState() => _TraineePageState();
}

class _TraineePageState extends State<TraineePage> {
  int currentIndex = 0;
  List<Widget> screens({QuerySnapshot<Request>? requests}) => [
        TraineeDashboard(requests: requests),
        TraineeInstructor(requests: requests),
        TraineeLessons(requests: requests),
        const TraineeInstructorSearch(),
      ];

  @override
  void dispose() async {
    super.dispose();
    await NotificationsListeners.cancelListeners();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final FocusScopeNode currentScope = FocusScope.of(context);
        if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
          FocusManager.instance.primaryFocus!.unfocus();
        }
      },
      onPanDown: (_) {
        final FocusScopeNode currentScope = FocusScope.of(context);
        if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
          FocusManager.instance.primaryFocus!.unfocus();
        }
      },
      child: Scaffold(
        drawer: const NavBar(),
        appBar: const CustomAppBar(
          title: Icon(SeyaqtiApp.seyaqti_logo),
        ),
        body: FirebaseAuth.instance.currentUser!.isAnonymous
            ? IndexedStack(
                index: currentIndex,
                children: screens(),
              )
            : StreamBuilder(
                stream: getRequestQuery().snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Loading(color: Colors.white10);
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong...'));
                  } else {
                    final requests = snapshot.data;
                    return IndexedStack(
                      index: currentIndex,
                      children: screens(requests: requests),
                    );
                  }
                },
              ),
        floatingActionButton: null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) async {
            if (index == 2) {
              await UserPreferences.instance.setBool('onLessonView', true);
              List<String> lessonNotifications = UserPreferences.instance
                      .getStringList(NotificationsChangesHandler.lessonsNotifier
                          .getKey()) ??
                  [];
              if (lessonNotifications.isNotEmpty) {
                lessonNotifications.clear();
                //update listeners
                await NotificationsChangesHandler.lessonsNotifier
                    .updateValue(lessonNotifications);
              }
            } else {
              await UserPreferences.instance.setBool('onLessonView', false);
            }
            setState(() {
              currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(
                Icons.dashboard,
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: ValueListenableBuilder(
                valueListenable: NotificationsChangesHandler.chatsNotifier,
                builder: (context, value, child) {
                  int total = 0;
                  if (value is List) {
                    total = value.length;
                  }
                  return total == 0
                      ? const Icon(Icons.supervisor_account)
                      : Badge(
                          badgeContent: Text(
                            total.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                          child: const Icon(Icons.supervisor_account),
                        );
                },
              ),
              label: 'Instructor',
            ),
            BottomNavigationBarItem(
              icon: ValueListenableBuilder(
                valueListenable: NotificationsChangesHandler.lessonsNotifier,
                builder: (context, value, child) {
                  int total = 0;
                  if (value is List) {
                    total = value.length;
                  }
                  return total == 0
                      ? const Icon(Icons.calendar_month)
                      : Badge(
                          badgeContent: Text(
                            total.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                          child: const Icon(Icons.calendar_month),
                        );
                },
              ),
              label: 'Lessons',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
          ],
        ),
      ),
    );
  }

  Query<Request> getRequestQuery() {
    Query query = FirebaseFirestore.instance
        .collection('requests')
        .where('senderID', isEqualTo: AppUser.currentUser!.id)
        .limit(1);
    return query.withConverter(
        fromFirestore: (snapshot, _) => Request.fromJson(snapshot.data()!),
        toFirestore: (request, _) => request.toJsonReceiver());
  }
}
