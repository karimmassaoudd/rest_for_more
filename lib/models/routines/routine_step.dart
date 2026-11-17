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

/// One step of a routine on one day, as saved in the history.
class RoutineStepResult {
  const RoutineStepResult({required this.title, required this.done});

  final String title;
  final bool done;

  Map<String, Object> toJson() => {'title': title, 'done': done};

  factory RoutineStepResult.fromJson(Map<String, dynamic> json) =>
      RoutineStepResult(
        title: json['title'] as String? ?? '',
        done: json['done'] as bool? ?? false,
      );
}

/// One routine day in the history (a day starts at 04:00, see
/// RoutineProgressStorage.progressDay): how far each routine got, and which
/// steps it had that day and which were done. Records saved before the step
/// lists existed only have the counts; their lists are empty.
class RoutineDayRecord {
  const RoutineDayRecord({
    required this.date,
    required this.morningCompleted,
    required this.morningTotal,
    required this.eveningCompleted,
    required this.eveningTotal,
    this.morningSteps = const [],
    this.eveningSteps = const [],
  });

  final String date;
  final int morningCompleted;
  final int morningTotal;
  final int eveningCompleted;
  final int eveningTotal;

  /// The routine as it was that day, with done / not done per step.
  final List<RoutineStepResult> morningSteps;
  final List<RoutineStepResult> eveningSteps;

  double get morningProgress =>
      morningTotal == 0 ? 0 : morningCompleted / morningTotal;
  double get eveningProgress =>
      eveningTotal == 0 ? 0 : eveningCompleted / eveningTotal;

  Map<String, Object> toJson() => {
    'date': date,
    'morningCompleted': morningCompleted,
    'morningTotal': morningTotal,
    'eveningCompleted': eveningCompleted,
    'eveningTotal': eveningTotal,
    'morningSteps': [for (final step in morningSteps) step.toJson()],
    'eveningSteps': [for (final step in eveningSteps) step.toJson()],
  };

  factory RoutineDayRecord.fromJson(Map<String, dynamic> json) =>
      RoutineDayRecord(
        date: json['date'] as String,
        morningCompleted: json['morningCompleted'] as int? ?? 0,
        morningTotal: json['morningTotal'] as int? ?? 0,
        eveningCompleted: json['eveningCompleted'] as int? ?? 0,
        eveningTotal: json['eveningTotal'] as int? ?? 0,
        morningSteps: _stepsFrom(json['morningSteps']),
        eveningSteps: _stepsFrom(json['eveningSteps']),
      );

  static List<RoutineStepResult> _stepsFrom(Object? value) => value is List
      ? [
          for (final item in value)
            if (item is Map<String, dynamic>) RoutineStepResult.fromJson(item),
        ]
      : const [];
}
