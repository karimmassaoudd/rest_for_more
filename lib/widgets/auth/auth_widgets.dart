import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
// Re-exported so screens that import this file also get CodeInput.
export 'code_input.dart';

// Shared building blocks for the account screens:
// create account, log in and verify email.

/// Page layout: back button + Cormorant title, optional subtitle,
/// scrollable form, one primary button at the bottom, small footer link.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    required this.primaryLabel,
    required this.onPrimary,
    this.loading = false,
    this.footer,
    this.titleCentered = false,
    this.trailing,
  });

  final String title;

  /// Centred, small grey text under the title.
  final Widget? subtitle;

  /// The form fields.
  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// Shows a spinner in the primary button and disables it.
  final bool loading;

  /// Shown under the primary button, e.g. [AuthFooterLink].
  final Widget? footer;
  final bool titleCentered;

  /// Optional widget at the right of the title row (e.g. a language toggle).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const AuthBackButton(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: titleCentered
                          ? TextAlign.center
                          : TextAlign.start,
                      style: AppFonts.cormorant(
                        size: 30,
                        weight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ] else if (titleCentered)
                    // Same width as the back button + gap, so a centred
                    // title is centred on the screen, not in the leftover space.
                    const SizedBox(width: 52),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 16),
                DefaultTextStyle(
                  textAlign: TextAlign.center,
                  style: AppFonts.manrope(size: 13, color: palette.muted),
                  child: subtitle!,
                ),
              ],
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 32, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              AuthPrimaryButton(
                label: primaryLabel,
                onPressed: onPrimary,
                loading: loading,
              ),
              if (footer != null) ...[const SizedBox(height: 14), footer!],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round outlined back arrow. Opened without a screen underneath
/// (e.g. after a restart) it goes to Welcome instead of doing nothing.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.canPop() ? context.pop() : context.go('/welcome'),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
          child: Icon(Icons.arrow_back, size: 18, color: palette.text),
        ),
      ),
    );
  }
}

/// Full-width brown button. While [loading] it shows a small spinner and
/// can't be tapped, so a double tap can't create two accounts.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.onAccent,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Bold label, white rounded field, and the error in red under it.
/// Password fields get a show / hide button and no autocorrect.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.errorText,
    this.keyboardType,
    this.isPassword = false,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  /// Shown under the field and turns its border red; null = no error.
  final String? errorText;
  final TextInputType? keyboardType;
  final bool isPassword;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  /// Password fields start hidden.
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasError = widget.errorText != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: AppFonts.manrope(
              size: 12,
              weight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.controller,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            obscureText: widget.isPassword && _hidden,
            autocorrect: !widget.isPassword,
            enableSuggestions: !widget.isPassword,
            autofillHints: widget.autofillHints,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            onSubmitted: widget.onSubmitted,
            style: AppFonts.manrope(size: 15, color: palette.text),
            decoration: InputDecoration(
              hintText: widget.hint,
              // Red outline while there's an error; the text sits below.
              enabledBorder: hasError
                  ? Theme.of(context).inputDecorationTheme.errorBorder
                  : null,
              focusedBorder: hasError
                  ? Theme.of(context).inputDecorationTheme.focusedErrorBorder
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      tooltip: _hidden ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: palette.muted,
                      ),
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : null,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            AuthErrorText(widget.errorText!),
          ],
        ],
      ),
    );
  }
}

/// Small red message under a field or the code boxes.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key, this.center = false});

  final String message;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true, // screen readers announce the error
      child: Text(
        message,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: AppFonts.manrope(size: 12, color: AppColors.error),
      ),
    );
  }
}

/// "Already have an account? Log in" style footer.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  final String text;
  final String linkText;

  /// Null disables the link (e.g. while loading).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: AppFonts.manrope(size: 13, color: palette.text)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
            foregroundColor: palette.text,
            textStyle: AppFonts.manrope(
              size: 13,
              weight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          child: Text(linkText),
        ),
      ],
    );
  }
}
