import 'package:flutter/material.dart';

import '../models/activity.dart';

const routineSleepTime = '22:30';

//this temp hardcoded data, later this will be collect form a json or other data source


List<Activity> getActivities() {
  final list = <Activity>  [
    Activity(
      time: '21:30',
      name: 'Telefoon wegleggen',
      duration: '5 min',
      icon: Icons.phone_disabled_outlined,
    ),
    Activity(
      time: '21:35',
      name: 'Opruimen',
      duration: '10 min',
      icon: Icons.cleaning_services_outlined,
    ),
    Activity(
      time: '21:45',
      name: 'Douchen',
      duration: '15 min',
      icon: Icons.shower_outlined,
    ),
    Activity(
      time: '22:00',
      name: 'Tandenpoetsen',
      duration: '5 min',
      icon: Icons.sentiment_satisfied_alt_outlined,
    ),
    Activity(
      time: '22:05',
      name: 'Lezen',
      duration: '25 min',
      icon: Icons.menu_book_outlined,
    ),
    Activity(
      time: '22:30',
      name: 'Slapen',
      duration: '0 min',
      icon: Icons.bed_outlined,
    ),
  ];
  return list;
}
