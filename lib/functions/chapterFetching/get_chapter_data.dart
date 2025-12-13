import 'dart:convert';
import 'package:biblereader/utils/dialogHelper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Helper function to fetch specific chapter data
Future<List<dynamic>> getChapterData(
  String translation, // Translation code
  String bookID, // BookID to fetch
  int chapter, // Specific chapter to query
  BuildContext context, // BuildContext
) async {
  try {
    String fetchURL =
        'https://bible.helloao.org/api/$translation/$bookID/$chapter.json';
    // Get response and assign variables accordingly
    http.Response response = await http.get(Uri.parse(fetchURL));
    if (response.statusCode != 200) {
      // Catch error and alert user
      alertDialog(
        context.mounted ? context : context,
        'No internet or some other error.',
        'Return status code: ${response.statusCode}',
        'Ok',
        false,
      );
    }
    // Get data and return it
    dynamic jsonResponse = jsonDecode(response.body);
    List<dynamic> data = jsonResponse['chapter']['content'];
    return data;
  } catch (e) {
    // Catch error and alert user as this will stop runtime
    // This error should most likely never happen
    alertDialog(
      context.mounted ? context : context,
      'No internet or some other error.',
      'Error Message: $e',
      'Ok',
      false,
    );
    // Rethrow needed for compiling
    rethrow;
  }
}