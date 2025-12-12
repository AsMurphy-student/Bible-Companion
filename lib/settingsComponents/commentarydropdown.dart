import 'dart:convert';

import 'package:biblereader/functions/saveValue.dart';
import 'package:biblereader/utils/dialogHelper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// This class is for the commentary dropdown in settings
class Commentarydropdown extends StatefulWidget {
  // Parameter for the get commentary function to call from main
  final VoidCallback getCommentary;

  const Commentarydropdown({super.key, required this.getCommentary});

  @override
  State<Commentarydropdown> createState() => _CommentarydropdownState();
}

class _CommentarydropdownState extends State<Commentarydropdown> {
  // Set default commentary if none is stored in prefs
  // and declare commentarycodes array which populates the dropdown choices
  String chosenCommentary = 'jamieson-fausset-brown';
  List<String> commentaryCodes = [];

  // Prefs
  late SharedPreferences prefs;
  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      // If a chosen commentary is stored
      // Fetch it and override default
      if (prefs.getString('chosenCommentary') != null) {
        chosenCommentary = prefs.getString('chosenCommentary')!;
      }
    });
  }

  // This async function gets the available commentaries
  // to populate the dropdown menu
  Future<void> getCommentaries(String fetchURL) async {
    try {
      // Get response and assign variables accordingly
      var response = await http.get(Uri.parse(fetchURL));

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> data = jsonResponse['commentaries'];
        List<dynamic> filteredData = data
            .where((object) => object['language'] == 'eng')
            .toList();

        setState(() {
          commentaryCodes = filteredData
              .map((translation) => translation['id'].toString())
              .toList();
        });
      } else {
        // Alert dialogs to catch errors from api
        alertDialog(
          context,
          'No internet or some other error.',
          'Return status code: ${response.statusCode}',
          'Ok',
          false,
        );
      }
    } catch (e) {
      alertDialog(
        context,
        'No internet or some other error.',
        'Unable to populate commentary dropdown.',
        'Ok',
        false,
      );
    }
  }

  // Init prefs and populate commentary dropdown
  @override
  void initState() {
    super.initState();
    initPrefs();
    getCommentaries(
      'https://bible.helloao.org/api/available_commentaries.json',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Commentary:"),
        DropdownButton<String>(
          value: chosenCommentary,
          icon: Icon(Icons.arrow_downward),
          // When no codes are available due to internet
          // A disabled hint is displayed
          disabledHint: Text('Unable to get Commentaries'),
          onChanged: (String? newValue) {
            // An alert dialog is given informing the user 
            // that fetching takes a while
            alertDialog(
              context,
              'Fetching Data can take a while.',
              'Be aware that fetching data can take a while to complete.',
              'Ok',
              false,
            );

            // When new commentary is chosen
            // We updated and save the value
            // and call our passed in function
            setState(() {
              chosenCommentary = newValue!;
              saveValue('chosenCommentary', newValue, prefs);
              widget.getCommentary();
            });
          },
          items: commentaryCodes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ],
    );
  }
}
