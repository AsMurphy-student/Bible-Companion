import 'dart:convert';

import 'package:biblereader/functions/verses.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bible.dart';
import 'settings.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Prefs
  late SharedPreferences prefs;
  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getInt('currentBottomTab') != null) {
        currentBottomTab = prefs.getInt('currentBottomTab')!;
      }
      if (prefs.getString('currentBook') != null) {
        currentBook = prefs.getString('currentBook')!;
      }
      if (prefs.getInt('currentChapter') != null) {
        currentChapter = prefs.getInt('currentChapter')!;
      }
      // if (prefs.getString('bibleData') != null) {
      //   bibleData = json.decode(prefs.getString('bibleData')!);
      // } else {
      //   getBooks();
      // }
    });

    getBooks();
  }

  Future<void> saveValue(String key, dynamic value) async {
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> getBooks() async {
    String translation = prefs.getString('chosenTranslation') ?? "BSB";
    String fetchURL = 'https://bible.helloao.org/api/$translation/books.json';
    // Get response and assign variables accordingly
    var response = await http.get(Uri.parse(fetchURL));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> listOfBooks = jsonResponse['books'];

      List<String> bookIDs = listOfBooks
          .map((element) => element['id'].toString())
          .toList();
      List<int> bookChapterCounts = listOfBooks
          .map((element) => int.parse(element['numberOfChapters'].toString()))
          .toList();

      for (int b = 0; b < bookIDs.length; b++) {
        List<dynamic> bookData = [];
        for (int c = 0; c < bookChapterCounts[b]; c++) {
          bookData.add(await getChapterData(translation, bookIDs[b], c + 1));
        }
        bibleData[bookIDs[b]] = bookData;
      }
      setState(() {
        bibleData = bibleData;
      });
      // saveValue('bibleData', json.encode(bibleData));
    } else {
      print("Theres a problem: ${response.statusCode}");
    }
  }

  Future<List<dynamic>> getChapterData(
    String translation,
    String bookID,
    int chapter,
  ) async {
    try {
      String fetchURL =
          'https://bible.helloao.org/api/$translation/$bookID/$chapter.json';
      // Get response and assign variables accordingly
      var response = await http.get(Uri.parse(fetchURL));
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['chapter']['content'];

      return data;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  int currentBottomTab = 0;
  String currentBook = 'GEN';
  int currentChapter = 0;
  // List<String> bookIDs = [];
  // List<int> bookChapterCounts = [];
  var bibleData = <String, List<dynamic>>{};
  List<Widget> chapterWidgets = [];

  List<Widget> get bottomNavScreens => [
    PageHome(chapterWidgets: chapterWidgets),
    PageSettings(getBooksAndChapters: getBooks),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${bibleData.isNotEmpty ? currentBook : 'Fetching IDs'} ${currentChapter + 1}",
        ),
        // leading: DropdownButton<String>(
        //   isExpanded: true,
        //   value: bibleData.isNotEmpty ? currentBook : 'GEN',
        //   icon: Icon(Icons.arrow_downward),
        //   onChanged: (String? newValue) {
        //     setState(() {
        //       currentBook = newValue!;
        //       saveValue('currentBook', newValue);
        //       currentChapter = 0;
        //       saveValue('currentChapter', currentChapter);
        //       chapterWidgets = getContentWidgets(
        //         bibleData[currentBook]?[currentChapter],
        //         context,
        //       );
        //     });
        //   },
        //   items: bibleData.keys.map<DropdownMenuItem<String>>((String value) {
        //     return DropdownMenuItem<String>(value: value, child: Text(value));
        //   }).toList(),
        // ),
        actions: <Widget>[
          // IconButton(
          //   icon: Icon(Icons.arrow_back),
          //   onPressed: () {
          //     setState(() {
          //       if (currentChapter > 0) {
          //         currentChapter -= 1;
          //         saveValue('currentChapter', currentChapter);
          //         getChapterData();
          //       }
          //     });
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              // setState(() {
              //   if (currentChapter <
              //       (bookChapterCounts.isNotEmpty
              //           ? bookChapterCounts[currentBook] - 1
              //           : 1)) {
              //     currentChapter += 1;
              //     saveValue('currentChapter', currentChapter);
              //     getChapterData();
              //   }
              // });
              getBooks();
            },
          ),
        ],
      ),
      body: IndexedStack(index: currentBottomTab, children: bottomNavScreens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: currentBottomTab,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Bible",
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ],
        onTap: (value) {
          setState(() {
            currentBottomTab = value;
            saveValue('currentBottomTab', value);
          });
        },
      ),
    );
  }
}
