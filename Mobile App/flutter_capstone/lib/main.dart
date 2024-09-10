import 'package:flutter_capstone/Activity.dart';
//import 'package:flutter_capstone/AddLock.dart';
import 'package:flutter_capstone/AddTag.dart';
import 'package:flutter_capstone/Control.dart';
import 'package:flutter_capstone/Users.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'The Automatic Door Lock'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // const MyHomePage({super.key, required this.title});
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 4,
       child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.greenAccent,
          title: Text(widget.title),
          centerTitle: true,
          bottom: const TabBar(
            dividerColor: Colors.black,
            tabs: [
              Tab(text: "Home"),
              Tab(text: "Control"),
              Tab(text: "Users"),
              Tab(text: "Add Tags/Phones"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ActivityPage(),
            ControlPage(),
            UsersPage(),
            TagsPage(),
          ],
        ),
      ),
    );
  }
}