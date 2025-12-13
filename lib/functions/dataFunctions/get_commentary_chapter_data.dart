import 'dart:convert';
import 'package:biblereader/utils/dialogHelper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// getCommentaryChapterData helper function
Future<List<dynamic>?> getCommentaryChapterData(
  String commentaryID, // commentary ID to fetch
  String bookID, // bible ID to fetch
  int chapter, // chapter to fetch
  BuildContext context, // BuildContext
) async {
  try {
    String fetchURL =
        'https://bible.helloao.org/api/c/$commentaryID/$bookID/$chapter.json';
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
    // Return data once fetched and parsed
    dynamic jsonResponse = jsonDecode(response.body);
    List<dynamic> data = jsonResponse['chapter']['content'];
    return data;
  } catch (e) {
    // Null is return when no commentary for a chapter is given
    // print('Error with $bookID $chapter: $e');
    return null;
  }
}
