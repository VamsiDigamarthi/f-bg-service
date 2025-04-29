import 'package:bg/back_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  await initializeService();
  final prefs = await SharedPreferences.getInstance();
  final bool serviceRunning = prefs.getBool('serviceRunning') ?? false;
  if (serviceRunning) {
    await FlutterBackgroundService().startService();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // Function to start the service and update SharedPreferences
  Future<void> _startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('serviceRunning', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                FlutterBackgroundService().invoke("setAsForeground");
              },
              child: Text("Fore"),
            ),
            ElevatedButton(
              onPressed: () {
                FlutterBackgroundService().invoke("setAsBackground");
              },
              child: Text("back"),
            ),
            ElevatedButton(
              onPressed: () {
                FlutterBackgroundService().invoke("stopService");
              },
              child: Text("stop"),
            ),
            ElevatedButton(
              onPressed: _startService, // New button to start service
              child: const Text("Start Service"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
