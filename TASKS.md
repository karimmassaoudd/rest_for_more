# Language (REST-107, REST-116) and Light / Dark mode (REST-106)

Setup is done: packages installed, `generate: true` in pubspec.yaml,
`l10n.yaml` in the project root, and `lib/l10n/` with one example key
(`welcomeTitle`). Run `flutter gen-l10n` to generate the translations class.

## Language

- [ ] `lib/services/locale_controller.dart` (see the TODO in the file)
- [ ] Connect it to `MaterialApp.router` in `main.dart` (locale,
      supportedLocales, localizationsDelegates). Keep the router.
- [ ] Replace hard-coded texts screen by screen; every key in BOTH .arb files
- [ ] Language screen (Continue) and Profile → Language row (bottom sheet,
      Figma screen 8) change the language; remove the _Coming soon_ tag

## Light / Dark / System

- [ ] `lib/services/theme_controller.dart` (see the TODO)
- [ ] `lib/theme/app_palette.dart` (see the TODO) + a dark version of
      `buildAppTheme()` in `app_theme.dart`
- [ ] Connect to `MaterialApp.router` (theme, darkTheme, themeMode)
- [ ] Replace fixed `AppColors.` colours in the screens
- [ ] Profile → Appearance switch works; remove the _Coming soon_ tag

## Done when

- [ ] Language and theme change immediately on every screen and are kept after a restart
- [ ] Default language = phone language if English or Dutch, else English; default theme = System
- [ ] Text readable in dark mode; dark colours agreed with the clients
- [ ] `flutter analyze`: no issues

Notes: no online/AI translation and no `http` package (all texts in the .arb
files). Don't replace `MaterialApp.router` with `home:`.
