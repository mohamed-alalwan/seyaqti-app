import 'dart:async';
import 'package:intl/intl.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsListeners {
  static DateTime date = DateTime.now();
  static StreamSubscription? requestListener;
  static StreamSubscription? userListener;
  static StreamSubscription? reviewListener;
  static List<StreamSubscription> messagesListeners = [];
  static List<StreamSubscription> lessonsListeners = [];
  static List<QuerySnapshot<Request>> requestSnapshots = [];
  static List<QuerySnapshot<Lesson>> lessonSnapshots = [];
  static List<QuerySnapshot<Review>> reviewSnapshots = [];

  static cancelListeners() async {
    await userListener?.cancel();
    await requestListener?.cancel();
    await reviewListener?.cancel();
    for (var listener in messagesListeners) {
      await listener.cancel();
    }
    for (var listener in lessonsListeners) {
      await listener.cancel();
    }
    messagesListeners.clear();
    lessonsListeners.clear();
    requestSnapshots.clear();
    lessonSnapshots.clear();
    reviewSnapshots.clear();
  }

  static cancelFixListeners() async {
    for (var listener in messagesListeners) {
      await listener.cancel();
    }
    messagesListeners.clear();
    for (var listener in lessonsListeners) {
      await listener.cancel();
    }
    lessonsListeners.clear();
    lessonSnapshots.clear();
  }

  static setListeners() async {
    await cancelListeners();
    date = DateTime.now();
    userListener = getUserDoc().snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final user = snapshot.data()!;
        AppUser.currentUser = user;
      }
    });
    requestListener = getRequests().snapshots().listen(
      (snapshot) async {
        await cancelFixListeners();
        if (requestSnapshots.length == 2) requestSnapshots.removeAt(0);
        requestSnapshots.add(snapshot);
        //requests Changes
        for (var docChange in snapshot.docChanges) {
          if (docChange.type == DocumentChangeType.removed) {
            handleRequestDelete(docChange);
            return;
          } else if (docChange.type == DocumentChangeType.added &&
              requestSnapshots.length == 2) {
            handleRequestAdd(docChange);
          } else if (docChange.type == DocumentChangeType.modified) {
            handleRequestEdit(
              docChange,
              requestSnapshots[requestSnapshots.length - 2]
                  .docs
                  .firstWhere((doc) => doc.id == docChange.doc.id),
            );
          }
        }
        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            //messages
            messagesListeners.add(getMessages(doc.id).snapshots().listen(
              (snapshot) async {
                if (snapshot.docs.isNotEmpty) {
                  final message = snapshot.docs.first.data();
                  handleMessages(message);
                }
              },
            ));
            //lessons
            lessonsListeners.add(
              getLessons(doc.id).snapshots().listen(
                (snapshot) async {
                  if (lessonSnapshots.length == 2) lessonSnapshots.removeAt(0);
                  lessonSnapshots.add(snapshot);
                  for (var docChange in snapshot.docChanges) {
                    if (docChange.type == DocumentChangeType.removed) {
                      handleLessonDelete(docChange);
                    } else if (docChange.type == DocumentChangeType.added &&
                        lessonSnapshots.length == 2) {
                      handleLessonAdd(docChange);
                    } else if (docChange.type == DocumentChangeType.modified) {
                      handleLessonEdit(docChange);
                    }
                  }
                },
              ),
            );
          }
        }
      },
    );
    if (AppUser.currentUser!.type! == 'Instructor') {
      reviewListener = getReviewCollection().snapshots().listen(
        (snapshot) async {
          if (reviewSnapshots.length == 2) reviewSnapshots.removeAt(0);
          reviewSnapshots.add(snapshot);
          for (var docChange in snapshot.docChanges) {
            if (docChange.type == DocumentChangeType.added &&
                reviewSnapshots.length == 2) {
              await handleReviewAdd(docChange);
            }
          }
        },
      );
    }
  }

  static Future handleReviewAdd(DocumentChange<Review> docChange) async {
    final review = docChange.doc.data()!;
    await NotificationsApi.showNotification(
      title: 'New Review',
      body: '${review.displayName} has reviewed your training.',
      payload: 'reviews',
    );
  }

  static Future handleRequestDelete(DocumentChange<Request> docChange) async {
    final request = docChange.doc.data()!;
    bool isSender = AppUser.currentUser!.id! == request.senderID!;
    //delete chat notificationss
    List<String> chatNotifications = UserPreferences.instance.getStringList(
            NotificationsChangesHandler.chatsNotifier.getKey()) ??
        [];
    if (chatNotifications.isNotEmpty) {
      chatNotifications.removeWhere(
          (id) => id == request.senderID! || id == request.receiverID!);
      await NotificationsChangesHandler.chatsNotifier
          .updateValue(chatNotifications);
    }

    //delete lesson notifications
    List<String> lessonNotifications = UserPreferences.instance.getStringList(
            NotificationsChangesHandler.lessonsNotifier.getKey()) ??
        [];
    if (lessonNotifications.isNotEmpty && lessonSnapshots.isNotEmpty) {
      List<String> ids = [];
      for (var doc in lessonSnapshots.last.docs) {
        ids.add(doc.id);
      }
      lessonNotifications.removeWhere((id) => ids.contains(id));
      await NotificationsChangesHandler.lessonsNotifier
          .updateValue(lessonNotifications);
    }

    //delete request notifications
    List<String> requestNotifications = UserPreferences.instance.getStringList(
            NotificationsChangesHandler.requestsNotifier.getKey()) ??
        [];
    if (requestNotifications.isNotEmpty) {
      requestNotifications.removeWhere(
          (id) => id == request.senderID! || id == request.receiverID!);
      await NotificationsChangesHandler.requestsNotifier
          .updateValue(requestNotifications);
    }
    //show end training notification
    if (request.approval != null) {
      if (isSender) {
        await NotificationsApi.showNotification(
          title: 'Training Ended',
          body: 'Training with your instructor has been terminated.',
          payload: 'requests',
        );
      } else {
        await NotificationsApi.showNotification(
          title: 'Training Ended',
          body: 'Training with a trainee has been terminated',
          payload: 'requests',
        );
      }
    }
  }

  static Future handleRequestAdd(DocumentChange<Request> docChange) async {
    final request = docChange.doc.data()!;
    bool isSender = AppUser.currentUser!.id! == request.senderID!;
    if (!isSender && request.approval == null) {
      //notify requested
      await NotificationsApi.showNotification(
        title: 'New Request',
        body: 'A trainee has requested you for training.',
        payload: 'requests',
      );
      //save noti for receiver
      List<String> requestNotifications = UserPreferences.instance
              .getStringList(
                  NotificationsChangesHandler.requestsNotifier.getKey()) ??
          [];
      requestNotifications.add(request.senderID!);
      await NotificationsChangesHandler.requestsNotifier
          .updateValue(requestNotifications);
    }
  }

  static Future handleRequestEdit(DocumentChange<Request> docChange,
      QueryDocumentSnapshot<Request> doc) async {
    final request = docChange.doc.data()!;
    final previousRequest = doc.data();
    bool isSender = AppUser.currentUser!.id! == request.senderID!;
    if (previousRequest.approval != request.approval) {
      if (isSender) {
        //notify accepted
        await NotificationsApi.showNotification(
          title: 'Request Accepted',
          body: 'Instructor has accepted your request.',
          payload: 'chats',
        );
        //save noti for sender
        List<String> chatNotifications = UserPreferences.instance.getStringList(
                NotificationsChangesHandler.chatsNotifier.getKey()) ??
            [];
        chatNotifications.add(request.receiverID!);
        await NotificationsChangesHandler.chatsNotifier
            .updateValue(chatNotifications);
      } else {
        //save noti for receiver
        List<String> chatNotifications = UserPreferences.instance.getStringList(
                NotificationsChangesHandler.chatsNotifier.getKey()) ??
            [];
        chatNotifications.add(request.senderID!);
        await NotificationsChangesHandler.chatsNotifier
            .updateValue(chatNotifications);
      }
    }
  }

  static Future handleLessonDelete(DocumentChange<Lesson> docChange) async {
    final lesson = docChange.doc.data()!;
    bool isTrainee = AppUser.currentUser!.id! == lesson.traineeID!;
    if (isTrainee) {
      //notify trainee
      await NotificationsApi.showNotification(
        title: 'Lesson Canceled',
        body: 'Your Instructor has canceled lesson (${lesson.title!}).',
        payload: 'lessons',
      );
    }
    //remove noti for both
    List<String> lessonNotifications = UserPreferences.instance.getStringList(
            NotificationsChangesHandler.lessonsNotifier.getKey()) ??
        [];
    if (lessonNotifications.isNotEmpty) {
      lessonNotifications.removeWhere((id) => id == lesson.id);
      await NotificationsChangesHandler.lessonsNotifier
          .updateValue(lessonNotifications);
    }
    //remove scheduled notification
    await NotificationsApi.notifications.cancel(int.parse(lesson.id!));
  }

  static Future handleLessonAdd(DocumentChange<Lesson> docChange) async {
    final lesson = docChange.doc.data()!;
    bool isTrainee = AppUser.currentUser!.id! == lesson.traineeID!;
    bool onLessonView =
        UserPreferences.instance.getBool('onLessonView') ?? false;
    if (!lesson.isComplete!) {
      final fromDate = lesson.date!;
      final fromTimeText = DateFormat.jm().format(fromDate);
      final toDate = DateTime(fromDate.year, fromDate.month, fromDate.day,
          fromDate.hour + lesson.duration!, fromDate.minute);
      final toTimeText = DateFormat.jm().format(toDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final aDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final dateText = aDate == today
          ? 'Today'
          : aDate == yesterday
              ? 'Yesterday'
              : aDate == tomorrow
                  ? 'Tomorrow'
                  : DateFormat.yMEd().format(fromDate);
      if (isTrainee) {
        //notify trainee
        await NotificationsApi.showNotification(
          title: "New Lesson '${lesson.title!}'",
          body: 'Scheduled: $dateText at $fromTimeText - $toTimeText.',
          payload: 'lessons',
        );
      }
      if (!onLessonView && isTrainee) {
        //save noti for trainee
        List<String> lessonNotifications = UserPreferences.instance
                .getStringList(
                    NotificationsChangesHandler.lessonsNotifier.getKey()) ??
            [];
        lessonNotifications.add(lesson.id!);
        await NotificationsChangesHandler.lessonsNotifier
            .updateValue(lessonNotifications);
      }
      //add scheduled notification for both
      var dateReminder = fromDate.subtract(const Duration(minutes: 15));
      if (dateReminder
          .isBefore(DateTime.now().add(const Duration(minutes: 15)))) {
        dateReminder = fromDate;
      }
      if (dateReminder.isAfter(DateTime.now())) {
        await NotificationsApi.showScheduledNotification(
          id: int.parse(lesson.id!),
          scheduledDate: dateReminder,
          title: "Upcoming Lesson '${lesson.title!}'",
          body: 'Today from $fromTimeText until $toTimeText.',
          payload: 'lessons',
        );
      }
    }
  }

  static Future handleLessonEdit(DocumentChange<Lesson> docChange) async {
    final lesson = docChange.doc.data()!;
    bool isTrainee = AppUser.currentUser!.id! == lesson.traineeID!;
    bool onLessonView =
        UserPreferences.instance.getBool('onLessonView') ?? false;
    if (!lesson.isComplete!) {
      final fromDate = lesson.date!;
      final fromTimeText = DateFormat.jm().format(fromDate);
      final toDate = DateTime(fromDate.year, fromDate.month, fromDate.day,
          fromDate.hour + lesson.duration!, fromDate.minute);
      final toTimeText = DateFormat.jm().format(toDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final aDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final dateText = aDate == today
          ? 'Today'
          : aDate == yesterday
              ? 'Yesterday'
              : aDate == tomorrow
                  ? 'Tomorrow'
                  : DateFormat.yMEd().format(fromDate);
      if (isTrainee) {
        //notify trainee
        await NotificationsApi.showNotification(
          title: "Lesson Modified '${lesson.title!}'",
          body: 'Scheduled: $dateText at $fromTimeText - $toTimeText.',
          payload: 'lessons',
        );
      }
      if (!onLessonView && isTrainee) {
        //save noti for trainee
        List<String> lessonNotifications = UserPreferences.instance
                .getStringList(
                    NotificationsChangesHandler.lessonsNotifier.getKey()) ??
            [];
        lessonNotifications.add(lesson.id!);
        await NotificationsChangesHandler.lessonsNotifier
            .updateValue(lessonNotifications);
      }
      //add scheduled notification for both
      var dateReminder = fromDate.subtract(const Duration(minutes: 15));
      if (dateReminder
          .isBefore(DateTime.now().add(const Duration(minutes: 15)))) {
        dateReminder = fromDate;
      }
      if (dateReminder.isAfter(DateTime.now())) {
        await NotificationsApi.notifications.cancel(int.parse(lesson.id!));
        await NotificationsApi.showScheduledNotification(
          id: int.parse(lesson.id!),
          scheduledDate: dateReminder,
          title: "Upcoming Lesson '${lesson.title!}'",
          body: 'Today from $fromTimeText until $toTimeText.',
          payload: 'lessons',
        );
      }
    }
  }

  static Future handleMessages(Message message) async {
    if (message.dateSent!.compareTo(date) > 0 &&
        message.userID! != AppUser.currentUser!.id &&
        message.userID! !=
            UserPreferences.instance.getString('isChattingWith')) {
      await NotificationsApi.showNotification(
        title: 'New Message',
        body: '${message.userType} ${message.userName}: ${message.message}',
        payload: 'chats',
      );
      //update value notifier
      List<String> chatNotifications = UserPreferences.instance.getStringList(
              NotificationsChangesHandler.chatsNotifier.getKey()) ??
          [];
      chatNotifications.add(message.userID!);
      await NotificationsChangesHandler.chatsNotifier
          .updateValue(chatNotifications);
      date = DateTime.now();
    }
  }

  static Query<Message> getMessages(String id) {
    Query query =
        FirebaseFirestore.instance.collection('requests/$id/messages');
    query = query.orderBy('dateSent', descending: true).limit(1);

    return query.withConverter(
        fromFirestore: (snapshot, _) => Message.fromJson(snapshot.data()!),
        toFirestore: (message, _) => message.toJson());
  }

  static Query<Request> getRequests() {
    Query query = FirebaseFirestore.instance.collection('requests');
    if (AppUser.currentUser!.type! == 'Instructor') {
      query = query.where('receiverID', isEqualTo: AppUser.currentUser!.id);
      return query.orderBy('dateSent', descending: true).withConverter(
          fromFirestore: (snapshot, _) => Request.fromJson(snapshot.data()!),
          toFirestore: (request, _) => request.toJsonReceiver());
    } else {
      query = query.where('senderID', isEqualTo: AppUser.currentUser!.id);
      return query.withConverter(
          fromFirestore: (snapshot, _) => Request.fromJson(snapshot.data()!),
          toFirestore: (request, _) => request.toJsonReceiver());
    }
  }

  static Query<Lesson> getLessons(String id) {
    Query query = FirebaseFirestore.instance.collection('requests/$id/lessons');
    query = query.orderBy('date');
    return query.withConverter(
        fromFirestore: (snapshot, _) => Lesson.fromJson(snapshot.data()!),
        toFirestore: (lesson, _) => lesson.toJson());
  }

  static DocumentReference<AppUser> getUserDoc() {
    final id = AppUser.currentUser!.id;
    final doc = FirebaseFirestore.instance.collection('users').doc(id);
    return doc.withConverter(
      fromFirestore: (snapshot, options) => AppUser.fromJson(snapshot.data()!),
      toFirestore: (user, options) => user.toJson(),
    );
  }

  static CollectionReference<Review> getReviewCollection() {
    final id = AppUser.currentUser!.id;
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .collection('reviews');
    return collection.withConverter(
      fromFirestore: (snapshot, _) => Review.fromJson(snapshot.data()!),
      toFirestore: (review, _) => review.toJson(),
    );
  }
}
