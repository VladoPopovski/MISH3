import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/meal_api_service.dart';
import 'screens/categories_screen.dart';
import 'managers/favorites_manager.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // You can handle background messages here if needed
}

//local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  //notifications channel for android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  //init local notifications plugin
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  //req perms
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  // Print FCM token (needed for testing from Firebase Console)
  final token = await messaging.getToken();
  print("FCM TOKEN: $token");

  //foreground message handler - POPUP
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            visibility: NotificationVisibility.public,
            ticker: 'ticker',
          ),
        ),
      );
    }
  });

  //app favorites logic
  final favoritesManager = FavoritesManager();
  await favoritesManager.load();

  runApp(MyApp(favoritesManager: favoritesManager));
}

class MyApp extends StatelessWidget {
  final FavoritesManager favoritesManager;

  const MyApp({super.key, required this.favoritesManager});

  @override
  Widget build(BuildContext context) {
    final apiService = MealApiService();

    return ChangeNotifierProvider.value(
      value: favoritesManager,
      child: MaterialApp(
        title: 'Meals App',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.deepOrange,
        ),
        home: CategoriesScreen(apiService: apiService),
      ),
    );
  }
}
