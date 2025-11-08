import 'package:flutter/material.dart';

List<Widget> getContentWidgets(List<dynamic> data) {
  List<Widget> newWidgets = [];
  for (int i = 0; i < data.length; i++) {
    if (data[i]['type'] == 'heading') {
      if (i > 0) {
        newWidgets.add(SizedBox(height: 30));
      }
      newWidgets.add(
        Text(
          data[i]['content'].whereType<String>().join(' '),
          style: TextStyle(fontSize: 30),
        ),
      );
      if (i < data.length - 1) {
        newWidgets.add(SizedBox(height: 30));
      }
    } else if (data[i]['type'] == 'verse') {
      String verse = '';
      for (int v = 0; v < data[i]['content'].length; v++) {
        if (data[i]['content'][v] is String) {
          if (v > 0 && data[i]['content'][v - 1] is String) {
            verse += " ${data[i]['content'][v].toString()}";
          } else {
            verse += data[i]['content'][v].toString();
          }
        } else {
          verse += '\n';
        }
      }

      newWidgets.add(
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: data[i]['number'].toString(),
                style: TextStyle(
                  fontSize: 12,
                  textBaseline: TextBaseline.ideographic,
                ),
              ),
              WidgetSpan(child: SizedBox(width: 4)),
              TextSpan(text: verse, style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }
  }
  return newWidgets;
}
