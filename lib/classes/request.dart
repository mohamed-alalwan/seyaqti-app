// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String? senderID;
  final String? receiverID;
  DateTime? dateSent;
  bool? approval;

  Request({
    this.senderID,
    this.receiverID,
    this.approval,
    this.dateSent,
  });

  Map<String, dynamic> toJsonReceiver() => {
        'receiverID': receiverID,
        'senderID': senderID,
        'dateSent': dateSent,
        'approval': approval,
      };

  Map<String, dynamic> toJsonSender() => {
        'senderID': senderID,
        'receiverID': receiverID,
        'dateSent': dateSent,
      };

  static Request fromJson(Map<String, dynamic> json) => Request(
        receiverID: json['receiverID'],
        senderID: json['senderID'],
        dateSent: (json['dateSent'] as Timestamp).toDate(),
        approval: json['approval'],
      );
}
