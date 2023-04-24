import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/actions/chat_page.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/star_rating_average.dart';

class TraineeInstructor extends StatefulWidget {
  const TraineeInstructor({super.key, this.requests});
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
  State<TraineeInstructor> createState() => _TraineeInstructorState();
}

class _TraineeInstructorState extends State<TraineeInstructor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FirebaseAuth.instance.currentUser!.isAnonymous
          ? const Center(
              child: Text('You need to register to use this functionality.'))
          : widget.requests == null || widget.getApproved().isEmpty
              ? const Center(child: Text('No instructor yet.'))
              : ListView.builder(
                  itemCount: widget.requests!.docs.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final id = widget.requests!.docs[index].data().receiverID!;
                    return StreamBuilder(
                      stream: getUserDoc(id).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final user = snapshot.data!.data()!;
                          return buildUser(
                            user,
                            widget.requests!.docs[index].id,
                          );
                        } else {
                          return const Loading(color: Colors.white10);
                        }
                      },
                    );
                  },
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

  Widget buildUser(AppUser user, String id) {
    return Card(
      margin: const EdgeInsets.only(right: 10, left: 10, top: 5, bottom: 5),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(7),
        leading: CircleAvatar(
          child: ValueListenableBuilder(
            valueListenable: NotificationsChangesHandler.chatsNotifier,
            builder: (context, value, child) {
              int total = 0;
              if (value is List) {
                for (var id in value) {
                  if (id == user.id) total += 1;
                }
              }
              return total == 0
                  ? ClipOval(
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
                    )
                  : Badge(
                      badgeContent: Text(
                        total.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
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
                    );
            },
          ),
        ),
        title: Text(user.fullName()!),
        trailing: Column(
          children: const [
            Expanded(child: Icon(Icons.arrow_forward_ios)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarRatingAverage(avg: user.ratingAverage!.toDouble()),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[700]),
                children: [
                  const WidgetSpan(
                    child: Icon(Icons.location_on, size: 15),
                  ),
                  TextSpan(text: " ${user.city!}"),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[700]),
                children: [
                  const WidgetSpan(
                    child: Icon(Icons.directions_car, size: 15),
                  ),
                  TextSpan(
                    text:
                        " ${user.carMake!} | ${user.carModel!} | ${user.carYear!}",
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              user: user,
              id: id,
            ),
          ),
        ),
      ),
    );
  }
}
