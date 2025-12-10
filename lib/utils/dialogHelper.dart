import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void alertDialog(
  BuildContext context,
  String title,
  String message,
  String buttonMessage,
  bool forceExit,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Closes the dialog
              if (forceExit) {
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              }
            },
            child: Text(buttonMessage),
          ),
        ],
      );
    },
  );
}