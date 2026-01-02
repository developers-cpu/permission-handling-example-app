import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(onPressed: () {}, child: Text("Android 10")),
            ElevatedButton(onPressed: () {}, child: Text("Android 11")),
            ElevatedButton(onPressed: () {}, child: Text("Android 12")),
            ElevatedButton(onPressed: () {}, child: Text("Android 13")),
            ElevatedButton(onPressed: () {}, child: Text("Android 14")),
            ElevatedButton(onPressed: () {}, child: Text("Android 15")),
            ElevatedButton(onPressed: () {}, child: Text("Android 16")),
          ],
        ),
      ),
    );
  }
}
