const Set<String> hardAlwaysAvailableApps = {
  // Phone
  'com.google.android.dialer',
  'com.android.dialer',
  'com.samsung.android.dialer',
  // Messages
  'com.google.android.apps.messaging',
  'com.samsung.android.messaging',
};

Set<String> getHardAlwaysAvailableApps(Set<String> selectedApps) => {
  ...selectedApps,
  ...hardAlwaysAvailableApps,
};
