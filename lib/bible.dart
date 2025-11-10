import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PageHome extends StatefulWidget {
  final List<Widget>? chapterWidgets;

  const PageHome({super.key, required this.chapterWidgets});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  // Prefs
  late SharedPreferences prefs;
  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      // if (prefs.getInt('currentBottomTab') != null) {
      //   currentBottomTab = prefs.getInt('currentBottomTab')!;
      // }
    });
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: widget.chapterWidgets ?? [],
        ),
      )
    );
  }
}
