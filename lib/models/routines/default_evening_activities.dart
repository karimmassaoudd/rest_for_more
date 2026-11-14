import 'package:flutter/material.dart';

import 'activity.dart';

/// The bedtime used until the user picks their own ("HH:mm").
const defaultRoutineSleepTime = '22:30';

/// The evening routine a new user starts with, ending at the default bedtime.
///
/// A function instead of a constant list because [Activity] can be edited:
/// every caller gets its own copy.
List<Activity> defaultEveningActivities() => [
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
    time: defaultRoutineSleepTime,
    // The editor finds the bedtime activity by this name.
    name: 'Slapen',
    duration: '0 min',
    icon: Icons.bed_outlined,
  ),
];
