import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/profile/profile_page.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/widgets/build_card.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/star_rating_average.dart';

class TraineeDashboard extends StatefulWidget {
  const TraineeDashboard({super.key, this.requests});
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
  State<TraineeDashboard> createState() => _TraineeDashboardState();
}

class _TraineeDashboardState extends State<TraineeDashboard> {
  AppUser user = AppUser();
  @override
  void initState() {
    super.initState();
    if (!FirebaseAuth.instance.currentUser!.isAnonymous) {
      user = AppUser.currentUser!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FirebaseAuth.instance.currentUser!.isAnonymous
          ? const Center(
              child: Text('You need to register to use this functionality.'))
          : Padding(
              padding: const EdgeInsets.all(15),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        width: 90,
                        height: 90,
                        child: Card(
                          elevation: 3,
                          shape: const CircleBorder(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: user.imageURL != null
                                    ? Image.network(user.imageURL!).image
                                    : const AssetImage('assets/guest.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        onPressed: viewProfile,
                        child: const Text('View Profile'),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: BuildCard(
                              header: 'Instructor Assigned',
                              customContent: instructorBuilder(),
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: lessonsBuilder()),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: trainingbuilder()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  viewProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(user: user),
      ),
    ).then(
      (_) => setState(() {
        user = AppUser.currentUser!;
      }),
    );
  }

  Widget instructorBuilder() {
    if (widget.requests == null || widget.getApproved().isEmpty) {
      return const Text('No instructor yet.');
    } else {
      final id = widget.requests!.docs.first.data().receiverID!;
      return StreamBuilder(
        stream: getUserDoc(id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final user = snapshot.data!.data()!;
            return Column(
              children: [
                CircleAvatar(
                  child: ClipOval(
                    child: user.imageURL != null
                        ? Image.network(
                            user.imageURL!,
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          )
                        : Image.asset(
                            'assets/guest.png',
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                  ),
                ),
                const SizedBox(height: 2.5),
                Text(user.fullName()!),
                const SizedBox(height: 2.5),
                StarRatingAverage(avg: user.ratingAverage!.toDouble())
              ],
            );
          } else {
            return const Loading(color: Colors.white10);
          }
        },
      );
    }
  }

  Widget lessonsBuilder() => ValueListenableBuilder(
        valueListenable: LessonTracker.lessons,
        builder: (context, value, _) {
          final completed = LessonTracker.lessons.getCompleted();
          final pending = LessonTracker.lessons.getPending();
          return BuildCard(
            header: 'Lessons Pending',
            content: pending,
            footer: 'Completed: $completed',
            color: Colors.orange,
          );
        },
      );

  Widget trainingbuilder() => StreamBuilder(
        stream: getHours(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final hoursDoc = snapshot.data!;
            if (hoursDoc.exists) {
              final hours = hoursDoc.data()!['hours'] as int;
              return BuildCard(
                header: 'Training Hours',
                content: '$hours',
                footer: '/ 22',
                color: Colors.green,
              );
            } else {
              return const BuildCard(
                header: 'Training Hours',
                content: '0',
                footer: '/ 22',
                color: Colors.green,
              );
            }
          } else {
            return const BuildCard(
              header: 'Training Hours',
              customContent: Loading(),
              color: Colors.green,
            );
          }
        },
      );

  Stream<DocumentSnapshot<Map<String, dynamic>>> getHours() {
    final userID = AppUser.currentUser!.id!;
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .collection('hours')
        .doc(userID);
    return doc.snapshots();
  }

  DocumentReference<AppUser> getUserDoc(String id) {
    final doc = FirebaseFirestore.instance.collection('users').doc(id);
    return doc.withConverter(
      fromFirestore: (snapshot, options) => AppUser.fromJson(snapshot.data()!),
      toFirestore: (user, options) => user.toJson(),
    );
  }
}
