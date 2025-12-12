import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This is the page home class which display bible data
class PageHome extends StatefulWidget {
  // Parameter for list of content widgets to display
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
  }

  // Init prefs
  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      // Box Decoration usage for styling
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 8),
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      height: double.infinity,
      // List of content widgets
      child: ListView(children: widget.chapterWidgets ?? []),
    );
  }
}
