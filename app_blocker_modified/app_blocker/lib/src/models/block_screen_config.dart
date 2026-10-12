import 'dart:ui';

/// Configuration for the Android block screen shown when a blocked app is opened.
///
/// This has no effect on iOS, where the system shield is used instead.
class BlockScreenConfig {
  /// Creates an [BlockScreenConfig] instance.
  const BlockScreenConfig({
    this.title,
    this.subtitle,
    this.message,
    this.backgroundColor,
    this.iconAssetPath,
    this.returnHomeButtonText,
    this.emergencyButtonText,
    this.timerLabel,
  });

  /// The title text shown on the block screen.
  ///
  /// Defaults to "App Blocked" if not specified.
  final String? title;

  /// The subtitle text shown below the title.
  final String? subtitle;

  /// Additional message text shown on the block screen.
  final String? message;

  /// The background color of the block screen.
  ///
  /// Defaults to a dark semi-transparent color if not specified.
  final Color? backgroundColor;

  /// Path to a custom icon asset to display on the block screen.
  ///
  /// Should be a Flutter asset path (e.g., `assets/icons/lock.png`).
  final String? iconAssetPath;

  /// The label shown on the primary "return to home" button.
  ///
  /// Defaults to "Return to home" if not specified.
  final String? returnHomeButtonText;

  /// The label shown on the secondary "emergency unlock" button.
  ///
  /// Defaults to "Emergency Unlock" if not specified.
  final String? emergencyButtonText;

  /// The label shown for the timer on the block screen.
  ///
  /// Defaults to "{timeLeft} remaining" if not specified.
  final String? timerLabel;

  /// Creates an [BlockScreenConfig] from a map returned by the platform.
  factory BlockScreenConfig.fromMap(Map<String, dynamic> map) {
    return BlockScreenConfig(
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      message: map['message'] as String?,
      backgroundColor: map['backgroundColor'] != null
          ? Color(map['backgroundColor'] as int)
          : null,
      iconAssetPath: map['iconAssetPath'] as String?,
      returnHomeButtonText: map['returnHomeButtonText'] as String?,
      emergencyButtonText: map['emergencyButtonText'] as String?,
      timerLabel: map['timerLabel'] as String?,
    );
  }

  /// Converts this instance to a map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'message': message,
      'backgroundColor': backgroundColor?.toARGB32(),
      'iconAssetPath': iconAssetPath,
      'returnHomeButtonText': returnHomeButtonText,
      'emergencyButtonText': emergencyButtonText,
      'timerLabel': timerLabel,
    };
  }

  @override
  String toString() => 'BlockScreenConfig(title: $title, subtitle: $subtitle)';
}
