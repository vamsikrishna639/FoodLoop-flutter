import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/fl_button.dart';
import 'auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _hidePassword = true;
  bool _loading = false;
  String? _error; // message from the server after a failed attempt

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(_email.text.trim(), _password.text);
      // No navigation here: the router sees the new session and redirects.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = context.select<AuthProvider, bool>((a) => a.sessionExpired);

    return AuthLayout(
      form: Form(
        key: _formKey,
        // Each field checks itself when the user leaves it.
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text('Sign in', style: context.text.displaySmall)),
              const SizedBox(height: FlSpace.sm),
              Text('Pick up where you left off at the counter.',
                  style: context.text.bodyLarge?.copyWith(color: context.fl.inkSoft)),
              const SizedBox(height: FlSpace.xxl),
              if (_error != null)
                FormNotice(message: _error!)
              else if (expired)
                const FormNotice(message: 'You were signed out. Please sign in again.', error: false),
              LabeledField(
                label: 'Email',
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  decoration: const InputDecoration(hintText: 'you@college.edu'),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Enter your email';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                      return 'That does not look like an email address';
                    }
                    return null;
                  },
                ),
              ),
              LabeledField(
                label: 'Password',
                child: TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      tooltip: _hidePassword ? 'Show password' : 'Hide password',
                      icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
                ),
              ),
              const SizedBox(height: FlSpace.sm),
              FlButton(
                label: 'Sign in',
                loadingLabel: 'Signing in',
                variant: FlButtonVariant.accent,
                expand: true,
                loading: _loading,
                onPressed: () {
                  TextInput.finishAutofillContext();
                  _submit();
                },
              ),
              const SizedBox(height: FlSpace.xl),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('New to FoodLoop?', style: context.text.bodyMedium),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/register'),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
