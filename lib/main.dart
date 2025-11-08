import 'dart:convert';

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
    return const MaterialApp(
      home: HomePage(),
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

    getBooks(
      'https://bible.helloao.org/api/${prefs.getString('chosenTranslation') ?? "BSB"}/books.json',
    );
  }

  Future<void> saveValue(String key, dynamic value) async {
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> getBooks(String fetchURL) async {
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
      getChapterData(
        'https://bible.helloao.org/api/${prefs.getString('chosenTranslation') ?? "BSB"}/${bookIDs[currentBook]}/${currentChapter + 1}.json',
      );
    } else {
      print("Theres a problem: ${response.statusCode}");
    }
  }

  Future<void> getChapterData(String fetchURL) async {
    // Get response and assign variables accordingly
    var response = await http.get(Uri.parse(fetchURL));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['chapter']['content'];

      List<Widget> newWidgets = [];
      setState(() {
        for (int i = 0; i < data.length; i++) {
          if (data[i]['type'] == 'heading') {
            if (i > 0) {
              newWidgets.add(SizedBox(height: 30));
            }
            newWidgets.add(
              Text(
                data[i]['content'].whereType<String>().join(' '),
                style: TextStyle(fontSize: 30),
              ),
            );
            if (i < data.length - 1) {
              newWidgets.add(SizedBox(height: 30));
            }
          } else if (data[i]['type'] == 'verse') {
            String verse = '';
            for (int v = 0; v < data[i]['content'].length; v++) {
              if (data[i]['content'][v] is String) {
                if (v > 0) {
                  verse += " ${data[i]['content'][v].toString()}";
                } else {
                  verse += data[i]['content'][v].toString();
                }
              } else {
                verse += '\n';
              }
            }

            newWidgets.add(
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: data[i]['number'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        textBaseline: TextBaseline.ideographic,
                      ),
                    ),
                    WidgetSpan(child: SizedBox(width: 4)),
                    TextSpan(text: verse, style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              // Text(data[i]['content'].whereType<String>().join(' ')),
            );
          }
        }
        chapterWidgets = newWidgets;
        print(chapterWidgets);
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
    PageSettings(),
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
              getChapterData(
                'https://bible.helloao.org/api/${prefs.getString('chosenTranslation') ?? "BSB"}/${bookIDs[currentBook]}/${currentChapter + 1}.json',
              );
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
                  getChapterData(
                    'https://bible.helloao.org/api/${prefs.getString('chosenTranslation') ?? "BSB"}/${bookIDs[currentBook]}/${currentChapter + 1}.json',
                  );
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
                  getChapterData(
                    'https://bible.helloao.org/api/${prefs.getString('chosenTranslation') ?? "BSB"}/${bookIDs[currentBook]}/${currentChapter + 1}.json',
                  );
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
            backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
            backgroundColor: Colors.green,
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
