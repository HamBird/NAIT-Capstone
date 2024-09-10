import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
      title: 'Control Door Lock',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ControlPage(),
    );
  }
}

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlState();
}

class _ControlState extends State<ControlPage> {
  static BluetoothDevice blueDevice = BluetoothDevice(remoteId: const DeviceIdentifier("D8:3A:DD:57:06:86"));
  //late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  //late StreamSubscription<bool> _isScanningSubscription;

  Timer? _timer;
  bool _timerActive = false;

  String connectionStatus = "Unconnected";

  void checkState() {
    if(blueDevice.isConnected) {
      setState(() {
        connectionStatus = "Connected";
      });
    }
    else if(blueDevice.isDisconnected) {
      setState(() {
        connectionStatus = "Not Connected";
      });
    }
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
  @override
  void initState() {
    super.initState();
    //periodicallyScan();
    //_connect();
  }

  void turnOnLock() async{
    await _connect();
    await publishMessageOn();
    client.disconnect();
  }

  void turnOffLock() async{
    await _connect();
    await publishMessageOff();
    client.disconnect();
  }

  Future<void> connectToSpecificDevice() async {
    try{
      const macAddress = "D8:3A:DD:57:06:86";
      //Completer<void> complete = Completer<void>();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));

      await FlutterBluePlus.isScanning.where((event) => event == false).first;
      //StreamSubscription<List<ScanResult>> subscription = StreamSubscription<List<ScanResult>>();

      print("Starting Scan");

      //late BluetoothDevice desiredDevice;
      bool scannedDevice = false;
      
      var completer = Completer<void>();

      var subscription = FlutterBluePlus.scanResults.listen((results) {
          blueDevice = results.firstWhere((val) => val.device.remoteId.toString() == macAddress).device;
          //blueDevice = desiredDevice;
          scannedDevice = true;
          print("This is the result of the scan: ${blueDevice.remoteId.toString()} ${blueDevice.remoteId.toString() == macAddress}");
          print(blueDevice);
          //return;
          if (!completer.isCompleted) {
            completer.complete();
          }   
      },
      onError: (e) { 
        print(e);
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      );
    
      await completer.future;
      FlutterBluePlus.cancelWhenScanComplete(subscription);

      print(blueDevice);
      if (!scannedDevice) { print("Could not find device"); return; }
      //if(desiredDevice != null) {
      //  blueDevice = desiredDevice;
      //}

      print("Awaiting End of Scan!");
      //connectToDevice(blueDevice);

      blueDevice.cancelWhenDisconnected(subscription, delayed: true, next: true);
      //print("The Device Connected Is ${blueDevice.remoteId}");
    }
    catch (e) {
      print("An Error Has Occured Whilst Scanning $e");
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await connectToSpecificDevice();
      print("After Scanning");

      await device.connect(autoConnect: false);
      print("After Device Connect");
      await for (var state in blueDevice.connectionState) {
        if (state == BluetoothConnectionState.connected) {
          print("Device connected successfully");
          break; // Exit the loop when the device is connected
        }
      }
      print("After Connection State");


      //List<BluetoothService> _services = await blueDevice.discoverServices();
      //print(_services);
      
      if (Platform.isAndroid) {
        await device.requestMtu(512);
        List<BluetoothService> services = await blueDevice.discoverServices();
        print(services);
      }
      print("After Device MTU");

      //await device.connectionState.where((val) => val == BluetoothConnectionState.connected).first;
      // Connection successful
    } catch (e) {
      // Error occurred during connection
      print("Help Me Please ${e} $blueDevice");
    }
  }

  void disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      checkState();
    }
    catch(e) {
      print(e);
    }
  }

  void onConnectDevice() async {
    if (!blueDevice.isConnected && !FlutterBluePlus.isScanningNow) {
      await connectToDevice(blueDevice);
    }
    checkState();
  }
  void onDisconnectDevice() async {
    if (blueDevice.isConnected) {
      disconnectDevice(blueDevice);
    }
  }
  // Call in initState
  void periodicallyScan() {
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) { 
      onConnectDevice();
    });
  }
  void cancelAutoConnect() {
    _timerActive = false;
    _timer?.cancel();
    print("Disabled Timer");
  }
  // ReCall Periodically Scan
  void resumeAutoConnect() {
    print("Resumed Timer");
    if(!_timerActive) {
      _timerActive = true;
      
      periodicallyScan();
    }
  }
  Future<void> publishMessageOn() async{
    final builder = MqttClientPayloadBuilder();
    builder.addString('Turn On');
    client.publishMessage('Pi/Message', MqttQos.atLeastOnce, builder.payload!);
  }
  Future<void> publishMessageOff() async{
    final builder = MqttClientPayloadBuilder();
    builder.addString('Turn Off');
    client.publishMessage('Pi/Message', MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  void dispose() {
    //_scanResultsSubscription.cancel();
    //_isScanningSubscription.cancel();
    //blueDevice.disconnect();
    if(blueDevice.isConnected) {
      disconnectDevice(blueDevice);
    }
    if(_timerActive) {
      _timer?.cancel();
      _timer = null;
      _timerActive = false;
    }
    super.dispose();
  }

   void updateTable() async {
    // Example of updating the table data
    //await _GetActivity();
    setState(() {
      
    });
  }

  bool isAutoConnectOn = false;

  void onDisconnected() {
    print('Client Disconnected!');
  }

  
  // probably create similar structures for drop down menus, etc.
  // for add, remove, and update
  //Widget _buildActivityTable() {
    
  //}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade300,
        title: const Text('Lock Control Settings'),
        centerTitle: true,
      ),
      backgroundColor: Colors.blueGrey.shade300,
      body: Center(
        child: Column(
          children: [
            const Text("Note: To allow normal behavior, you must close after opening the door", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Column(children: [
                const Text("Open the Door"),
                const SizedBox(height: 15),
                FilledButton(onPressed: turnOffLock, child: const Text("Open")),
              ]),
              const SizedBox(width: 100),
              Column(children: [
                const Text("Close the Door"),
                const SizedBox(height: 15),
                FilledButton(onPressed: turnOnLock, child: const Text("Close")),
              ]),
            ]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const Text("Current Bluetooth Status: "),
              // the text below would be controlled through connection status string instead of constant
              Text(connectionStatus),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const Text("Turn Auto-Connect Off"),
              const SizedBox(width: 10),
              Switch(
                value: isAutoConnectOn,
                onChanged: (value) {
                  setState(() {
                    isAutoConnectOn = value;
                  });
                  // this is where the autoconnect callback would be called
                  print(isAutoConnectOn);
                  if(isAutoConnectOn) {
                    resumeAutoConnect();
                  }
                  else {
                    cancelAutoConnect();
                  }
                },
              ),
              const SizedBox(width: 10),
              const Text("Turn Auto-Connect On"),
            ]),
            const SizedBox(height: 20),
            const Text("Disconnect from Lock"),
            const SizedBox(height: 10),
            FilledButton(onPressed: onDisconnectDevice, child: const Text("Disconnect")),
          ]
        ),
      ),
    );
  }
}
