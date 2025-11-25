import 'package:flutter/material.dart';

import '../models/meal_summary.dart';
import '../models/meal_detail.dart';
import '../services/meal_api_service.dart';
import '../widgets/meal_grid_item.dart';
import 'meal_detail_screen.dart';

class MealsByCategoryScreen extends StatefulWidget {
  final MealApiService apiService;
  final String category;

  const MealsByCategoryScreen({
    super.key,
    required this.apiService,
    required this.category,
  });

  @override
  State<MealsByCategoryScreen> createState() => _MealsByCategoryScreenState();
}

class _MealsByCategoryScreenState extends State<MealsByCategoryScreen> {
  late Future<List<MealSummary>> _futureMeals;
  String _searchText = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _futureMeals = widget.apiService.getMealsByCategory(widget.category);
  }

  Future<void> _searchMeals(String query) async {
    setState(() {
      _isSearching = true;
      _searchText = query;
    });

    try {
      if (query.trim().isEmpty) {
        setState(() {
          _futureMeals =
              widget.apiService.getMealsByCategory(widget.category);
        });
      } else {
        _futureMeals = widget.apiService.searchMeals(query);
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _openMealDetail(MealSummary meal) async {
    try {
      final MealDetail detail =
      await widget.apiService.getMealDetail(meal.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MealDetailScreen(mealDetail: detail),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search meals',
                prefixIcon: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _searchMeals(value);
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MealSummary>>(
              future: _futureMeals,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final meals = snapshot.data ?? [];
                if (meals.isEmpty) {
                  return const Center(child: Text('No meals found.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return MealGridItem(
                      meal: meal,
                      onTap: () => _openMealDetail(meal),
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
