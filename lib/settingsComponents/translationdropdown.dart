import 'dart:convert';

import 'package:biblereader/utils/dialogHelper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Translationdropdown extends StatefulWidget {
  final VoidCallback getBooksAndChapters;

  const Translationdropdown({super.key, required this.getBooksAndChapters});

  @override
  State<Translationdropdown> createState() => _TranslationdropdownState();
}

class _TranslationdropdownState extends State<Translationdropdown> {
  String chosenTranslation = 'BSB';
  List<String> translationCodes = [];

  // Prefs
  late SharedPreferences prefs;
  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('chosenTranslation') != null) {
        chosenTranslation = prefs.getString('chosenTranslation')!;
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

  Future<void> getTranslations(String fetchURL) async {
    // Get response and assign variables accordingly
    var response = await http.get(Uri.parse(fetchURL));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['translations'];
      List<dynamic> filteredData = data
          .where(
            (object) =>
                object['language'] == 'eng' && object['numberOfBooks'] == 66,
          )
          .toList();

      setState(() {
        translationCodes = filteredData
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
    getTranslations(
      'https://bible.helloao.org/api/available_translations.json',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Translation:"),
        DropdownButton<String>(
          value: chosenTranslation,
          icon: Icon(Icons.arrow_downward),
          disabledHint: Text('Unable to get Translations'),
          onChanged: (String? newValue) {
            alertDialog(
              context,
              'Fetching Data can take a while.',
              'Be aware that fetching data can take a while to complete.',
              'Ok',
              false,
            );
            
            setState(() {
              chosenTranslation = newValue!;
              saveValue('chosenTranslation', newValue);
              widget.getBooksAndChapters();
            });
          },
          items: translationCodes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ],
    );
  }
}
