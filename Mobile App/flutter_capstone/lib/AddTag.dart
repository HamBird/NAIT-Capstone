import 'package:flutter/material.dart';
import 'package:flutter_capstone/AddLock.dart';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
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
      title: 'Add Tags Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TagsPage(),
    );
  }
}

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsState();
}

class _TagsState extends State<TagsPage> {
  List<dynamic> _users = [];
  List<dynamic> _locks = [];
  List<String> _names = [];
  String currentName = "";
  String currentLock = "";
  String removeMessage = "Select This Is Quite Long";


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

  void updatePico() async{
    await _connect();
    await publishUpdate();
    client.disconnect();
  }

  Future<void> publishUpdate() async{
    final builder = MqttClientPayloadBuilder();
    builder.addString('Update');
    client.publishMessage('Pi/Message', MqttQos.atLeastOnce, builder.payload!);
  }

  Future<void> publishMessageUpdatePhone(String tagid, String lockid) async{
    final builder = MqttClientPayloadBuilder();
    builder.addString('UpdatePhone $tagid $lockid');
    client.publishMessage('Pi/Message', MqttQos.atLeastOnce, builder.payload!);
  }
  Future<void> publishMessageUpdateTag(String tagid, String lockid) async{
    final builder = MqttClientPayloadBuilder();
    builder.addString('UpdateTag $tagid $lockid');
    client.publishMessage('Pi/Message', MqttQos.atLeastOnce, builder.payload!);
  }

  void onDisconnected() {
    print('Client Disconnected!');
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
    } 
    else 
    {
      print('Failed to load users');
    }
  }

  Future<void> _GetLocks() async{
    final response = await http.get(Uri.parse("https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php?LockNames=True"));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      //_locks = jsonData.toList();
      for (var element in jsonData) {
        _locks.add(element[0]);
      }
      print(_locks);
      currentLock = _locks[0].toString();
      print(currentLock);
    } 
    else 
    {
      print('Failed to load users');
    }
  }

  @override
  void initState() {
    updateTable();
    super.initState();

  }

  void updateTable() async {
    // Example of updating the table data
    await _GetUsers();
    await _GetLocks();
    setState(() {
      
    });
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


  // Handles the tag row
  Widget tagRow(String title, String desc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12.0),
            ),
            const SizedBox(width: 15.0),  // To add space between the text and the containers
            Center(
              child: SizedBox(
                width: 110.0,
                height: 40.0,
                child: FilledButton(
                  onPressed: addTag,          
                  child: const Text("Add Tag"),
                ),
              ),
            ),
            Text(
              desc,
              style: const TextStyle(fontSize: 12.0),
            ),
            Center(
              child: SizedBox(
                width: 120.0,
                height: 50.0,
                child: FilledButton(
                  onPressed: removeTag,          
                  child: const Text("Delete Tag"),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10.0),  // To add space between the containers
        const SizedBox(
          width: 200.0,
          height: 200.0,
          //decoration: BoxDecoration(
          //  border: Border.all(color: Colors.black),
          //),
          child: Image(image: AssetImage('assets/CardCropped.png')),
        ),
      ],
    );
  }

  // Handles the phone row
  Widget phoneRow(String title, String desc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(
          width: 180.0,
          height: 180.0,
          child: Image(image: AssetImage('assets/PhoneCropped.png')),
        ),
        const SizedBox(width: 15.0),  // To add space between the text and the containers
        Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12.0),
            ),
            const SizedBox(width: 15.0),  // To add space between the text and the containers
            Center(
              child: SizedBox(
                width: 150.0,
                height: 50.0,
                child: FilledButton(
                  onPressed: addPhone,          
                  child: const Text("Add Phone"),
                ),
              ),
            ),
            Text(
              desc,
              style: const TextStyle(fontSize: 12.0),
            ),
            Center(
              child: SizedBox(
                width: 150.0,
                height: 50.0,
                child: FilledButton(
                  onPressed: removePhone,          
                  child: const Text("Delete Phone"),
                ),
              ),
            ),
          ],
        ),
      ],
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
            width: 110,  // Specify your desired width
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
        setState(() {
          currentName = _name!;
        });
      },
      value: currentName
    );
  }

  void removePhone() async{
    await removeQuery(currentLock, currentName, "Phone");
    updatePico();
    showAlert("Success", "Successfully removed phone address from user!");
  }
  void removeTag() async{
    await removeQuery(currentLock, currentName, "Tag");
    updatePico();
    showAlert("Success", "Successfully removed tag address from user!");
  }

  void addTag() async{
    Map<String, dynamic> result = await addQuery(currentLock, currentName, "Tag");

    if(result.isNotEmpty) {
      // Perform MQTT to send message to Pico
      await _connect();
      await publishMessageUpdateTag(result['tagid'], result['lockid']);
      client.disconnect();
      showAlert("Notice", "Message sent to Lock, Please Scan Tag on Lock!");
    }
  }
  void addPhone() async{
    Map<String, dynamic> result = await addQuery(currentLock, currentName, "Phone");

    if(result.isNotEmpty) {
      // Perform MQTT to send message to Pico
      await _connect();
      await publishMessageUpdatePhone(result['tagid'], result['lockid']);
      client.disconnect();
      showAlert("Notice", "Message sent to Lock, Please Connect Phone To Lock!");
    }
  }

  Future<int> removeQuery(String _lockname, String _username, String _type) async{
    final http.Response response = await http.post(
      Uri.parse('https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'remove': "1",
        'name': _username,
        'lock': _lockname,
        'type': _type,
      }),
    );

    if (response.statusCode == 200){
      print('POST SUCCESS');
      return 200;
    }
    else{
      print('ERROR WITH POST');
      return -1;
    }
  }

  Future<Map<String, dynamic>> addQuery(String _lockname, String _username, String _type) async{
    final http.Response response = await http.post(
      Uri.parse('https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'add': "1",
        'name': _username,
        'lock': _lockname,
        'type': _type,
      }),
    );

    if (response.statusCode == 200){
      print('POST SUCCESS');
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      print(jsonData);
      return jsonData;
    }
    else{
      print('ERROR WITH POST');
      Map<String, dynamic> jsonData = {};
      return jsonData;
    }
  }

  Widget _buildDropMenuLock() {
    return DropdownButton(
      //initialSelection: removeMessage,
      //value: currentName,
      items: _locks.map((name) {
        return DropdownMenuItem<dynamic>(
          value: name,
          child: SizedBox(
            width: 110,  // Specify your desired width
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
      onChanged: (dynamic _lock) {
        setState(() {
          currentLock = _lock!;
        });
      },
      value: currentLock
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade300,
        centerTitle: true,
        title: const Text('Adding Tags or Phones'),
      ),
      backgroundColor: Colors.blueGrey.shade300,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Text("Current User:", style: TextStyle(fontSize: 14)),
                _buildDropMenu(), 
                _buildDropMenuLock(),
              ]),
              tagRow('Add New Tags For Lock', 'Remove Tag'),
              const SizedBox(height: 50.0),  // To add space between the rows
              phoneRow('Add New Phones For Lock', 'Remove Phone'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddLockPage()),
                  );
                }, 
                child: const Text("Add New Lock")),
            ],
          ),
        ), 
      ), 
    );
  }

}
