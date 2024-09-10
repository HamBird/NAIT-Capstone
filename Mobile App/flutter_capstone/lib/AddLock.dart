import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AddLockPage(),
    );
  }
}

class AddLockPage extends StatefulWidget {
  const AddLockPage({super.key});

  @override
  State<AddLockPage> createState() => _LockState();
}

class _LockState extends State<AddLockPage> {
  final TextEditingController _textEditingController = TextEditingController();
  String lockname = "";


  Future<void> addQuery(String _lockname) async{
    final http.Response response = await http.post(
      Uri.parse('https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'AddLock': "1",
        'lock': _lockname,
      }),
    );

    if (response.statusCode == 200){
      //print('POST SUCCESS');
      showAlert("User Added", "User was successfully added to the database!");
    }
    else{
      //print('ERROR WITH POST');
      showAlert("Failed", "Failed to add user to database!");
    }
  }


  Widget _buildTextBox() {
    return TextField(
      controller: _textEditingController,
      decoration: const InputDecoration(
        hintText: 'Enter your text...',
      ),
    );
  }

  void showAlert(String _title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_title),
          content: Text(description),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  //@override
  //void initState() {
    //super.initState();
    // Fetch data on initial load
  //}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: const Text('Adding New Lock'),
        centerTitle: true,
      ),
      backgroundColor: Colors.blueGrey.shade300,
      body: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                SizedBox(height: 60),
                Text("Please Insert a Name!"),
            ],  
          ),
          const SizedBox(height: 50),
          _buildTextBox(),
          const SizedBox(height: 80),
          FilledButton(onPressed: () {addQuery(_textEditingController.text); _textEditingController.text = "";}, child: const Text("Add Name"))
        ],
      ),
    );
  }
}
