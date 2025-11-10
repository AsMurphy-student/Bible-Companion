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
      if (prefs.getInt('currentBook') != null) {
        currentBook = prefs.getInt('currentBook')!;
      }
      if (prefs.getInt('currentChapter') != null) {
        currentChapter = prefs.getInt('currentChapter')!;
      }
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
    String fetchURL =
        'https://bible.helloao.org/api/${prefs.getString('chosenTranslation') ?? "BSB"}/books.json';
    // Get response and assign variables accordingly
    var response = await http.get(Uri.parse(fetchURL));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['books'];

      setState(() {
        bookIDs = data.map((element) => element['id'].toString()).toList();
        bookChapterCounts = data
            .map((element) => int.parse(element['numberOfChapters'].toString()))
            .toList();
      });
      getChapterData();
    } else {
      print("Theres a problem: ${response.statusCode}");
    }
  }

  Future<void> getChapterData() async {
    String fetchURL =
        'https://bible.helloao.org/api/${prefs.getString('chosenTranslation') ?? "BSB"}/${bookIDs[currentBook]}/${currentChapter + 1}.json';
    // Get response and assign variables accordingly
    var response = await http.get(Uri.parse(fetchURL));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['chapter']['content'];

      setState(() {
        chapterWidgets = getContentWidgets(data, context);
      });

      // setState(() {
      //   chapterWidgets = chapterData
      //       .map((content) => {Text('hello')})
      //       .cast<Widget>()
      //       .toList();
      //   print(chapterWidgets);
      // });
      // setState(() {
      //   bookIDs = data.map((element) => element['id'].toString()).toList();
      //   bookChapterCounts = data
      //       .map((element) => int.parse(element['numberOfChapters'].toString()))
      //       .toList();
      // });
    } else {
      print("Theres a problem: ${response.statusCode}");
    }
  }

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  int currentBottomTab = 0;
  int currentBook = 0;
  int currentChapter = 0;
  List<String> bookIDs = [];
  List<int> bookChapterCounts = [];
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
          "${bookIDs.isNotEmpty ? bookIDs[currentBook] : 'Fetching IDs'} ${currentChapter + 1}",
        ),
        leading: DropdownButton<String>(
          isExpanded: true,
          value: bookIDs.isNotEmpty ? bookIDs[currentBook] : 'GEN',
          icon: Icon(Icons.arrow_downward),
          onChanged: (String? newValue) {
            setState(() {
              currentBook = bookIDs.indexOf(newValue!);
              saveValue('currentBook', bookIDs.indexOf(newValue));
              currentChapter = 0;
              saveValue('currentChapter', currentChapter);
              getChapterData();
            });
          },
          items: bookIDs.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                if (currentChapter > 0) {
                  currentChapter -= 1;
                  saveValue('currentChapter', currentChapter);
                  getChapterData();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              setState(() {
                if (currentChapter <
                    (bookChapterCounts.isNotEmpty
                        ? bookChapterCounts[currentBook] - 1
                        : 1)) {
                  currentChapter += 1;
                  saveValue('currentChapter', currentChapter);
                  getChapterData();
                }
              });
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
