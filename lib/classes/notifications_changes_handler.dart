import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:seyaqti_app/classes/user_preferences.dart';

class NotificationsChangesHandler {
  static const String chats = 'chatNotifications';
  static const String requests = 'requestNotifications';
  static const String lessons = 'lessonNotifications';

  static NotificationsNotifier chatsNotifier = NotificationsNotifier(
    UserPreferences.instance.getStringList(
      FirebaseAuth.instance.currentUser!.uid + chats,
    ),
    chats,
    FirebaseAuth.instance.currentUser!.uid,
  );

  static NotificationsNotifier requestsNotifier = NotificationsNotifier(
    UserPreferences.instance.getStringList(
      FirebaseAuth.instance.currentUser!.uid + requests,
    ),
    requests,
    FirebaseAuth.instance.currentUser!.uid,
  );

  static NotificationsNotifier lessonsNotifier = NotificationsNotifier(
    UserPreferences.instance.getStringList(
      FirebaseAuth.instance.currentUser!.uid + lessons,
    ),
    lessons,
    FirebaseAuth.instance.currentUser!.uid,
  );
}

class NotificationsNotifier extends ValueNotifier {
  String key;
  String userID;
  NotificationsNotifier(List<String>? super.value, this.key, this.userID);

  updateValue(List<String> value) async {
    await UserPreferences.instance.setStringList(getKey(), value);
    this.value = UserPreferences.instance.getStringList(getKey());
  }

  String getKey() => userID + key;
}
