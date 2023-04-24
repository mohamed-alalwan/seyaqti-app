import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/profile/profile_page.dart';
import 'package:seyaqti_app/widgets/build_card.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/star_rating_average.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key, this.requests});
  final QuerySnapshot<Request>? requests;

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  final reviewsScroller = ScrollController();
  AppUser user = AppUser.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
                      child: traineesTotalBuilder(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: lessonsBuilder(),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: BuildCard(
                        header: 'Recent Reviews',
                        customContent: Scrollbar(
                          thumbVisibility: true,
                          controller: reviewsScroller,
                          child: SingleChildScrollView(
                            controller: reviewsScroller,
                            scrollDirection: Axis.horizontal,
                            child: buildReviews(),
                          ),
                        ),
                        color: Colors.green,
                      ),
                    ),
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

  Widget buildSimpleReview({
    required String title,
    required double rate,
    required String name,
    String? imageURL,
  }) =>
      Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(20)),
        width: 250,
        height: 100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(title),
            StarRatingAverage(avg: rate),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: imageURL != null
                      ? Image.network(
                          imageURL,
                          fit: BoxFit.cover,
                          width: 20,
                          height: 20,
                        )
                      : Image.asset(
                          'assets/guest.png',
                          fit: BoxFit.cover,
                          width: 20,
                          height: 20,
                        ),
                ),
                const SizedBox(width: 5),
                Text(name, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      );

  Widget traineesTotalBuilder() {
    if (widget.requests == null) {
      return const BuildCard(
        header: 'Current Trainees',
        content: '0',
        color: Colors.red,
        footer: 'Requests: 0',
      );
    } else {
      int approved = 0;
      int notApproved = 0;
      for (var doc in widget.requests!.docs) {
        final request = doc.data();
        if (request.approval == true) {
          approved += 1;
        } else {
          notApproved += 1;
        }
      }
      return BuildCard(
        header: 'Current Trainees',
        content: approved.toString(),
        color: Colors.red,
        footer: 'Requests: $notApproved',
      );
    }
  }

  Query<Review> getReviewQuery() {
    final instructorID = AppUser.currentUser!.id!;
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(instructorID)
        .collection('reviews')
        .orderBy('dateUpdated', descending: true)
        .limit(3);
    return query.withConverter(
      fromFirestore: (snapshot, _) => Review.fromJson(snapshot.data()!),
      toFirestore: (review, _) => review.toJson(),
    );
  }

  Widget buildReviews() => StreamBuilder(
        stream: getReviewQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Widget> reviews = [];
            if (snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                final review = doc.data();
                reviews.add(
                  buildSimpleReview(
                    title: review.title!,
                    rate: review.rating!,
                    name: review.displayName!,
                    imageURL: review.imageURL,
                  ),
                );
              }
            } else {
              reviews.add(const Text('No reviews yet.'));
            }
            return Row(
              children: reviews,
            );
          } else {
            return const Loading();
          }
        },
      );
}
