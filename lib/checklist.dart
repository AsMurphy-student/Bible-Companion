import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PageChecklist extends StatefulWidget {
  final TextEditingController controller;

  const PageChecklist({super.key, required this.controller});

  @override
  State<PageChecklist> createState() => _PageChecklistState();
}

class _PageChecklistState extends State<PageChecklist> {
  // Prefs
  late SharedPreferences prefs;
  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveValue(String key, dynamic value) async {
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }
  
  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          children: [
            Text('Reflection Checklist', style: TextStyle(fontSize: 30)),
            TextField(
              controller: widget.controller,
              keyboardType: TextInputType.multiline,
              minLines: 10,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
