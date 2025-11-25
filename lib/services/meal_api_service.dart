import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/meal_summary.dart';
import '../models/meal_detail.dart';

class MealApiService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<Category>> getCategories() async {
    final uri = Uri.parse('$_baseUrl/categories.php');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load categories');
    }

    final data = jsonDecode(response.body);
    final List list = data['categories'] ?? [];

    return list.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<MealSummary>> getMealsByCategory(String category) async {
    final uri = Uri.parse('$_baseUrl/filter.php?c=$category');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load meals');
    }

    final data = jsonDecode(response.body);
    final List list = data['meals'] ?? [];

    return list.map((e) => MealSummary.fromJson(e)).toList();
  }

  /// Search meals by name. Optional category filter.
  // Future<List<MealSummary>> searchMeals(String query,
  //     {String? category}) async {
  //   if (query.trim().isEmpty) return [];
  //
  //   final uri = Uri.parse('$_baseUrl/search.php?s=$query');
  //   final response = await http.get(uri);
  //
  //   if (response.statusCode != 200) {
  //     throw Exception('Failed to search meals');
  //   }
  //
  //   final data = jsonDecode(response.body);
  //   final List? list = data['meals'];
  //
  //   if (list == null) return [];
  //
  //   return list.map((e) => MealSummary.fromJson(e)).toList();
  // }

  Future<List<MealSummary>> searchMeals(String query, {String? category}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/search.php?s=$query');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to search meals');
    }

    final data = jsonDecode(response.body);
    final List? list = data['meals'];

    if (list == null) return [];

    // FILTER JSON FIRST (because JSON has strCategory)
    final filteredJson = category == null
        ? list
        : list.where((mealJson) =>
    mealJson['strCategory']?.toString().toLowerCase() ==
        category.toLowerCase()
    );

    // THEN MAP TO MODEL
    return filteredJson
        .map((json) => MealSummary.fromJson(json))
        .toList();
  }


  Future<MealDetail> getMealDetail(String id) async {
    final uri = Uri.parse('$_baseUrl/lookup.php?i=$id');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load meal detail');
    }

    final data = jsonDecode(response.body);
    final List list = data['meals'] ?? [];

    if (list.isEmpty) {
      throw Exception('Meal not found');
    }

    return MealDetail.fromJson(list.first);
  }

  Future<MealDetail> getRandomMeal() async {
    final uri = Uri.parse('$_baseUrl/random.php');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load random meal');
    }

    final data = jsonDecode(response.body);
    final List list = data['meals'] ?? [];

    if (list.isEmpty) {
      throw Exception('No random meal');
    }

    return MealDetail.fromJson(list.first);
  }
}
