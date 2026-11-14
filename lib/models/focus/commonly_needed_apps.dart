/// Android package names suggested when the user taps "Suggested Apps"
/// on the Edit Always Available Apps screen. Only the installed ones are selected.
///
/// Most apps have a Google, a generic (AOSP) and a Samsung version.
const commonlyNeededApps = [
  // Camera
  'com.google.android.GoogleCamera',
  'com.android.camera2', // generic/AOSP
  'com.sec.android.app.camera', // Samsung
  // Clock / Alarm
  'com.google.android.deskclock',
  'com.android.deskclock', // generic/AOSP
  'com.sec.android.app.clockpackage', // Samsung
  // Calculator
  'com.google.android.calculator',
  'com.android.calculator2', // generic/AOSP
  'com.sec.android.app.popupcalculator', // Samsung
  // Maps (same package on every phone)
  'com.google.android.apps.maps',
  // Contacts
  'com.google.android.contacts',
  'com.android.contacts', // generic/AOSP
  'com.samsung.android.app.contacts', // Samsung
  // Settings (same package on every phone)
  'com.android.settings',
  // Email
  'com.google.android.gm', // Gmail
  'com.samsung.android.email.provider', // Samsung Email
  // Calendar
  'com.google.android.calendar',
  'com.samsung.android.calendar', // Samsung
];
