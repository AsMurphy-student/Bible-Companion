import 'package:flutter/material.dart';

class PageNotes extends StatefulWidget {

  const PageNotes({super.key});

  @override
  State<PageNotes> createState() => _PageNotesState();
}

class _PageNotesState extends State<PageNotes> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(child: Column(
        children: [
          Text('notes'),
        ],
      )),
    );
  }
}