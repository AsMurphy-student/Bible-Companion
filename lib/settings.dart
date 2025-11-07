import 'package:biblereader/settingsComponents/translationdropdown.dart';
import 'package:flutter/material.dart';

class PageSettings extends StatefulWidget {
  const PageSettings({super.key});

  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.purple[50],
      child: Center(child: Column(
        children: [
          Translationdropdown(),
        ],
      )),
    );
  }
}