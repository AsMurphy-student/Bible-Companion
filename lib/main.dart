import 'package:flutter/material.dart';
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
  int currentBottomTab = 0;

  final List<Widget> bottomNavScreens = [PageHome(), PageSettings()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book chapter (ex. John 5)"),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.arrow_back), onPressed: () {}),
          IconButton(icon: Icon(Icons.arrow_forward), onPressed: () {}),
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
            
          });
        },
      ),
    );
  }
}
