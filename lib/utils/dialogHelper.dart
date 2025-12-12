import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// This is a dialog helper function
// which create a simple dialog
void alertDialog(
  BuildContext context, // Buildcontext
  String title, // Title of the dialog
  String message, // message under the dialog
  String buttonMessage, // button message/text
  bool forceExit, // bool of whether to force exit app or not
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
              Navigator.pop(context);
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
