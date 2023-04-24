// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String? id;
  final String? title;
  final String? instructorID;
  final String? traineeID;
  final String? requestID;
  DateTime? dateCreated;
  DateTime? date;
  bool? isComplete;
  bool? isPickup;
  int? duration;

  Lesson({
    this.id,
    this.title,
    this.instructorID,
    this.traineeID,
    this.requestID,
    this.dateCreated,
    this.date,
    this.isComplete,
    this.isPickup,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'instructorID': instructorID,
        'traineeID': traineeID,
        'requestID': requestID,
        'dateCreated': DateTime.now(),
        'date': date,
        'isComplete': isComplete,
        'isPickup': isPickup,
        'duration': duration,
      };

  static Lesson fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'],
        title: json['title'],
        instructorID: json['instructorID'],
        traineeID: json['traineeID'],
        requestID: json['requestID'],
        dateCreated: (json['date'] as Timestamp).toDate(),
        date: (json['date'] as Timestamp).toDate(),
        isComplete: json['isComplete'],
        isPickup: json['isPickup'],
        duration: json['duration'],
      );
}
