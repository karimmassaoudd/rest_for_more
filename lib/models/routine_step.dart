enum RoutinePeriod { morning, evening }

class RoutineStep {
  const RoutineStep({
    this.id = '',
    required this.title,
    required this.time,
    required this.duration,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String time;
  final String duration;
  final bool isCompleted;

  RoutineStep copyWith({
    String? id,
    String? title,
    String? time,
    String? duration,
    bool? isCompleted,
  }) {
    return RoutineStep(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'time': time,
    'duration': duration,
    'isCompleted': isCompleted,
  };

  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    time: json['time'] as String? ?? '',
    duration: json['duration'] as String? ?? '5 min',
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

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
