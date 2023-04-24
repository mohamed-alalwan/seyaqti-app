// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String? instructorID;
  final String? traineeID;
  final String? displayName;
  String? title;
  String? comment;
  double? rating;
  String? imageURL;
  DateTime? dateUpdated;

  Review({
    this.instructorID,
    this.traineeID,
    this.displayName,
    this.title,
    this.comment,
    this.rating,
    this.imageURL,
    this.dateUpdated,
  });

  Map<String, dynamic> toJson() => {
        'traineeID': traineeID,
        'instructorID': instructorID,
        'displayName': displayName,
        'title': title,
        'comment': comment,
        'rating': rating,
        'imageURL': imageURL,
        'dateUpdated': DateTime.now(),
      };

  static Review fromJson(Map<String, dynamic> json) => Review(
        traineeID: json['traineeID'],
        instructorID: json['instructorID'],
        displayName: json['displayName'],
        title: json['title'],
        comment: json['comment'],
        rating: json['rating'],
        imageURL: json['imageURL'],
        dateUpdated: (json['dateUpdated'] as Timestamp).toDate(),
      );
}
