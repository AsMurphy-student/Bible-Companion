import 'package:flutter/material.dart';

class PageChecklist extends StatefulWidget {

  const PageChecklist({super.key});

  @override
  State<PageChecklist> createState() => _PageChecklistState();
}

class _PageChecklistState extends State<PageChecklist> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(child: Column(
        children: [
          Text('checklist'),
        ],
      )),
    );
  }
}