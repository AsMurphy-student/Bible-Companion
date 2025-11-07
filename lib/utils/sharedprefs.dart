import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get instance async {
    // If preferences is null then get instance and return
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}
