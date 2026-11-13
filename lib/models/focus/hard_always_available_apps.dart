/// Apps that are always usable during a session and can't be blocked
/// or turned off: phone and messages, so the user can always be reached.
const Set<String> hardAlwaysAvailableApps = {
  // Phone
  'com.google.android.dialer',
  'com.android.dialer',
  'com.samsung.android.dialer',
  // Messages
  'com.google.android.apps.messaging',
  'com.samsung.android.messaging',
};

/// The user's own always-available apps plus [hardAlwaysAvailableApps].
Set<String> getHardAlwaysAvailableApps(Set<String> selectedApps) => {
  ...selectedApps,
  ...hardAlwaysAvailableApps,
};
