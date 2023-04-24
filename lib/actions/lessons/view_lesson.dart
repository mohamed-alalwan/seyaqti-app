import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:seyaqti_app/actions/lessons/edit_lesson.dart';
import 'package:seyaqti_app/profile/profile_page.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/location_finder.dart';
import 'package:seyaqti_app/widgets/star_rating_average.dart';

class ViewLesson extends StatefulWidget {
  const ViewLesson({super.key, this.requests, required this.lesson});
  final QuerySnapshot<Request>? requests;
  final Lesson lesson;

  @override
  State<ViewLesson> createState() => _ViewLessonState();
}

class _ViewLessonState extends State<ViewLesson> {
  Marker? marker;
  List<AppUser> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    setUsers();
  }

  Future setUsers() async {
    try {
      List<AppUser> users = [];
      final traineeID = widget.lesson.traineeID!;
      final instructorID = widget.lesson.instructorID!;
      DocumentSnapshot<AppUser> snapshot = await getUserDoc(traineeID).get();
      if (snapshot.exists) {
        final trainee = snapshot.data()!;
        users.add(trainee);
        marker = Marker(
          markerId: const MarkerId('0'),
          position: LatLng(
            trainee.mapLatitude!,
            trainee.mapLongitude!,
          ),
        );
      }
      snapshot = await getUserDoc(instructorID).get();
      if (snapshot.exists) {
        final instructor = snapshot.data()!;
        users.add(instructor);
      }
      this.users = users;
      isLoading = false;
      setState(() {});
    } on FirebaseException catch (_) {
      debugPrint(_.message);
      Utils.ShowErrorBar('Something went wrong...');
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

  deleteLesson(Lesson lesson) async {
    final lessonDoc = FirebaseFirestore.instance
        .collection('requests/${lesson.requestID!}/lessons')
        .doc(lesson.id!);
    try {
      await lessonDoc.delete();
      Utils.ShowSuccessBar('Lesson has been deleted.');
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (_) {
      Utils.ShowErrorBar('Something went wrong...');
      debugPrint(_.message);
      Navigator.pop(context);
    }
  }

  editLesson(Lesson lesson) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditLesson(requests: widget.requests, lesson: lesson),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromDate = widget.lesson.date!;
    final dateText = DateFormat.yMEd().format(fromDate);
    final fromTimeText = DateFormat.jm().format(fromDate);
    final toDate = DateTime(fromDate.year, fromDate.month, fromDate.day,
        fromDate.hour + widget.lesson.duration!, fromDate.minute);
    final toTimeText = DateFormat.jm().format(toDate);
    final durationText = widget.lesson.duration! > 1
        ? '${widget.lesson.duration!.toString()} hours'
        : '${widget.lesson.duration!.toString()} hour';
    final grey = Colors.grey[700];
    final pickupText = widget.lesson.isPickup! ? 'Yes' : 'No';
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onTapDown: (_) => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lesson.title!),
          centerTitle: true,
          actions: widget.lesson.isComplete! ||
                  AppUser.currentUser!.type == 'Trainee'
              ? null
              : [
                  IconButton(
                    onPressed: () => editLesson(widget.lesson),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => deleteLesson(widget.lesson),
                    icon: const Icon(Icons.delete),
                  ),
                ],
        ),
        body: isLoading
            ? const Loading(color: Colors.white10)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.grey[700],
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Lesson Details',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(color: grey, fontSize: 16),
                                children: [
                                  WidgetSpan(
                                    child: Icon(
                                      Icons.calendar_today,
                                      size: 17,
                                      color: grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " Date: $dateText",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(color: grey, fontSize: 16),
                                children: [
                                  WidgetSpan(
                                    child: Icon(
                                      Icons.schedule,
                                      size: 17,
                                      color: grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " Time: $fromTimeText - $toTimeText",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(color: grey, fontSize: 16),
                                children: [
                                  WidgetSpan(
                                    child: Icon(
                                      Icons.hourglass_full,
                                      size: 17,
                                      color: grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " Duration: $durationText",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(color: grey, fontSize: 16),
                                children: [
                                  WidgetSpan(
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 17,
                                      color: grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: widget.lesson.isComplete!
                                        ? ' Status: Finished'
                                        : ' Status: Pending',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(color: grey, fontSize: 16),
                                children: [
                                  WidgetSpan(
                                    child: Icon(
                                      Icons.location_on,
                                      size: 17,
                                      color: grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' Pickup: $pickupText',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        if (users[index].type! == 'Trainee') {
                          return buildTrainee(users[index]);
                        } else {
                          return buildInstructor(users[index]);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    if (widget.lesson.isPickup! &&
                        !widget.lesson.isComplete! &&
                        AppUser.currentUser!.type != 'Trainee')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LocationFinder(selectedMarker: marker),
                          ),
                        ),
                        label: const Text('LOCATION'),
                        icon: const Icon(Icons.location_on),
                      ),
                    if (widget.lesson.isPickup! &&
                        !widget.lesson.isComplete! &&
                        AppUser.currentUser!.type == 'Trainee')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: null,
                        label: const Text('LIVE TRACKING (Coming Soon)'),
                        icon: const Icon(Icons.location_on),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget buildTrainee(AppUser user) {
    return Column(
      children: [
        Row(
          children: [
            Text('${user.type!}:', textAlign: TextAlign.left),
          ],
        ),
        Card(
          margin: const EdgeInsets.only(top: 5, bottom: 20),
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
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
            )),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(user: user),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildInstructor(AppUser user) {
    return Column(
      children: [
        Row(
          children: [
            Text('${user.type!}:', textAlign: TextAlign.left),
          ],
        ),
        Card(
          margin: const EdgeInsets.only(top: 5, bottom: 5),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(7),
            leading: CircleAvatar(
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
              MaterialPageRoute(builder: (context) => ProfilePage(user: user)),
            ),
          ),
        ),
      ],
    );
  }
}
