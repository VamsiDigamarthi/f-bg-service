import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // Channel ID
    'MY FOREGROUND SERVICE', // Channel name
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

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

  // Handle overlay toggle
  service.on("toggleOverlay").listen((event) async {
    final isShow = event?['show'] as bool? ?? false;
    if (isShow) {
      await FlutterOverlayWindow.showOverlay(
        height: 100,
        width: 100,
        alignment: OverlayAlignment.topLeft,
        enableDrag: true,
        flag: OverlayFlag.defaultFlag,
      );
      print("Overlay shown");
    } else {
      await FlutterOverlayWindow.closeOverlay();
      print("Overlay removed");
    }
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

// Define the overlay content
@pragma("vm:entry-point")
Widget overlayWidget() {
  return Material(
    color: Colors.transparent,
    child: Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: Text(
          "Float",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    ),
  );
}
