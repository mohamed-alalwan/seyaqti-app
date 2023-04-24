// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seyaqti_app/extensions/string_casing_extension.dart';

class AppUser {
  static AppUser? currentUser;
  final String? id;
  final String? gender;
  final DateTime? birthday;
  final String? type;
  String? city;
  double? mapLatitude;
  double? mapLongitude;
  String? firstName;
  String? lastName;
  int? experienceYears;
  String? phoneNumber;
  String? carMake;
  String? carModel;
  int? carYear;
  String? transmissionType;
  String? imageURL;
  String? carURL;
  num? ratingAverage;
  num? ratingCount;

  AppUser({
    this.id,
    this.firstName,
    this.lastName,
    this.gender,
    this.birthday,
    this.type,
    this.city,
    this.mapLatitude,
    this.mapLongitude,
    this.experienceYears,
    this.phoneNumber,
    this.carMake,
    this.carModel,
    this.carYear,
    this.transmissionType,
    this.imageURL,
    this.carURL,
    this.ratingAverage,
    this.ratingCount,
  });

  String calculateAge() {
    DateTime? birthday = this.birthday;
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthday!.year;
    int month1 = currentDate.month;
    int month2 = birthday.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthday.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age.toString();
  }

  String? fullName() {
    if (firstName == null || lastName == null) return null;
    String fullName =
        '${firstName!.toCapitalized()} ${lastName!.toCapitalized()}';
    return fullName;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'firstName': firstName?.toLowerCase().toCapitalized(),
        'lastName': lastName?.toLowerCase().toCapitalized(),
        'gender': gender,
        'birthday': birthday,
        'city': city,
        'mapLatitude': mapLatitude,
        'mapLongitude': mapLongitude,
        'experienceYears': experienceYears,
        'phoneNumber': phoneNumber,
        'carMake': carMake,
        'carModel': carModel,
        'carYear': carYear,
        'transmissionType': transmissionType,
        'imageURL': imageURL,
        'carURL': carURL,
        'ratingAverage': ratingAverage,
        'ratingCount': ratingCount,
      };

  static AppUser fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        gender: json['gender'],
        birthday: (json['birthday'] as Timestamp).toDate(),
        type: json['type'],
        city: json['city'],
        mapLatitude: json['mapLatitude'],
        mapLongitude: json['mapLongitude'],
        experienceYears: json['experienceYears'],
        phoneNumber: json['phoneNumber'],
        carMake: json['carMake'],
        carModel: json['carModel'],
        carYear: json['carYear'],
        transmissionType: json['transmissionType'],
        imageURL: json['imageURL'],
        carURL: json['carURL'],
        ratingAverage: json['ratingAverage'],
        ratingCount: json['ratingCount'],
      );
}
