import 'package:flutter/material.dart';

List<Widget> getContentWidgets(
  List<dynamic>? data,
  BuildContext context,
  bool isVerses,
) {
  List<Widget> newWidgets = [];

  if (data == null) {
    newWidgets.add(
      RichText(
        text: TextSpan(
          children: [
            WidgetSpan(child: SizedBox(width: 4)),
            TextSpan(
              text:
                  "No Data Found! There was no data found for this chapter from the commentary source.",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 32, height: 2.0),
            ),
          ],
        ),
      ),
    );
    return newWidgets;
  }

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
        } else if (data[i]['content'][v]['text'] != null &&
            data[i]['content'][v]['text'] is String) {
          verse += data[i]['content'][v]['text'];
        }
      }

      newWidgets.add(
        RichText(
          text: TextSpan(
            children: [
              if (isVerses)
                TextSpan(
                  text: data[i]['number'].toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    textBaseline: TextBaseline.ideographic,
                  ),
                ),
              WidgetSpan(child: SizedBox(width: 4)),
              TextSpan(
                text: verse,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 18, height: 2.0),
              ),
            ],
          ),
        ),
      );
    }
  }
  return newWidgets;
}
