import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/instructor/instructor_dashboard.dart';
import 'package:seyaqti_app/instructor/instructor_lessons.dart';
import 'package:seyaqti_app/instructor/instructor_requests.dart';
import 'package:seyaqti_app/instructor/instructor_traineees.dart';
import 'package:seyaqti_app/widgets/custom_app_bar.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/nav_bar.dart';
import 'package:seyaqti_app/widgets/seyaqti_app_icons.dart';
import 'package:badges/badges.dart';
import 'package:seyaqti_app/shared_import.dart';

class InstructorPage extends StatefulWidget {
  const InstructorPage({super.key});

  @override
  State<InstructorPage> createState() => _InstructorPageState();
}

class _InstructorPageState extends State<InstructorPage> {
  int currentIndex = 0;

  List<Widget> screens({QuerySnapshot<Request>? requests}) {
    return [
      InstructorDashboard(requests: requests),
      InstructorTrainees(requests: requests),
      InstructorLessons(requests: requests),
      InstructorRequests(requests: requests),
    ];
  }

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
        body: StreamBuilder(
          stream: getRequestQuery().snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final requests = snapshot.data;
              return IndexedStack(
                index: currentIndex,
                children: screens(requests: requests),
              );
            } else {
              return const Loading(color: Colors.white10);
            }
          },
        ),
        floatingActionButton: null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) async {
            //lessons
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
                      ? const Icon(Icons.groups)
                      : Badge(
                          badgeContent: Text(
                            total.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                          child: const Icon(Icons.groups),
                        );
                },
              ),
              label: 'Trainees',
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
            BottomNavigationBarItem(
              icon: ValueListenableBuilder(
                valueListenable: NotificationsChangesHandler.requestsNotifier,
                builder: (context, value, child) {
                  int total = 0;
                  if (value is List) {
                    total = value.length;
                  }
                  return total == 0
                      ? const Icon(Icons.priority_high)
                      : Badge(
                          badgeContent: Text(
                            total.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                          child: const Icon(Icons.priority_high),
                        );
                },
              ),
              label: 'Requests',
            ),
          ],
        ),
      ),
    );
  }

  Query<Request> getRequestQuery() {
    Query query = FirebaseFirestore.instance
        .collection('requests')
        .where('receiverID', isEqualTo: AppUser.currentUser!.id)
        .orderBy('dateSent', descending: true);
    return query.withConverter(
        fromFirestore: (snapshot, _) => Request.fromJson(snapshot.data()!),
        toFirestore: (request, _) => request.toJsonReceiver());
  }
}
