/// Which routine a step belongs to; also decides the light (morning)
/// or dark (evening) colours.
enum RoutinePeriod { morning, evening }

/// One step of the morning or evening routine on the routine screen.
class RoutineStep {
  const RoutineStep({
    required this.title,
    required this.time,
    required this.duration,
    this.isCompleted = false,
  });

  /// Also used to save progress, so two steps shouldn't share a title.
  final String title;

  /// Start time, 12-hour like "7:00 AM".
  final String time;

  /// Text like "15 min".
  final String duration;
  final bool isCompleted;

  /// A copy with [isCompleted] changed; everything else stays.
  RoutineStep copyWith({bool? isCompleted}) {
    return RoutineStep(
      title: title,
      time: time,
      duration: duration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
