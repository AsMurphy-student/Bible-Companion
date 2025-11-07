import 'package:flutter/material.dart';

class Translationdropdown extends StatefulWidget {
  const Translationdropdown({super.key});

  @override
  State<Translationdropdown> createState() => _TranslationdropdownState();
}

class _TranslationdropdownState extends State<Translationdropdown> {
  String dropdownValue = 'Item 1'; // Initial value
  final List<String> items = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Translation:"),
        DropdownButton<String>(
          value: dropdownValue,
          icon: Icon(Icons.arrow_downward),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!;
            });
          },
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ],
    );
  }
}
