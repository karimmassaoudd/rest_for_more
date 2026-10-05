import 'package:flutter/material.dart';

class Activity {
  Activity({
    required this.time,
    required this.name,
    required this.duration,
    required this.icon,
  });

  String time;
  String name;
  String duration;
  IconData icon;
}
