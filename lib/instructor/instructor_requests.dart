import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/profile/profile_page.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/widgets/loading.dart';

class InstructorRequests extends StatefulWidget {
  const InstructorRequests({super.key, required this.requests});
  final QuerySnapshot<Request>? requests;

  @override
  State<InstructorRequests> createState() => _InstructorRequestsState();
}

class _InstructorRequestsState extends State<InstructorRequests> {
  @override
  Widget build(BuildContext context) {
    final List<String> ids = [];
    if (widget.requests != null || widget.requests!.docs.isNotEmpty) {
      for (var doc in widget.requests!.docs) {
        final request = doc.data();
        if (request.approval == null) {
          ids.add(request.senderID!);
        }
      }
    }
    return Scaffold(
      body: ids.isEmpty
          ? const Center(child: Text('No requests yet.'))
          : getUsers(ids),
    );
  }

  Widget getUsers(List<String> ids) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final id = ids[index];
        return StreamBuilder(
          stream: getUserDoc(id).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final user = snapshot.data!.data()!;
              return buildUser(user);
            } else {
              return const Loading(color: Colors.white10);
            }
          },
        );
      },
    );
  }

  DocumentReference<AppUser> getUserDoc(String id) {
    final doc = FirebaseFirestore.instance.collection('users').doc(id);
    return doc.withConverter(
      fromFirestore: (snapshot, options) => AppUser.fromJson(snapshot.data()!),
      toFirestore: (user, options) => user.toJson(),
    );
  }

  Widget buildUser(AppUser user) {
    return Card(
      margin: const EdgeInsets.only(right: 10, left: 10, top: 5, bottom: 5),
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          child: ValueListenableBuilder(
            valueListenable: NotificationsChangesHandler.requestsNotifier,
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
        subtitle: RichText(
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
        onTap: () async {
          List<String> requestNotifications = UserPreferences.instance
                  .getStringList(
                      NotificationsChangesHandler.requestsNotifier.getKey()) ??
              [];
          if (requestNotifications.isNotEmpty) {
            requestNotifications.removeWhere((id) => id == user.id);
          }
          //update listeners
          await NotificationsChangesHandler.requestsNotifier
              .updateValue(requestNotifications);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProfilePage(user: user, acceptRequest: true),
            ),
          );
        },
      ),
    );
  }
}
