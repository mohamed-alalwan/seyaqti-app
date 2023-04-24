import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/firestore.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:seyaqti_app/profile/edit_profile_page.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/star_rating_average.dart';

// ignore: must_be_immutable
class ProfilePage extends StatefulWidget {
  ProfilePage({super.key, required this.user, this.acceptRequest});
  AppUser user;
  final bool? acceptRequest;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final tab1Controller = ScrollController();
  final tab2Controller = ScrollController();
  final tab3Controller = ScrollController();
  bool requested = false;
  bool requestClicked = false;
  bool accepted = false;
  bool acceptClicked = false;
  bool isInstructor = false;
  AppUser user = AppUser();

  @override
  void initState() {
    super.initState();
    if (!FirebaseAuth.instance.currentUser!.isAnonymous) {
      user = AppUser.currentUser!;
    }
    isInstructor = widget.user.type == 'Instructor';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: getTabs().length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.user.type!}'s Page"),
          centerTitle: true,
          actions: getActions(),
          bottom: TabBar(
            tabs: getTabTitles(),
          ),
        ),
        body: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    image: isInstructor
                        ? DecorationImage(
                            image: widget.user.carURL != null
                                ? Image.network(widget.user.carURL!).image
                                : const AssetImage('assets/car.jpg'),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      isInstructor ? 0.25 : 0,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  constraints:
                      const BoxConstraints(maxWidth: 200, maxHeight: 120),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: widget.user.imageURL != null
                                ? Image.network(widget.user.imageURL!).image
                                : const AssetImage('assets/guest.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        widget.user.fullName()!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isInstructor)
                        StarRatingAverage(
                          avg: widget.user.ratingAverage!.toDouble(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: getTabs(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Tab> getTabTitles() => [
        const Tab(text: 'Personal'),
        if (isInstructor) const Tab(text: 'Work'),
        if (isInstructor) const Tab(text: 'Reviews'),
      ];

  List<Widget> getTabs() => [
        Scrollbar(
          thickness: 5,
          thumbVisibility: true,
          radius: const Radius.circular(100),
          controller: tab1Controller,
          child: ListView(
            controller: tab1Controller,
            shrinkWrap: true,
            children: [
              buildField('Age', '${widget.user.calculateAge()} years old'),
              buildField('Gender', widget.user.gender!),
              buildField('Location', widget.user.city!),
            ],
          ),
        ),
        if (isInstructor)
          Scrollbar(
            thickness: 5,
            thumbVisibility: true,
            radius: const Radius.circular(100),
            controller: tab2Controller,
            child: ListView(
              controller: tab2Controller,
              shrinkWrap: true,
              children: [
                buildField(
                    'Experience Years', widget.user.experienceYears.toString()),
                buildField('Phone Number', widget.user.phoneNumber.toString()),
                buildField('Car Make', widget.user.carMake.toString()),
                buildField('Car Model', widget.user.carModel.toString()),
                buildField('Car Year', widget.user.carYear.toString()),
                buildField('Transmission Type',
                    widget.user.transmissionType.toString()),
              ],
            ),
          ),
        if (isInstructor)
          Scrollbar(
            thickness: 5,
            thumbVisibility: true,
            radius: const Radius.circular(100),
            controller: tab3Controller,
            child: SingleChildScrollView(
              controller: tab3Controller,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Text(
                          'Reviews (${widget.user.ratingCount})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          height: 0.5,
                          width: 250,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.only(top: 15),
                        ),
                      ],
                    ),
                  ),
                  buildReviewList(),
                ],
              ),
            ),
          ),
      ];

  Widget buildReviewList() {
    return FirestoreQueryBuilder(
      query: getReviewQuery(),
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return const Loading(color: Colors.white10);
        }
        if (snapshot.hasError) {
          return Text('error ${snapshot.error}');
        }
        return ListView.builder(
          controller: tab3Controller,
          shrinkWrap: true,
          itemCount: snapshot.docs.length,
          itemBuilder: (context, index) {
            if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
              snapshot.fetchMore();
            }
            final review = snapshot.docs[index].data();
            return Column(
              children: [
                buildReview(review),
              ],
            );
          },
        );
      },
    );
  }

  Query<Review> getReviewQuery() {
    final instructorID = widget.user.id!;
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(instructorID)
        .collection('reviews')
        .orderBy('dateUpdated');
    return query.withConverter(
      fromFirestore: (snapshot, _) => Review.fromJson(snapshot.data()!),
      toFirestore: (review, _) => review.toJson(),
    );
  }

  Widget buildReview(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15, right: 32, left: 32),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Text(
              review.title!,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            StarRatingAverage(avg: review.rating!),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(2.5),
              child: ReadMoreText(
                review.comment!,
                trimLines: 3,
                trimMode: TrimMode.Line,
                trimCollapsedText: 'Show more',
                trimExpandedText: 'Show less',
                moreStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.blueAccent,
                ),
                lessStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.blueAccent,
                ),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipOval(
                        child: review.imageURL != null
                            ? Image.network(
                                review.imageURL!,
                                fit: BoxFit.cover,
                                width: 25,
                                height: 25,
                              )
                            : Image.asset(
                                'assets/guest.png',
                                fit: BoxFit.cover,
                                width: 25,
                                height: 25,
                              ),
                      ),
                      const SizedBox(width: 5),
                      Text(review.displayName!,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  DateFormat.yMd().format(review.dateUpdated!),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.end,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String field, String value) => Center(
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(field, style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                height: 0.5,
                width: 250,
                color: Colors.grey[300],
                margin: const EdgeInsets.all(15),
              ),
              Text(value),
            ],
          ),
        ),
      );

  List<Widget> getActions() => [
        if (widget.user.id != FirebaseAuth.instance.currentUser!.uid &&
            widget.user.type == 'Instructor')
          requestButton(),
        if (FirebaseAuth.instance.currentUser!.uid == widget.user.id)
          editButton(),
        if (widget.user.id != FirebaseAuth.instance.currentUser!.uid &&
            widget.acceptRequest != null)
          acceptButton(),
      ];

  IconButton requestButton() => IconButton(
        onPressed: requestClicked
            ? null
            : () async {
                setState(() => requestClicked = true);
                setState(() => requested = false);
                if (FirebaseAuth.instance.currentUser!.isAnonymous) {
                  Utils.ShowErrorBar(
                      'You need to register to use this functionality.');
                  return;
                }
                final requests = FirebaseFirestore.instance
                    .collection('requests')
                    .where('senderID', isEqualTo: user.id);
                try {
                  final snapshot = await requests.get();
                  bool requestedBefore = false;
                  if (snapshot.docs.isNotEmpty) {
                    setState(() => requested = true);
                    if (snapshot.docs.first.data()['receiverID'] !=
                        widget.user.id) {
                      requestedBefore = true;
                    }
                  }
                  showDialog(
                    context: context,
                    builder: (context) {
                      return requestAlert(requestedBefore);
                    },
                  );
                } on FirebaseException catch (_) {
                  Utils.ShowErrorBar('Something went wrong...');
                }
                setState(() => requestClicked = false);
              },
        icon: const Icon(Icons.person_add),
      );

  AlertDialog requestAlert(bool requestedBefore) {
    return AlertDialog(
      title: const Center(child: Text('Request Training')),
      content: Text(
        'Are you sure you want to request training from ${widget.user.fullName()}?',
        textAlign: TextAlign.center,
      ),
      actions: [
        ElevatedButton(
          onPressed: requested
              ? null
              : () async {
                  try {
                    final requests =
                        FirebaseFirestore.instance.collection('requests').doc();
                    Request request = Request(
                      receiverID: widget.user.id,
                      senderID: user.id,
                      dateSent: DateTime.now(),
                    );
                    final json = request.toJsonSender();
                    await requests.set(json);
                  } on FirebaseException catch (_) {
                    Utils.ShowErrorBar('Something went wrong...');
                  }
                  Utils.ShowSuccessBar('Request has been sent.');
                  if (!mounted) return;
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            requested
                ? requestedBefore
                    ? 'REQUESTED ANOTHER INSTRUCTOR'
                    : 'REQUEST SENT'
                : 'YES',
            textAlign: TextAlign.center,
          ),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('CANCEL'),
        ),
      ],
      elevation: 5,
      actionsAlignment: MainAxisAlignment.center,
      contentTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 18,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      actionsPadding: const EdgeInsets.all(30),
    );
  }

  IconButton editButton() => IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfilePage(user: user),
            ),
          ).then(
            (_) => setState(() {
              widget.user = user;
            }),
          );
        },
        icon: const Icon(Icons.edit),
      );

  IconButton acceptButton() => IconButton(
        onPressed: acceptClicked
            ? null
            : () async {
                setState(() => acceptClicked = true);
                setState(() => accepted = false);
                final collection = FirebaseFirestore.instance
                    .collection('requests')
                    .where('receiverID', isEqualTo: user.id)
                    .where('senderID', isEqualTo: widget.user.id);
                try {
                  final snapshot = await collection.get();
                  if (snapshot.docs.isNotEmpty) {
                    final json = snapshot.docs.first.data();
                    final id = snapshot.docs.first.id;
                    final request = Request.fromJson(json);
                    if (request.approval == true) {
                      setState(() => accepted = true);
                    }
                    showDialog(
                      context: context,
                      builder: (context) => acceptAlert(request, id),
                    );
                  }
                } on FirebaseException catch (_) {
                  Utils.ShowErrorBar('Something went wrong...');
                }
                setState(() => acceptClicked = false);
              },
        icon: const Icon(Icons.priority_high),
      );

  AlertDialog acceptAlert(Request request, String id) => AlertDialog(
        title: const Center(child: Text('Request Training')),
        content: Text(
          'Are you sure you want to accept training request from ${widget.user.fullName()}?',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: accepted
                ? null
                : () async {
                    try {
                      final doc = FirebaseFirestore.instance
                          .collection('requests')
                          .doc(id);
                      request.approval = true;
                      request.dateSent = DateTime.now();
                      await doc.set(request.toJsonReceiver());
                    } on FirebaseException catch (_) {
                      Utils.ShowErrorBar('Something went wrong...');
                    }
                    Utils.ShowSuccessBar("Trainee's request is accepted.");
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(accepted ? 'ACCEPTED' : 'ACCEPT REQUEST'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('CANCEL'),
          ),
        ],
        elevation: 5,
        actionsAlignment: MainAxisAlignment.center,
        contentTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        actionsPadding: const EdgeInsets.all(30),
      );
}
