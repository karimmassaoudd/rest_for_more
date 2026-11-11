enum RoutinePeriod { morning, evening }

class RoutineStep {
  const RoutineStep({
    required this.title,
    required this.time,
    required this.duration,
    this.isCompleted = false,
  });

  final String title;
  final String time;
  final String duration;
  final bool isCompleted;

  RoutineStep copyWith({bool? isCompleted}) {
    return RoutineStep(
      title: title,
      time: time,
      duration: duration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
