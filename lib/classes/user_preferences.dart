import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static SharedPreferences instance = instance;
  static Future init() async {
    instance = await SharedPreferences.getInstance();
  }
}
