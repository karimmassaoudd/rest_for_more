import 'routine_step.dart';

/// The morning routine shown until the user changes it.
/// The first three steps start ticked off, as an example.
const defaultMorningSteps = [
  RoutineStep(
    title: 'Cold Water & Electrolytes',
    time: '7:00 AM',
    duration: '5 min',
    isCompleted: true,
  ),
  RoutineStep(
    title: 'Box Breathing & Stretch',
    time: '7:05 AM',
    duration: '10 min',
    isCompleted: true,
  ),
  RoutineStep(
    title: 'Sensory Shower',
    time: '7:15 AM',
    duration: '15 min',
    isCompleted: true,
  ),
  RoutineStep(
    title: 'Matcha & Intention Journal',
    time: '7:30 AM',
    duration: '10 min',
  ),
  RoutineStep(
    title: 'Daily Priority Alignment',
    time: '7:40 AM',
    duration: '5 min',
  ),
];

/// The evening routine shown until the user changes it.
const defaultEveningSteps = [
  RoutineStep(
    title: 'Screen Curfew & Phone Away',
    time: '9:40 PM',
    duration: '5 min',
  ),
  RoutineStep(
    title: 'Herbal Chamomile & Tincture',
    time: '9:45 PM',
    duration: '10 min',
  ),
  RoutineStep(
    title: 'Warm Shower & Skincare',
    time: '9:55 PM',
    duration: '15 min',
  ),
  RoutineStep(
    title: 'Gratitude & Unload Journal',
    time: '10:10 PM',
    duration: '10 min',
  ),
  RoutineStep(
    title: 'Dim Lamps & 4-7-8 Breathing',
    time: '10:20 PM',
    duration: '5 min',
  ),
];
