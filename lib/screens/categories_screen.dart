import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/meal_detail.dart';
import '../services/meal_api_service.dart';
import '../widgets/category_card.dart';
import 'meals_by_category_screen.dart';
import 'meal_detail_screen.dart';
import 'favorites_screen.dart'; // ← ADD THIS IMPORT
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CategoriesScreen extends StatefulWidget {
  final MealApiService apiService;

  const CategoriesScreen({super.key, required this.apiService});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _futureCategories;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _initFCM();
    _futureCategories = widget.apiService.getCategories();
  }

  Future<void> _initFCM() async {
    // Request notification permission (Android/iOS)
    await FirebaseMessaging.instance.requestPermission();

    // Get the FCM device token
    final token = await FirebaseMessaging.instance.getToken();
    print("FCM TOKEN: $token");

    // Save token to Firestore (your Cloud Function will read this)
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(token)
          .set({'token': token});
    }

    // Listen for token refresh (optional)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(newToken)
          .set({'token': newToken});
    });
  }


  void _openRandomMeal() async {
    try {
      final MealDetail meal = await widget.apiService.getRandomMeal();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MealDetailScreen(
            mealDetail: meal,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading random meal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FavoritesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _openRandomMeal,
            tooltip: 'Random meal of the day',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search categories',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Category>>(
              future: _futureCategories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                final categories = snapshot.data ?? [];

                final filtered = categories.where((c) {
                  if (_searchText.isEmpty) return true;
                  return c.name.toLowerCase().contains(_searchText);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No categories found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final cat = filtered[index];
                    return CategoryCard(
                      category: cat,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MealsByCategoryScreen(
                              apiService: widget.apiService,
                              category: cat.name,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
