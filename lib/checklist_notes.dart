import 'package:flutter/material.dart';

// This class is for both
// checklist and notes as they are both similar
class PageChecklistNotes extends StatefulWidget {
  // We have parameters for the controller for the text field
  final TextEditingController controller;
  // The title of the page
  final String title;
  // And the input hint on the text field to use
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
            // Text field with Title
            Text(widget.title, style: TextStyle(fontSize: 30)),
            TextField(
              controller: widget.controller,
              keyboardType: TextInputType.multiline,
              minLines: 10,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hint: Text(widget.inputHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
