import 'package:biblereader/settingsComponents/commentarydropdown.dart';
import 'package:biblereader/settingsComponents/translationdropdown.dart';
import 'package:flutter/material.dart';

class PageSettings extends StatefulWidget {
  final VoidCallback getBooksAndChapters;
  final VoidCallback getCommentary;

  const PageSettings({super.key, required this.getBooksAndChapters, required this.getCommentary});

  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          children: [
            Translationdropdown(
              getBooksAndChapters: widget.getBooksAndChapters,
            ),
            Commentarydropdown(
              getCommentary: widget.getCommentary,
            )
          ],
        ),
      ),
    );
  }
}
