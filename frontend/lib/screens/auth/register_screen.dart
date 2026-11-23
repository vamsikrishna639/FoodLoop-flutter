import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/paper_shapes.dart';
import '../../widgets/pressable.dart';
import '../../widgets/status_stamp.dart';
import 'auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _organization = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  UserRole? _role;
  bool _roleMissing = false; // true after submitting without picking a role
  bool _hidePassword = true;
  bool _loading = false;
  String? _error;
  Map<String, String> _serverErrors = {}; // per-field messages from the API

  @override
  void dispose() {
    for (final c in [_name, _organization, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() {
      _serverErrors = {};
      _roleMissing = _role == null;
    });
    final fieldsOk = _formKey.currentState!.validate();
    if (!fieldsOk || _role == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            role: _role!,
            phone: _phone.text.trim(),
            organization: _organization.text.trim(),
          );
      // The router now sends the new (pending) user to the waiting screen.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors = e.fieldErrors;
        // Field errors appear under their inputs; anything else goes on top.
        _error = e.fieldErrors.isEmpty ? e.message : null;
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Combines the local check with any message the server sent for the field.
  String? Function(String?) _check(String field, String? Function(String) local) {
    return (v) => local((v ?? '').trim()) ?? _serverErrors[field];
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final orgLabel = switch (_role) {
      UserRole.donor => 'Canteen name',
      UserRole.volunteer => 'Club or unit',
      _ => 'Organization',
    };

    return AuthLayout(
      formMaxWidth: 560,
      form: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('Take a token', style: context.text.displaySmall)),
            const SizedBox(height: FlSpace.sm),
            Text('Tell us how you will use FoodLoop. An admin approves each new account.',
                style: context.text.bodyLarge?.copyWith(color: fl.inkSoft)),
            const SizedBox(height: FlSpace.xl),
            if (_error != null) FormNotice(message: _error!),

            // ---- Role picker: four token slips -------------------------
            Text('I am joining as', style: context.text.titleSmall),
            const SizedBox(height: FlSpace.sm),
            LayoutBuilder(
              builder: (context, box) {
                // Two slips per row; a single column only when text is very large.
                final perRow = box.maxWidth >= 300 ? 2 : 1;
                // The gap is wider than two notches, so the cut-outs of
                // neighbouring slips do not touch.
                final w = (box.maxWidth - FlSpace.xl * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: FlSpace.xl,
                  runSpacing: FlSpace.md,
                  children: [
                    for (final role in UserRole.values)
                      SizedBox(
                        width: w,
                        child: _RoleSlip(
                          role: role,
                          selected: _role == role,
                          // Admin accounts are created by the college, not here.
                          enabled: role != UserRole.admin && !_loading,
                          onTap: () => setState(() {
                            _role = role;
                            _roleMissing = false;
                          }),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (_roleMissing)
              Padding(
                padding: const EdgeInsets.only(top: FlSpace.sm),
                child: Semantics(
                  liveRegion: true,
                  child: Text('Choose one of the roles above',
                      style: context.text.bodySmall
                          ?.copyWith(color: fl.chilliDeep, fontWeight: FontWeight.w600)),
                ),
              ),
            const SizedBox(height: FlSpace.xl),

            // ---- Details -------------------------------------------------
            LabeledField(
              label: 'Your name',
              child: TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: _check('name', (v) => v.length < 2 ? 'Enter your name' : null),
              ),
            ),
            LabeledField(
              label: orgLabel,
              optional: true,
              child: TextFormField(
                controller: _organization,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'e.g. Asha Night Shelter'),
                validator: _check('organization', (v) => v.length > 80 ? 'Keep this under 80 characters' : null),
              ),
            ),
            LabeledField(
              label: 'Email',
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                // A server message such as "already exists" belongs to the old
                // value, so drop it as soon as the email is edited.
                onChanged: (_) {
                  if (_serverErrors.containsKey('email')) {
                    setState(() => _serverErrors = Map.of(_serverErrors)..remove('email'));
                  }
                },
                validator: _check('email', (v) {
                  if (v.isEmpty) return 'Enter your email';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                    return 'That does not look like an email address';
                  }
                  return null;
                }),
              ),
            ),
            LabeledField(
              label: 'Phone',
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(helperText: 'So a volunteer or canteen can reach you'),
                validator: _check('phone', (v) {
                  if (v.isEmpty) return 'Enter your phone number';
                  if (!RegExp(r'^[0-9+\- ]{7,15}$').hasMatch(v)) return 'Use 7 to 15 digits';
                  return null;
                }),
              ),
            ),
            LabeledField(
              label: 'Password',
              child: TextFormField(
                controller: _password,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  helperText: 'At least 6 characters',
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                    icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
                // Not trimmed: spaces are allowed in passwords.
                validator: (v) =>
                    (v ?? '').length < 6 ? 'Use at least 6 characters' : _serverErrors['password'],
              ),
            ),
            const SizedBox(height: FlSpace.sm),
            FlButton(
              label: 'Create account',
              loadingLabel: 'Creating account',
              variant: FlButtonVariant.accent,
              expand: true,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: FlSpace.xl),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Already have an account?', style: context.text.bodyMedium),
                TextButton(
                  onPressed: _loading ? null : () => context.go('/login'),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One role, drawn as a small token slip. Picking it stamps it.
class _RoleSlip extends StatelessWidget {
  const _RoleSlip({required this.role, required this.selected, required this.enabled, required this.onTap});

  final UserRole role;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  static const double _stub = 34;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final isAdmin = role == UserRole.admin;

    return Pressable(
      onTap: enabled ? onTap : null,
      selected: selected,
      semanticLabel: isAdmin ? 'Admin. Set up by the campus office, not available here' : '${role.label}. ${role.blurb}',
      builder: (context, hovered) => Opacity(
        opacity: isAdmin ? 0.55 : 1,
        child: CustomPaint(
          painter: TokenSlipPainter(
            stubHeight: _stub,
            lineColor: selected ? fl.ink : (hovered ? fl.controlBorder : fl.perforation),
            shadowColor: fl.ink.withValues(alpha: 0.10),
            lifted: hovered && !selected,
          ),
          foregroundPainter: selected ? _SelectedOutline(fl.ink, _stub) : null,
          child: ClipPath(
            clipper: const TokenSlipClipper(_stub),
            child: ColoredBox(
              color: fl.surface,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A fixed height keeps all four slips the same size.
                    SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(96),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(FlSpace.md, FlSpace.md, FlSpace.md, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(role.label, style: context.text.titleLarge),
                            const SizedBox(height: FlSpace.xs),
                            Expanded(
                              child: Text(
                                isAdmin ? 'Set up by the campus office' : role.blurb,
                                style: context.text.bodySmall,
                                overflow: TextOverflow.fade,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: _stub,
                      child: ColoredBox(
                        color: fl.surfaceSunken,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: FlRadius.notch + 3),
                              child: DottedLine(color: fl.perforation, dot: 3, gap: 4, height: 3),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: FlSpace.md),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isAdmin ? 'NOT HERE' : (selected ? 'YOURS' : 'TAP TO PICK'),
                                        style: fl.monoSmall,
                                      ),
                                    ),
                                    if (selected) const StatusStamp.custom('PICKED', scale: 0.72),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A heavier ink outline for the chosen slip.
class _SelectedOutline extends CustomPainter {
  const _SelectedOutline(this.color, this.stub);
  final Color color;
  final double stub;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      tokenSlipPath(size, stub),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SelectedOutline old) => old.color != color;
}
