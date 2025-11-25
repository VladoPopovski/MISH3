import 'package:flutter/material.dart';
import '../models/meal_summary.dart';

class MealGridItem extends StatelessWidget {
  final MealSummary meal;
  final VoidCallback onTap;

  const MealGridItem({
    super.key,
    required this.meal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: GridTile(
        footer: Container(
          color: Colors.black54,
          padding: const EdgeInsets.all(4),
          child: Text(
            meal.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        child: Image.network(
          meal.thumbnail,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
