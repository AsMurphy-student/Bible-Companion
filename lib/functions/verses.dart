import 'package:flutter/material.dart';

// This function gets content widgets based off of the data passed through
// This is used for both bible data and commentary data
// This function is incredibly useful to construct the right widgets needed in
// the bible page and commentary page
List<Widget> getContentWidgets(
  List<dynamic>? data, // List of data to utilize (bible or commentary)
  BuildContext context, // Build Context
  bool isVerses, // Boolean to put verse numbers in front or not
) {
  List<Widget> newWidgets = [];

  // If there is no data at all
  // Have a default page put in stating there is no data
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

  // For each content object
  // Add widget(s) based on type in return response
  for (int i = 0; i < data.length; i++) {
    // Heading Type
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
    // Verse Type
    } else if (data[i]['type'] == 'verse') {
      String verse = '';
      // Loop through if there are multiple lines to create the verse string
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

      // Add in verses object
      // With verse number or not
      newWidgets.add(
        RichText(
          text: TextSpan(
            children: [
              if (isVerses)
                TextSpan(
                  text: data[i]['number'].toString(),
                  // textTheme utilized from theme object
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    textBaseline: TextBaseline.ideographic,
                  ),
                ),
              // Spacer
              WidgetSpan(child: SizedBox(width: 4)),
              TextSpan(
                text: verse,
                // textTheme utilized from theme object
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
  // When done looping return our chapter widgets
  return newWidgets;
}
