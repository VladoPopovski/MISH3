import 'package:flutter/material.dart';
import 'services/meal_api_service.dart';
import 'screens/categories_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = MealApiService();

    return MaterialApp(
      title: 'Meals App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepOrange,
      ),
      home: CategoriesScreen(apiService: apiService),
    );
  }
}
