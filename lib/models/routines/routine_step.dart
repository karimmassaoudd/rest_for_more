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

/// A snapshot of morning and evening completion for one calendar day.
class RoutineDayRecord {
  const RoutineDayRecord({
    required this.date,
    required this.morningCompleted,
    required this.morningTotal,
    required this.eveningCompleted,
    required this.eveningTotal,
  });

  final String date;
  final int morningCompleted;
  final int morningTotal;
  final int eveningCompleted;
  final int eveningTotal;

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
  };

  factory RoutineDayRecord.fromJson(Map<String, dynamic> json) =>
      RoutineDayRecord(
        date: json['date'] as String,
        morningCompleted: json['morningCompleted'] as int? ?? 0,
        morningTotal: json['morningTotal'] as int? ?? 0,
        eveningCompleted: json['eveningCompleted'] as int? ?? 0,
        eveningTotal: json['eveningTotal'] as int? ?? 0,
      );
}
