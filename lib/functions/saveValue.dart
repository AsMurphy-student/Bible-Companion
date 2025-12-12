import 'package:shared_preferences/shared_preferences.dart';

// This is a global function used to save values into shared prefs
Future<void> saveValue(String key, dynamic value, SharedPreferences prefs) async {
  if (value is String) {
    await prefs.setString(key, value);
  } else if (value is int) {
    await prefs.setInt(key, value);
  }
}