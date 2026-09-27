import 'package:flutter/material.dart';

class Roadmap {
  final String id;
  final String title;
  final String description;
  final int completedTasks;
  final int totalTasks;
  final List<Color> gradient;
  
  const Roadmap({
    required this.id,
    required this.title,
    required this.description,
    required this.completedTasks,
    required this.totalTasks,
    required this.gradient,
  });
}
