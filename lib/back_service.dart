import 'dart:ui';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: iosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
    ),
  );
}

@pragma("vm:entry-point")
Future<bool> iosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma("vm:entry-point")
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.on("setAsForeground").listen((event) {
      service.setAsForegroundService();
      print("Service moved to foreground");
    });
    service.on("setAsBackground").listen((event) {
      service.setAsBackgroundService();
      print("Service moved to background");
    });
  }
  service.on("stopService").listen((event) async {
    service.stopSelf();
    print("Service stopped");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('serviceRunning', false);
  });
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(title: "WoR", content: "Chages");
      }
    }
    print("background services running");
    service.invoke("update");
  });
}
