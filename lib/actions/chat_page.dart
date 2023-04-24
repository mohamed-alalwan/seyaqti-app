import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:intl/intl.dart';
import 'package:seyaqti_app/actions/end_training.dart';
import 'package:seyaqti_app/actions/lessons/add_lesson.dart';
import 'package:seyaqti_app/actions/edit_hours.dart';
import 'package:seyaqti_app/actions/manage_review.dart';
import 'package:seyaqti_app/profile/profile_page.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.user,
    required this.id,
    this.requests,
  });
  final AppUser user;
  final String id;
  final QuerySnapshot<Request>? requests;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  StreamSubscription? messageListener;
  final controller = TextEditingController();
  final now = DateTime.now();
  bool isInForeground = true;

  final endAlert = EndTraining();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setMessageListener();
    setPageData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    setState(() {
      isInForeground = state == AppLifecycleState.resumed;
    });
  }

  @override
  void dispose() {
    super.dispose();
    messageListener!.cancel();
    revertPageData();
    WidgetsBinding.instance.removeObserver(this);
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.user.fullName()!),
          centerTitle: true,
          actions: [
            AppUser.currentUser!.type == 'Trainee'
                ? popupMenuTrainee()
                : popupMenuInstructor(),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(right: 16, left: 16),
                child: StreamBuilder(
                  stream: getMessages(widget.id).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final messages = snapshot.data!.docs;
                      return messages.isEmpty
                          ? buildText('Say Hi..')
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              reverse: true,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                return buildMessage(messages[index].data());
                              },
                            );
                    } else {
                      return const Loading(color: Colors.white10);
                    }
                  },
                ),
              ),
            ),
            Material(
              elevation: 30,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        autocorrect: true,
                        enableSuggestions: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          labelText: 'Your Message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            gapPadding: 10,
                          ),
                        ),
                        onEditingComplete: sendMessage,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: sendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(15),
                      ),
                      child: const Icon(Icons.send),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  setMessageListener() {
    messageListener =
        getMessages(widget.id).limit(1).snapshots().listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final message = snapshot.docs.first.data();
        if (message.dateSent!.compareTo(now) > 0 &&
            message.userID! != AppUser.currentUser!.id) {
          isInForeground
              ? FlutterRingtonePlayer.playNotification()
              : await NotificationsApi.showNotification(
                  title: 'New Message',
                  body:
                      '${message.userType} ${message.userName}: ${message.message}',
                  payload: 'chats',
                );
        }
      }
    });
  }

  Future sendMessage() async {
    FocusScope.of(context).unfocus();
    final messageText = controller.text.trim();
    if (controller.text.trim().isEmpty) return;
    try {
      //add message
      final message = Message(
        userID: AppUser.currentUser!.id,
        userName: AppUser.currentUser!.firstName,
        userType: AppUser.currentUser!.type,
        message: messageText,
        dateSent: DateTime.now(),
      );
      final collection = FirebaseFirestore.instance
          .collection('requests/${widget.id}/messages');
      await collection.add(message.toJson());
      final request =
          FirebaseFirestore.instance.collection('requests').doc(widget.id);
      await request.set({'dateSent': DateTime.now()}, SetOptions(merge: true));
    } on FirebaseException catch (_) {
      Utils.ShowErrorBar('Something went wrong...');
      debugPrint(_.message);
    }
    controller.clear();
  }

  Future setPageData() async {
    await UserPreferences.instance.setString('isChattingWith', widget.user.id!);
    List<String> chatNotifications = UserPreferences.instance.getStringList(
            NotificationsChangesHandler.chatsNotifier.getKey()) ??
        [];
    if (chatNotifications.isNotEmpty) {
      chatNotifications.removeWhere((id) => id == widget.user.id);
      //update listeners
      await NotificationsChangesHandler.chatsNotifier
          .updateValue(chatNotifications);
    }
  }

  Future revertPageData() async {
    await UserPreferences.instance.remove('isChattingWith');
  }

  Query<Message> getMessages(String id) {
    Query query =
        FirebaseFirestore.instance.collection('requests/$id/messages');
    query = query.orderBy('dateSent', descending: true);

    return query.withConverter(
        fromFirestore: (snapshot, _) => Message.fromJson(snapshot.data()!),
        toFirestore: (message, _) => message.toJson());
  }

  Widget buildMessage(Message message) {
    final isMe = (AppUser.currentUser!.id! == message.userID);
    const radius = Radius.circular(12);
    const borderRadius = BorderRadius.all(radius);
    final date = DateFormat.yMd().add_jm().format(message.dateSent!);
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.grey[200]
                : const Color.fromARGB(255, 250, 234, 230),
            borderRadius: isMe
                ? borderRadius
                    .subtract(const BorderRadius.only(bottomRight: radius))
                : borderRadius
                    .subtract(const BorderRadius.only(bottomLeft: radius)),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.message!,
                style: const TextStyle(color: Colors.black),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 10),
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget buildText(String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[500], fontSize: 25),
      ),
    );
  }

  Widget popupMenuInstructor() => PopupMenuButton(
        onSelected: (value) {
          //view profile
          if (value == 1) {
            viewProfile();
          }
          //add lesson
          if (value == 2) {
            addLesson();
          }
          //update hours
          if (value == 3) {
            editHours();
          }
          //end training
          if (value == 4) {
            endTraining();
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.grey[900],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'View Profile',
                    style: TextStyle(color: Colors.grey[900]),
                  )
                ],
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey[900],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Add Lesson',
                    style: TextStyle(color: Colors.grey[900]),
                  )
                ],
              ),
            ),
            PopupMenuItem(
              value: 3,
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.grey[900],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Update Hours',
                    style: TextStyle(color: Colors.grey[900]),
                  )
                ],
              ),
            ),
            PopupMenuItem(
              value: 4,
              child: Row(
                children: const [
                  Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'End Training',
                    style: TextStyle(color: Colors.red),
                  )
                ],
              ),
            ),
          ];
        },
      );

  Widget popupMenuTrainee() => PopupMenuButton(
        onSelected: (value) {
          //call mobile
          if (value == 1) {
            callMobile();
          }
          //view profile
          if (value == 2) {
            viewProfile();
          }
          //write review
          if (value == 3) {
            manageReview();
          }
          //end training
          if (value == 4) {
            endTraining();
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(
                    Icons.call,
                    color: Colors.grey[900],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Call Mobile',
                    style: TextStyle(color: Colors.grey[900]),
                  )
                ],
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.grey[900],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'View Profile',
                    style: TextStyle(color: Colors.grey[900]),
                  )
                ],
              ),
            ),
            PopupMenuItem(
              value: 3,
              child: Row(
                children: [
                  Icon(
                    Icons.reviews,
                    color: Colors.grey[900],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Write Review',
                    style: TextStyle(color: Colors.grey[900]),
                  )
                ],
              ),
            ),
            PopupMenuItem(
              value: 4,
              child: Row(
                children: const [
                  Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'End Training',
                    style: TextStyle(color: Colors.red),
                  )
                ],
              ),
            ),
          ];
        },
      );

  Future callMobile() async {
    await launchUrl(Uri(scheme: 'tel', path: widget.user.phoneNumber));
  }

  addLesson() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLesson(
          traineeID: widget.user.id,
          requests: widget.requests,
        ),
      ));

  viewProfile() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(user: widget.user),
      ));

  editHours() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHours(traineeID: widget.user.id!),
      ));

  manageReview() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageReview(instructorID: widget.user.id!),
      ));

  endTraining() {
    showDialog(
      context: context,
      builder: (context) => endAlert,
    ).then((_) async {
      if (endAlert.confirm is bool) {
        final endConfirmed = endAlert.confirm!;
        if (endConfirmed) {
          debugPrint('end training');
          try {
            //delete lessons
            final lessonsCol =
                await getRequestDoc().collection('lessons').get();
            for (var doc in lessonsCol.docs) {
              await doc.reference.delete();
            }
            //delete messages
            final messagesCol =
                await getRequestDoc().collection('messages').get();
            for (var doc in messagesCol.docs) {
              await doc.reference.delete();
            }
            //delete requests
            await getRequestDoc().delete();
            if (!mounted) return;
            Navigator.pop(context);
          } on FirebaseException catch (e) {
            debugPrint(e.message);
            Utils.ShowErrorBar('Something went wrong');
          }
        }
      }
    });
  }

  DocumentReference<Request> getRequestDoc() {
    final id = widget.id;
    final doc = FirebaseFirestore.instance.collection('requests').doc(id);
    return doc.withConverter(
      fromFirestore: (snapshot, options) => Request.fromJson(snapshot.data()!),
      toFirestore: (request, options) => request.toJsonReceiver(),
    );
  }
}
