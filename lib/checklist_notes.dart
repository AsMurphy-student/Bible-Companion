import 'package:flutter/material.dart';

class PageChecklistNotes extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final String inputHint;

  const PageChecklistNotes({
    super.key,
    required this.controller,
    required this.title,
    required this.inputHint,
  });

  @override
  State<PageChecklistNotes> createState() => _PageChecklistNotesState();
}

class _PageChecklistNotesState extends State<PageChecklistNotes> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          children: [
            Text(widget.title, style: TextStyle(fontSize: 30)),
            TextField(
              controller: widget.controller,
              keyboardType: TextInputType.multiline,
              minLines: 10,
              maxLines: null,
              decoration: InputDecoration(border: OutlineInputBorder(), hint: Text(widget.inputHint)),
            ),
          ],
        ),
      ),
    );
  }
}
