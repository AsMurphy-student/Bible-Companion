import 'dart:convert';

import 'package:biblereader/functions/saveValue.dart';
import 'package:biblereader/utils/dialogHelper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// This class is for the translation dropdown in settings
class Translationdropdown extends StatefulWidget {
  // This parameter function is for getting bible data
  final VoidCallback getBooksAndChapters;

  const Translationdropdown({super.key, required this.getBooksAndChapters});

  @override
  State<Translationdropdown> createState() => _TranslationdropdownState();
}

class _TranslationdropdownState extends State<Translationdropdown> {
  // We initialize chosentranslation with a default value
  // and a translation codes list for the dropdown values that can be chosen
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

  // This function gets translation codes to populate dropdown
  Future<void> getTranslations(String fetchURL) async {
    try {
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
        'Unable to populate translation dropdown.',
        'Ok',
        false,
      );
    }
  }

  // Init prefs and populate translation dropdown
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
            // Alert dialog informing that fetching takes some time
            alertDialog(
              context,
              'Fetching Data can take a while.',
              'Be aware that fetching data can take a while to complete.',
              'Ok',
              false,
            );

            // Set new chosen translation and get translation data
            setState(() {
              chosenTranslation = newValue!;
              saveValue('chosenTranslation', newValue, prefs);
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
