const int kBreakMinutes = 1; //5
const int kMinMinutesForPause = 1; //30

/// None under 30 min, then one pause per full hour (at least one).
int pausesAllowedFor(int sessionMinutes) {
  if (sessionMinutes < kMinMinutesForPause) return 0;
  final perHour = sessionMinutes ~/ 60;
  return perHour < 1 ? 1 : perHour;
}
