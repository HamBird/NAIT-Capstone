import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

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
      home: const ActivityPage(),
    );
  }
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityState();
}

class _ActivityState extends State<ActivityPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  static String url = 'https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php';
  List<dynamic> _activity = [];
  

  @override
  void initState() {
    updateTable();
    super.initState();
    // Fetch data on initial load
  }

  Future<void> _PostActivity() async{
    final Map<String, dynamic> data = {
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
    }
    else{
      print('ERROR WITH POST');
    }
  }

  Future<void> _GetActivity() async{
    final response = await http.get(Uri.parse("https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php?Active=True"));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      _activity = jsonData.toList();
    } 
    else 
    {
      throw Exception('Failed to load users');
    }
  }
   void updateTable() async {
    // Example of updating the table data
    await _GetActivity();
    setState(() {
      
    });
  }
  // probably create similar structures for drop down menus, etc.
  // for add, remove, and update
  Widget _buildActivityTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Message')),
          ],
          rows: _activity.map((data) {
            List<DataCell> cells = [];
            data.forEach((cellData) {
              cells.add(DataCell(Text(cellData.toString())));
            });
          return DataRow(cells: cells);
          }).toList(),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade300,
        title: const Text('Lock Activity Table'),
        centerTitle: true,
      ),
      backgroundColor: Colors.blueGrey.shade300,
      body: SingleChildScrollView(
        child:Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              child: _buildActivityTable(),
            ),
          ),
        ]),
      ),
    );
  }
}
