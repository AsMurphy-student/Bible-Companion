import 'dart:convert';

import 'package:biblereader/checklist_notes.dart';
import 'package:biblereader/functions/chapterFetching/get_chapter_data.dart';
import 'package:biblereader/functions/chapterFetching/get_commentary_chapter_data.dart';
import 'package:biblereader/functions/saveValue.dart';
import 'package:biblereader/functions/verses.dart';
import 'package:biblereader/utils/dialogHelper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bible.dart';
import 'settings.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:archive/archive.dart';

// This is the start of the main app
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
      // Theme is defined here for both light and dark theme
      theme: ThemeData(
        fontFamily: GoogleFonts.sora().fontFamily,
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
        fontFamily: GoogleFonts.sora().fontFamily,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0x0fd45f2d),
          brightness: Brightness.dark,
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
      // Disable debug banner
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
      // Init prefs and set variables if stored
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
      // Init checklist if stored or set default
      // and set listener to controller
      if (prefs.getString('checklist') != null) {
        checklistController = TextEditingController(
          text: prefs.getString('checklist'),
        );
        checklistController.addListener(
          () => saveValue('checklist', checklistController.text, prefs),
        );
      } else {
        checklistController = TextEditingController(
          text:
              '1. Identify exactly what this verse/section is saying.\n2. Where can this teaching apply to today?\n3. Where can this teaching apply to me?',
        );
        checklistController.addListener(
          () => saveValue('checklist', checklistController.text, prefs),
        );
      }

      // If we have notes data
      // decompress it and save it
      if (prefs.getString('notesData') != null) {
        // Get the string, decompress it, and get it into bytes
        // Figured out from: https://stackoverflow.com/questions/39735145/how-to-compress-a-string-using-gzip-or-similar-in-dart
        String notesDataString = prefs.getString('notesData')!;
        List<int> compressed = base64.decode(notesDataString);
        List<int> bytes = GZipDecoder().decodeBytes(compressed);
        try {
          // Then decode the bytes into json then cast it into List<String>
          Map<String, dynamic> loadedNotesData = jsonDecode(utf8.decode(bytes));
          Map<String, List<String>> parsedNotesData = Map.from(
            loadedNotesData.map(
              (key, value) => MapEntry(
                key,
                (value as List).map((e) => e.toString()).toList(),
              ),
            ),
          );
          // Once casted set to global variable
          // and set current notes into text field
          setState(() {
            notesData = parsedNotesData;
            notesController = TextEditingController(
              text: notesData[currentBook]?[currentChapter],
            );
          });
        } catch (e) {
          alertDialog(
            context,
            'Error decoding Json for notes data.',
            '$e',
            'Ok',
            false,
          );
        }
      }

      // Regardless of if there is stored notes data
      // Set the listener for the notes controller
      // Figured out from: https://stackoverflow.com/questions/39735145/how-to-compress-a-string-using-gzip-or-similar-in-dart
      notesController.addListener(() {
        notesData[currentBook]?[currentChapter] = notesController.text;
        List<int> notesBytes = utf8.encode(json.encode(notesData));
        List<int> notesCompressed = GZipEncoder().encode(notesBytes);
        saveValue('notesData', base64.encode(notesCompressed), prefs);
      });

      // If we have bible data
      // Decompress it and save it
      // then get chapter widgets with it
      // Figured out from: https://stackoverflow.com/questions/39735145/how-to-compress-a-string-using-gzip-or-similar-in-dart
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
              true,
            );
            bibleFetchingProgress = 1;
          });
          getCommentaryBooks();
        } catch (e) {
          alertDialog(
            context,
            'Error decoding Json for bible data.',
            '$e',
            'Ok',
            false,
          );
        }

        // Remove splash screen once stored bible data is processed
        FlutterNativeSplash.remove();
      } else {
        // Fetch bible data if none is stored
        getBooks();
      }
    });
  }

  // This function is called to fetch and store all bible data
  // Wanted to export this but setstate is used within it which makes it hard to refactor
  Future<void> getBooks() async {
    setState(() {
      // Set fetching progress variable for the progress bar to 0
      bibleFetchingProgress = 0;
    });
    // get chosen translation or use default
    String translation = prefs.getString('chosenTranslation') ?? "BSB";

    String fetchURL = 'https://bible.helloao.org/api/$translation/books.json';
    try {
      // Get response and assign variables accordingly
      http.Response response = await http.get(Uri.parse(fetchURL));

      if (response.statusCode == 200) {
        // Get list of books to get other details
        dynamic jsonResponse = jsonDecode(response.body);
        List<dynamic> listOfBooks = jsonResponse['books'];

        // Get book ids to fetch and chapter counts of each
        List<String> bookIDs = listOfBooks
            .map((element) => element['id'].toString())
            .toList();
        currentBookIDs = bookIDs;
        List<int> bookChapterCounts = listOfBooks
            .map((element) => int.parse(element['numberOfChapters'].toString()))
            .toList();
        chapterNames = listOfBooks
            .map((element) => element['name'].toString())
            .toList();
        saveValue('chapterNames', chapterNames, prefs);

        // Loop through each book
        for (int b = 0; b < bookIDs.length; b++) {
          List<dynamic> bookData = [];
          // Loop through each chapter and fetch it and then add it to bibleData map
          for (int c = 0; c < bookChapterCounts[b]; c++) {
            bookData.add(
              await getChapterData(
                translation,
                bookIDs[b],
                c + 1,
                context.mounted ? context : context,
              ),
            );
          }
          bibleData[bookIDs[b]] = bookData;

          // If notesData is not filled initialize it for current book
          if (notesData[bookIDs[b]] == null) {
            List<String> bookNotesInit = List.filled(bookData.length, '');
            notesData[bookIDs[b]] = bookNotesInit;
          }

          // If we are on current book
          // Set chapter widgets
          // Remove splash screen
          // and if commentary is not filled fetch it
          if (bookIDs[b] == currentBook) {
            setState(() {
              chapterWidgets = getContentWidgets(
                bibleData[currentBook]?[currentChapter],
                context.mounted ? context : context,
                true,
              );
            });
            FlutterNativeSplash.remove();
            if (commentaryData.isEmpty) {
              getCommentaryBooks();
            }
          }
          // Set state of fetching progress each completion
          setState(() {
            bibleFetchingProgress = (b + 1) / bookIDs.length;
          });
        }
        // When bible data is fully fetch reassign it to update state
        setState(() {
          bibleData = bibleData;
        });
        // Save bible data to prefs
        // Figured out from: https://stackoverflow.com/questions/39735145/how-to-compress-a-string-using-gzip-or-similar-in-dart
        List<int> bytes = utf8.encode(json.encode(bibleData));
        List<int> compressed = GZipEncoder().encode(bytes);
        saveValue('bibleData', base64.encode(compressed), prefs);
        chapterWidgets = getContentWidgets(
          bibleData[currentBook]?[currentChapter],
          context.mounted ? context : context,
          true,
        );
        // Remove splash screen if for whatever reason it has not been already
        FlutterNativeSplash.remove();

        // If notes data is not saved, save it
        // Figured out from: https://stackoverflow.com/questions/39735145/how-to-compress-a-string-using-gzip-or-similar-in-dart
        if (prefs.getString('notesData') == null) {
          List<int> notesBytes = utf8.encode(json.encode(notesData));
          List<int> notesCompressed = GZipEncoder().encode(notesBytes);
          saveValue('notesData', base64.encode(notesCompressed), prefs);
        }
        // Alert Dialog to catch different status code
      } else {
        alertDialog(
          context.mounted ? context : context,
          'No internet or some other error.',
          'Return status code: ${response.statusCode}',
          'Ok',
          false,
        );
      }
      // Alert Dialog to catch different status code
    } catch (e) {
      FlutterNativeSplash.remove();
      alertDialog(
        context.mounted ? context : context,
        'No internet or some other error.',
        'No internet is present unable to fetch data.',
        'Exit App',
        true,
      );
    }
  }

  // getCommentaryBooks function which fetchs commentary data
  // Wanted to export this but setstate is used within it which makes it hard to refactor
  Future<void> getCommentaryBooks() async {
    // If currentBookIDs of current translation is not set, set it
    if (currentBookIDs.isEmpty) {
      currentBookIDs = bibleData.keys.toList();
    }
    // Set commentary fetching progress to 0
    setState(() {
      commentaryFetchingProgress = 0;
    });
    String commentaryTranslationID =
        prefs.getString('chosenCommentary') ?? "jamieson-fausset-brown";
    // Loop through and fetch each book
    for (int b = 0; b < currentBookIDs.length; b++) {
      List<dynamic> bookData = [];
      String fetchURL =
          'https://bible.helloao.org/api/c/$commentaryTranslationID/${currentBookIDs[b]}/${1}.json';
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
      dynamic jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        // If we cannot decode json we continue and skip the book
        // Alert is not used here as user does not need to know
        // and getting 20 dialog alerts is not ideal for some commentaries
        // print("Error no book: ${currentBookIDs[b]} Error: $e");
        continue;
      }
      // Get number of chapters
      int numberOfChapters = int.parse(
        jsonResponse['book']['numberOfChapters'].toString(),
      );

      // Loop through chapters and fetch commentary chapter data
      for (int c = 0; c < numberOfChapters; c++) {
        bookData.add(
          await getCommentaryChapterData(
            commentaryTranslationID,
            currentBookIDs[b],
            c + 1,
            context.mounted ? context : context,
          ),
        );
      }
      // Once all chapters are fetched
      // Set to commentary data map accordingly
      commentaryData[currentBookIDs[b]] = bookData;
      // If on currently selected book update chapter widgets
      if (currentBookIDs[b] == currentBook) {
        setState(() {
          commentaryWidgets = getContentWidgets(
            commentaryData[currentBook]?[currentChapter],
            context.mounted ? context : context,
            false,
          );
        });
      }
      // Update progress bar variable
      setState(() {
        commentaryFetchingProgress = (b + 1) / currentBookIDs.length;
      });
    }
    // At end of loop set to 1
    // to ensure progress bar always disappears upon completion
    setState(() {
      commentaryFetchingProgress = 1;
    });
  }

  // Init prefs on startup
  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  // Progress bars variables
  double bibleFetchingProgress = 0;
  double commentaryFetchingProgress = 0;
  // Current tab, book, and chapter selected
  int currentBottomTab = 2;
  String currentBook = 'GEN';
  int currentChapter = 0;
  // Maps for bible, commentary, and notes data
  Map<String, List<dynamic>> bibleData = {};
  Map<String, List<dynamic>> commentaryData = {};
  Map<String, List<String>> notesData = {};
  // List of chapter names and bookIDs
  List<String> chapterNames = [];
  List<String> currentBookIDs = [];
  // Both array of chapter widgets for bible and commentary pages
  List<Widget> chapterWidgets = [];
  List<Widget> commentaryWidgets = [];
  // Controllers for checklist and notes
  TextEditingController checklistController = TextEditingController(text: '');
  TextEditingController notesController = TextEditingController(text: '');

  // bottom navigation screens
  List<Widget> get bottomNavScreens => [
    // Notes page
    PageChecklistNotes(
      controller: notesController,
      title: 'Chapter Notes',
      inputHint: 'Type Notes for Chapter Here...',
    ),
    // Checklist Page
    PageChecklistNotes(
      controller: checklistController,
      title: 'Reflection Checklist',
      inputHint: 'Type Checklist Here...',
    ),
    // Bible Page
    PageHome(chapterWidgets: chapterWidgets),
    // Commentary Page
    PageHome(chapterWidgets: commentaryWidgets),
    // Settings Page
    PageSettings(
      getBooksAndChapters: getBooks,
      getCommentary: getCommentaryBooks,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Title to show current book and chapter
        title: Text(
          "${bibleData.isNotEmpty && chapterNames.isNotEmpty ? chapterNames[bibleData.keys.toList().indexOf(currentBook)] : 'Fetching IDs'} ${currentChapter + 1}",
        ),
        // About icon button with small description
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              alertDialog(
                context,
                'About Bible Companion',
                'This is a Bible App which utilizes the Free Bible API. It features the Bible with Commentary, along with notes and a reflection checklist that is configurable.',
                'Ok',
                false,
              );
            },
          ),
        ],
        // This is the area for the progress bars of fetching
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            // We shrink the height of this area down once fetching is complete
            bibleFetchingProgress < 1 && commentaryFetchingProgress < 1
                ? 32.0
                : 0.0,
          ),
          child: Column(
            children: [
              // bible progress bar
              Visibility(
                visible: bibleFetchingProgress < 1,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.9,
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      LinearProgressIndicator(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).colorScheme.primary,
                        minHeight: 20,
                        value: bibleFetchingProgress,
                      ),
                      Text(
                        'Fetching Rest of Bible Data',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
              // commentary progress bar
              Visibility(
                visible: commentaryFetchingProgress < 1,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.9,
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      LinearProgressIndicator(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).colorScheme.primary,
                        minHeight: 20,
                        value: commentaryFetchingProgress,
                      ),
                      Text(
                        'Fetching Rest of Commentary Data',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // This drawer is for book selection
      drawer: Drawer(
        // Semantic label for screen readers
        semanticLabel: "Book Selector",
        // Tile builder using bible data
        child: ListView.builder(
          itemCount: bibleData.keys.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(chapterNames[index]),
              onTap: () {
                setState(() {
                  currentBook = bibleData.keys.elementAt(index);
                  saveValue(
                    'currentBook',
                    bibleData.keys.elementAt(index),
                    prefs,
                  );
                  Navigator.pop(context);
                  Scaffold.of(context).openEndDrawer();
                });
              },
            );
          },
        ),
      ),
      // This end drawer opens upon selecting a book from the main drawer
      endDrawer: Drawer(
        // Semantic label for screen readers
        semanticLabel: "Chapter Selector",
        // Tile builder using bible data
        child: ListView.builder(
          itemCount: bibleData[currentBook]?.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text("${index + 1}"),
              onTap: () {
                setState(() {
                  currentChapter = index;
                  saveValue('currentChapter', currentChapter, prefs);
                  chapterWidgets = getContentWidgets(
                    bibleData[currentBook]?[currentChapter],
                    context,
                    true,
                  );
                  commentaryWidgets = getContentWidgets(
                    commentaryData[currentBook]?[currentChapter],
                    context,
                    false,
                  );
                  notesController.text =
                      notesData[currentBook]![currentChapter];
                  Navigator.pop(context);
                });
              },
            );
          },
        ),
      ),
      // Used indexed stack with bottom nav screens
      body: IndexedStack(index: currentBottomTab, children: bottomNavScreens),
      // Bottom navigation bar
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
            saveValue('currentBottomTab', value, prefs);
          });
        },
      ),
    );
  }
}
