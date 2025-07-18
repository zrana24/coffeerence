import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> getFcmToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? fcmToken = await messaging.getToken();
    print('FCM Token: $fcmToken');

    if (fcmToken != null) {
      await sendTokenToBackend(fcmToken);
    }
  } else {
    print('Bildirim izinleri verilmedi.');
  }
}

Future<void> sendTokenToBackend(String fcmToken) async {
  final prefs = await SharedPreferences.getInstance();
  final loginToken = prefs.getString('token');

  if (loginToken == null) {
    print('Login token bulunamadı, token gönderilemiyor.');
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('https://mobilapp.coffeerence.com.tr/api/save-token'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $loginToken',
      },
      body: json.encode({'token': fcmToken}),
    );

    if (response.statusCode == 200) {
      print('FCM token backend\'e başarıyla gönderildi.');
    } else {
      final responseData = json.decode(response.body);
      print(
          'FCM token gönderme başarısız: ${response.statusCode} - ${responseData['message'] ?? 'Bilinmeyen hata'}');
    }
  } catch (e) {
    print('Token gönderilirken hata oluştu: $e');
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Arka planda gelen bildirim: ");
  print('Title: \'${message.notification?.title}\'');
  print('Body: \'${message.notification?.body}\'');
}

Future<void> setupFirebaseMessagingListeners(BuildContext context) async {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Uygulama açıkken gelen bildirim: ${message.notification?.title}');
    if (message.notification != null) {
      final snackBar = SnackBar(
        content: Text(
          '${message.notification!.title ?? ''}\n${message.notification!.body ?? ''}',
        ),
        duration: Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print(
        'Bildirime tıklanarak uygulama açıldı: ${message.notification?.title}');
  });
}
