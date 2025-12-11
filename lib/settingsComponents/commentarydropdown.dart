import 'dart:convert';

import 'package:biblereader/utils/dialogHelper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Commentarydropdown extends StatefulWidget {
  final VoidCallback getCommentary;

  const Commentarydropdown({super.key, required this.getCommentary});

  @override
  State<Commentarydropdown> createState() => _CommentarydropdownState();
}

class _CommentarydropdownState extends State<Commentarydropdown> {
  String chosenCommentary = 'jamieson-fausset-brown';
  List<String> commentaryCodes = [];

  // Prefs
  late SharedPreferences prefs;
  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('chosenCommentary') != null) {
        chosenCommentary = prefs.getString('chosenCommentary')!;
      }
    });
  }

  Future<void> saveValue(String key, dynamic value) async {
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> getCommentaries(String fetchURL) async {
    // Get response and assign variables accordingly
    var response = await http.get(Uri.parse(fetchURL));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['commentaries'];
      List<dynamic> filteredData = data
          .where(
            (object) =>
                object['language'] == 'eng',
          )
          .toList();

      setState(() {
        commentaryCodes = filteredData
            .map((translation) => translation['id'].toString())
            .toList();
      });
    } else {
      print("Theres a problem: ${response.statusCode}");
    }
  }

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
        Text("Translation:"),
        DropdownButton<String>(
          value: chosenCommentary,
          icon: Icon(Icons.arrow_downward),
          disabledHint: Text('Unable to get Commentaries'),
          onChanged: (String? newValue) {
            alertDialog(
              context,
              'Fetching Data can take a while.',
              'Be aware that fetching data can take a while to complete.',
              'Ok',
              false,
            );
            
            setState(() {
              chosenCommentary = newValue!;
              saveValue('chosenCommentary', newValue);
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
