import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

final client = MqttServerClient('test.mosquitto.org', '');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Table Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UsersPage(),
    );
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UserPageState();
}

class _UserPageState extends State<UsersPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  static String url = 'https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php';
  List<dynamic> _users = [];
  List<String> _names = [];
  String currentName = "";
  String removeMessage = "Select This Is Quite Long";
  

  @override
  void initState() {
    updateTable();
    super.initState();
    // Fetch data on initial load
  }

  Future<void> _connect() async {
    client.setProtocolV311();
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.port = 1883;
    client.onDisconnected = onDisconnected;
    final connMessage = MqttConnectMessage()
      .withClientIdentifier('PhoneApp')
      .withWillTopic('willtopic')
      .withWillMessage('Will Topic')
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);
    print('Mosquitto client connecting...');
    client.connectionMessage = connMessage;

    try {
      await client.connect();
      client.autoReconnect = true;
    } on Exception {
      print('Client Exception ');
      client.disconnect();
    }
  }

  Future<void> publishUpdate() async{
    final builder = MqttClientPayloadBuilder();
    builder.addString('Update');
    client.publishMessage('Pi/Message', MqttQos.atLeastOnce, builder.payload!);
  }

  void onDisconnected() {
    print('Client Disconnected!');
  }

  void updatePico() async{
    await _connect();
    await publishUpdate();
    client.disconnect();
  }

  Future<void> _PostUser() async{
    final Map<String, dynamic> data = {
      'AddUser': '1',
      'firstName' : _firstNameController.text,
      'lastName' : _lastNameController.text,
    };
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type' : 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200){
      print('POST SUCCESS');
      updateTable();
      updatePico();
    }
    else{
      print('ERROR WITH POST');
    }
  }

  Future<void> _GetUsers() async{
    final response = await http.get(Uri.parse("https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php?getUsers=True"));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      _users = jsonData.toList();
      //print(_users);
      for (var element in _users) {
        String name = "${element[1]} ${element[2]}";
         _names.add(name);
      }
      currentName = _names[0];
      print(_names);
    } 
    else 
    {
      print('Failed to load users');
    }
  }
   void updateTable() async {
    // Example of updating the table data
    _names.clear();
    await _GetUsers();
    setState(() {
      
    });
  }

  Widget _buildAddUser() {
    return FilledButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context)
          {
            return Dialog(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: () {
                        _PostUser();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Submit'),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
      child: const Text('Add User')
    );
  }
  // probably create similar structures for drop down menus, etc.
  // for add, remove, and update
  Widget _buildDataTable() {
     return Center(
      child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Firstname')),
            DataColumn(label: Text('LastName')),
          ],
          rows: _users.map((data) {
            List<DataCell> cells = [];
            data.forEach((cellData) {
              cells.add(DataCell(Text(cellData.toString())));
            });
            ScrollDirection.forward;
          return DataRow(cells: cells);
          }).toList(),
      ))
    );
  }

  // use to handle removing a user
  void removeUser() async {
    //print(currentName);
    String Username = currentName;
    print(Username);
    final http.Response response = await http.post(
      Uri.parse('https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php'),
       headers: <String, String>{
         'Content-Type': 'application/json; charset=UTF-8',
       },
       body: jsonEncode(<String, String>{
         'name': currentName,
       }),
     );

     if (response.statusCode == 200){
       updateTable();
       updatePico();
       //showAlert("Removed User", "User successfully removed from database!");
     }
     else{
       //print('ERROR WITH POST');
       //showAlert("Failed", "Could not remove user!");
     }
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

  Widget _buildDropMenu() {
    return DropdownButton(
      //initialSelection: removeMessage,
      //value: currentName,
      items: _names.map((name) {
        return DropdownMenuItem<dynamic>(
          value: name,
          child: SizedBox(
            width: 150,  // Specify your desired width
            height: 50,  // Specify your desired height
            child: Center(
              child: Text(
                name,
                style: const TextStyle(color: Colors.black),
              )
            ),
          ),
        );
      }).toList(),
      onChanged: (dynamic _name) {
        //removeUser();
        setState(() {
          currentName = _name!;
        });
      },
      value: currentName
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade300,
        title: const Text('User Table'),
        centerTitle: true,
      ),
      backgroundColor: Colors.blueGrey.shade300,
      body: Column(
        children: [
          OverflowBar(
            //spacing: 8,
            //overflowAlignment: OverflowBarAlignment.center,
            children: [
              Row(children: [
                // add functionality for add user here CHRIS
                _buildAddUser(),
                //FilledButton(onPressed: () {}, child: const Text("Remove User")),
                //const Padding(padding: EdgeInsets.symmetric(horizontal: 10),),
                _buildDropMenu(),
                //const SizedBox(width: 20),
                // this button on press will be tied to the current user selected from the drop menu
                FilledButton(onPressed: removeUser, child: const Text("Remove")),
              ]),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDataTable(),
                  const SizedBox(height: 30),
                ],
              ),
            )
          )
        ],
      ), 

      /*
        SingleChildScrollView(
        child: Column(
          children: [
          _buildDataTable(),
          const SizedBox(height: 30),
        ]),
      )*/
    );
  }
}
