import 'package:biblereader/settingsComponents/translationdropdown.dart';
import 'package:flutter/material.dart';

class PageSettings extends StatefulWidget {
  final VoidCallback getBooksAndChapters;

  const PageSettings({super.key, required this.getBooksAndChapters});

  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(child: Column(
        children: [
          Translationdropdown(getBooksAndChapters: widget.getBooksAndChapters,),
        ],
      )),
    );
  }
}