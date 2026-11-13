/// Length of one break during a focus session.
const int kBreakMinutes = 5;

/// Sessions shorter than this get no breaks at all.
const int kMinMinutesForPause = 30;

/// How many breaks a session of [sessionMinutes] gets:
/// none under [kMinMinutesForPause], then one per full hour (at least one).
int pausesAllowedFor(int sessionMinutes) {
  if (sessionMinutes < kMinMinutesForPause) return 0;
  final perHour = sessionMinutes ~/ 60;
  return perHour < 1 ? 1 : perHour;
}
