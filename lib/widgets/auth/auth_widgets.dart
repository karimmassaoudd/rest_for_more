import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_fonts.dart';

/// Shared building blocks for the account screens (Figma Sprint 4, 1–4).

/// Muted red from the error states in the wireframe.
const authErrorRed = Color(0xFFB0473A);
const _fieldBorder = Color(0xFFE0D6C8);
const _fieldFill = Colors.white;

/// Page layout: back button + Cormorant title, centred subtitle,
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
  final Widget? subtitle;
  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool loading;
  final Widget? footer;
  final bool titleCentered;

  /// Optional widget at the right of the title row (e.g. LanguageToggle).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ]
                  // keeps a centred title really centred
                  else if (titleCentered)
                    const SizedBox(width: 52),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 16),
                DefaultTextStyle(
                  textAlign: TextAlign.center,
                  style: AppFonts.manrope(
                    size: 13,
                    color: AppColors.lightbrown,
                  ),
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
            border: Border.all(color: _fieldBorder),
          ),
          child: const Icon(
            Icons.arrow_back,
            size: 18,
            color: AppColors.darkbrown,
          ),
        ),
      ),
    );
  }
}

/// Full-width brown button; shows a small spinner and is disabled while busy
/// (prevents double accounts from double taps, REST-98).
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lightbrown,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Label + white rounded field + optional red error under it.
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
  bool _hidden = true;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: AppFonts.manrope(size: 12, weight: FontWeight.w700),
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
            style: AppFonts.manrope(size: 15),
            decoration: InputDecoration(
              hintText: widget.hint,
              filled: true,
              fillColor: _fieldFill,
              enabledBorder: _border(hasError ? authErrorRed : _fieldBorder),
              disabledBorder: _border(_fieldBorder),
              focusedBorder: _border(
                hasError ? authErrorRed : AppColors.mediumbrown,
                1.5,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      tooltip: _hidden ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.lightbrown,
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
        style: AppFonts.manrope(size: 12, color: authErrorRed),
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: AppFonts.manrope(size: 13)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
            foregroundColor: AppColors.darkbrown,
            textStyle: AppFonts.manrope(size: 13, weight: FontWeight.w700),
          ),
          child: Text(linkText),
        ),
      ],
    );
  }
}

/// Six boxes for the email code. One hidden TextField does the typing,
/// so paste and Android's one-time-code autofill work.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    this.hasError = false,
    this.onCompleted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onCompleted;
  final bool enabled;

  static const length = 6;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focus.addListener(() => setState(() {}));
  }

  void _onChanged() {
    setState(() {});
    final code = widget.controller.text;
    if (code.length == CodeInput.length) widget.onCompleted?.call(code);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          // Invisible field that receives the keyboard input.
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 52,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                maxLength: CodeInput.length,
                autofillHints: const [AutofillHints.oneTimeCode],
                showCursor: false,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
          Semantics(
            label: '6-digit code, ${code.length} of 6 entered',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(CodeInput.length, (i) {
                final filled = i < code.length;
                final active = _focus.hasFocus && i == code.length;
                return Container(
                  width: 46,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _fieldFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.hasError
                          ? authErrorRed
                          : active
                          ? AppColors.mediumbrown
                          : _fieldBorder,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    filled ? code[i] : '',
                    style: AppFonts.manrope(size: 20, weight: FontWeight.w600),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
