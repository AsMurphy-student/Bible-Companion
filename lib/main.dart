import 'dart:convert';

import 'package:biblereader/checklist.dart';
import 'package:biblereader/functions/verses.dart';
import 'package:biblereader/notes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bible.dart';
import 'settings.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:archive/archive.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
          seedColor: Color(0x0fd45f2d),
          brightness: Brightness.light,
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0x0fd45f2d),
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
      if (prefs.getStringList('chapterNames') != null) {
        chapterNames = prefs.getStringList('chapterNames')!;
      }
      if (prefs.getString('bibleData') != null) {
        String bibleDataString = prefs.getString('bibleData')!;
        List<int> compressed = base64.decode(bibleDataString);
        List<int> bytes = GZipDecoder().decodeBytes(compressed);

        dynamic loadedBibleData;
        try {
          loadedBibleData = jsonDecode(utf8.decode(bytes));
          for (int b = 0; b < loadedBibleData.length; b++) {
            bibleData[loadedBibleData.keys.elementAt(b)] = loadedBibleData
                .values
                .elementAt(b);
          }
          setState(() {
            bibleData = bibleData;
            chapterWidgets = getContentWidgets(
              bibleData[currentBook]?[currentChapter],
              context,
            );
            bibleFetchingProgress = 1;
          });
        } catch (e) {
          print('Error decoding JSON: $e');
        }

        FlutterNativeSplash.remove();
      } else {
        print('getting books');
        getBooks();
      }
    });
    // print('getting books');
    // await getBooks();
    // print('got books');
    // chapterWidgets = getContentWidgets(
    //   bibleData[currentBook]?[currentChapter],
    //   context.mounted ? context : context,
    // );
    // print('set chapter widgets');
    // FlutterNativeSplash.remove();
  }

  Future<void> saveValue(String key, dynamic value) async {
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  Future<void> getBooks() async {
    setState(() {
      bibleFetchingProgress = 0;
    });
    String translation = prefs.getString('chosenTranslation') ?? "BSB";
    String fetchURL = 'https://bible.helloao.org/api/$translation/books.json';
    try {
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
        chapterNames = listOfBooks
            .map((element) => element['name'].toString())
            .toList();
        saveValue('chapterNames', chapterNames);

        for (int b = 0; b < bookIDs.length; b++) {
          List<dynamic> bookData = [];
          for (int c = 0; c < bookChapterCounts[b]; c++) {
            bookData.add(await getChapterData(translation, bookIDs[b], c + 1));
          }
          bibleData[bookIDs[b]] = bookData;
          if (bookIDs[b] == currentBook) {
            print('remove splash');
            setState(() {
              chapterWidgets = getContentWidgets(
                bibleData[currentBook]?[currentChapter],
                context.mounted ? context : context,
              );
            });
            FlutterNativeSplash.remove();
          }
          setState(() {
            bibleFetchingProgress = bibleData.length / bookIDs.length;
          });
          // print('Got ${bookIDs[b]}');
        }
        setState(() {
          bibleData = bibleData;
        });
        print('got books');
        List<int> bytes = utf8.encode(json.encode(bibleData));
        List<int> compressed = GZipEncoder().encode(bytes);
        saveValue('bibleData', base64.encode(compressed));
        print('saved bible');
        chapterWidgets = getContentWidgets(
          bibleData[currentBook]?[currentChapter],
          context.mounted ? context : context,
        );
        print('set chapter widgets');
        FlutterNativeSplash.remove();
      } else {
        print("Theres a problem: ${response.statusCode}");
      }
    } catch (e) {
      print(e);
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
      if (response.statusCode != 200) {
        print('error');
      }
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['chapter']['content'];

      return data;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<void> getCommentaryBooks() async {
    setState(() {
      commentaryFetchingProgress = 0;
    });
    // String translation = prefs.getString('chosenTranslation') ?? "BSB";
    String fetchURL = 'https://bible.helloao.org/api/c/tyndale/books.json';
    try {
      // Get response and assign variables accordingly
      var response = await http.get(Uri.parse(fetchURL));

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> listOfBooks = jsonResponse['book'];

        List<String> bookIDs = listOfBooks
            .map((element) => element['id'].toString())
            .toList();
        List<int> bookChapterCounts = listOfBooks
            .map((element) => int.parse(element['numberOfChapters'].toString()))
            .toList();

        for (int b = 0; b < bookIDs.length; b++) {
          List<dynamic> bookData = [];
          for (int c = 0; c < bookChapterCounts[b]; c++) {
            bookData.add(
              await getCommentaryChapterData('tyndale', bookIDs[b], c + 1),
            );
          }
          bibleData[bookIDs[b]] = bookData;
          if (bookIDs[b] == currentBook) {
            print('remove splash');
            setState(() {
              chapterWidgets = getContentWidgets(
                bibleData[currentBook]?[currentChapter],
                context.mounted ? context : context,
              );
            });
            FlutterNativeSplash.remove();
          }
          setState(() {
            bibleFetchingProgress = bibleData.length / bookIDs.length;
          });
          // print('Got ${bookIDs[b]}');
        }
        setState(() {
          bibleData = bibleData;
        });
        print('got books');
        List<int> bytes = utf8.encode(json.encode(bibleData));
        List<int> compressed = GZipEncoder().encode(bytes);
        saveValue('bibleData', base64.encode(compressed));
        print('saved bible');
        chapterWidgets = getContentWidgets(
          bibleData[currentBook]?[currentChapter],
          context.mounted ? context : context,
        );
        print('set chapter widgets');
        FlutterNativeSplash.remove();
      } else {
        print("Theres a problem: ${response.statusCode}");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List<dynamic>> getCommentaryChapterData(
    String translation,
    String bookID,
    int chapter,
  ) async {
    try {
      String fetchURL =
          'https://bible.helloao.org/api/c/$translation/$bookID/$chapter.json';
      // Get response and assign variables accordingly
      var response = await http.get(Uri.parse(fetchURL));
      if (response.statusCode != 200) {
        print('error');
      }
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['chapter'];

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

  double bibleFetchingProgress = 0;
  double commentaryFetchingProgress = 0;
  int currentBottomTab = 2;
  String currentBook = 'GEN';
  int currentChapter = 0;
  var bibleData = <String, List<dynamic>>{};
  var commentaryData = <String, List<dynamic>>{};
  List<String> chapterNames = [];
  List<Widget> chapterWidgets = [];

  List<Widget> get bottomNavScreens => [
    PageNotes(),
    PageChecklist(),
    PageHome(chapterWidgets: chapterWidgets),
    PageHome(chapterWidgets: chapterWidgets),
    PageSettings(getBooksAndChapters: getBooks),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${bibleData.isNotEmpty && chapterNames.isNotEmpty ? chapterNames[bibleData.keys.toList().indexOf(currentBook)] : 'Fetching IDs'} ${currentChapter + 1}",
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Visibility(
            visible: bibleFetchingProgress < 1,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.9,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey,
                    borderRadius: BorderRadius.circular(25),
                    color: Theme.of(context).colorScheme.secondary,
                    minHeight: 20,
                    value: bibleFetchingProgress,
                  ),
                  Text(
                    'Fetching Rest of Bible Data',
                    style: const TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        semanticLabel: "Book Selector",
        child: ListView.builder(
          itemCount: bibleData.keys.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(chapterNames[index]),
              onTap: () {
                setState(() {
                  currentBook = bibleData.keys.elementAt(index);
                  saveValue('currentBook', bibleData.keys.elementAt(index));
                  Navigator.pop(context);
                  Scaffold.of(context).openEndDrawer();
                });
              },
            );
          },
        ),
      ),
      endDrawer: Drawer(
        semanticLabel: "Chapter Selector",
        child: ListView.builder(
          itemCount: bibleData[currentBook]?.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text("${index + 1}"),
              onTap: () {
                setState(() {
                  currentChapter = index;
                  saveValue('currentChapter', currentChapter);
                  chapterWidgets = getContentWidgets(
                    bibleData[currentBook]?[currentChapter],
                    context,
                  );
                  Navigator.pop(context);
                });
              },
            );
          },
        ),
      ),
      body: IndexedStack(index: currentBottomTab, children: bottomNavScreens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: currentBottomTab,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: "Reflection",
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: "Reflection",
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Bible",
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: "Commentary",
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
            backgroundColor: Theme.of(context).colorScheme.tertiary,
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
