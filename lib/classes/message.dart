// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? userID;
  final String? userName;
  final String? userType;
  final String? message;
  final DateTime? dateSent;

  Message({
    this.userID,
    this.userName,
    this.userType,
    this.message,
    this.dateSent,
  });

  Map<String, dynamic> toJson() => {
        'userID': userID,
        'userName': userName,
        'userType': userType,
        'message': message,
        'dateSent': dateSent,
      };

  static Message fromJson(Map<String, dynamic> json) => Message(
        userID: json['userID'],
        userName: json['userName'],
        userType: json['userType'],
        message: json['message'],
        dateSent: (json['dateSent'] as Timestamp).toDate(),
      );
}
