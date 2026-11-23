// The "Post food" / "Edit token" form.
//
// showListingForm() opens it as a bottom sheet on phones and as a dialog on
// tablets and desktops (PROMPT.md Part A). Every rule the server checks is
// also checked here first, and any error the server still sends back is
// shown under the matching field.
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../models/food_listing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/filter_tag.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/pressable.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/veg_marker.dart';
import '../auth/auth_layout.dart';

/// Opens the form. Pass [existing] to edit a listing instead of posting one.
Future<void> showListingForm(BuildContext context, {FoodListing? existing}) async {
  final String? message;
  if (context.isMobile) {
    message = await showModalBottomSheet<String>(
      context: context,
      // The sheet slides up; with reduced motion it simply appears.
      sheetAnimationStyle: FlMotion.reduced(context) ? AnimationStyle.noAnimation : null,
      isScrollControlled: true, // lets the sheet grow tall and clear the keyboard
      useSafeArea: true,
      builder: (_) => ListingForm(existing: existing),
    );
  } else {
    message = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(FlSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListingForm(existing: existing),
        ),
      ),
    );
  }
  // The form closes itself with the server's message after a save.
  if (message != null && context.mounted) showSlip(context, message);
}

class ListingForm extends StatefulWidget {
  const ListingForm({super.key, this.existing});
  final FoodListing? existing;

  @override
  State<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<ListingForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title, _quantity, _location, _allergens, _description, _image;

  late FoodType _foodType;
  late String _unit;
  late DateTime _preparedAt;
  late DateTime _deadline;

  bool _saving = false;
  String? _formError; // a failure that is not about one field
  Map<String, String> _serverErrors = {}; // field -> message from the API

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = _roundToFive(DateTime.now());
    // New tokens start with sensible times: prepared now, collect within 3 hours.
    _title = TextEditingController(text: e?.title ?? '');
    _quantity = TextEditingController(text: e == null ? '' : '${e.quantity}');
    _location = TextEditingController(
        text: e?.location ?? context.read<AuthProvider>().user?.organization ?? '');
    _allergens = TextEditingController(text: e?.allergenNotes ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _image = TextEditingController(text: e?.imageUrl ?? '');
    _foodType = e?.foodType ?? FoodType.veg;
    _unit = e?.unit ?? 'plates';
    _preparedAt = e?.preparedAt ?? now;
    _deadline = e?.pickupDeadline ?? now.add(const Duration(hours: 3));
  }

  @override
  void dispose() {
    for (final c in [_title, _quantity, _location, _allergens, _description, _image]) {
      c.dispose();
    }
    super.dispose();
  }

  static DateTime _roundToFive(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, t.minute - t.minute % 5);

  // ---- Validation ------------------------------------------------------------

  /// A server error for [field] wins until the user edits that field.
  String? _server(String field) => _serverErrors[field];

  void _clearServer(String field) {
    if (_serverErrors.containsKey(field)) setState(() => _serverErrors = {..._serverErrors}..remove(field));
  }

  String? _preparedError() {
    if (_server('preparedAt') != null) return _server('preparedAt');
    if (_preparedAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return 'Prepared time cannot be in the future';
    }
    return null;
  }

  String? _deadlineError() {
    if (_server('pickupDeadline') != null) return _server('pickupDeadline');
    if (!_deadline.isAfter(DateTime.now())) return 'Pickup deadline must be in the future';
    if (!_deadline.isAfter(_preparedAt)) return 'Pickup deadline must be after the prepared time';
    return null;
  }

  // ---- Save ------------------------------------------------------------------

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _formError = null;
      _serverErrors = {};
    });
    final fieldsOk = _formKey.currentState!.validate();
    if (!fieldsOk || _preparedError() != null || _deadlineError() != null) {
      setState(() {}); // shows the date errors too
      return;
    }

    final draft = ListingDraft(
      title: _title.text.trim(),
      description: _description.text.trim(),
      quantity: int.parse(_quantity.text.trim()),
      unit: _unit,
      location: _location.text.trim(),
      preparedAt: _preparedAt,
      pickupDeadline: _deadline,
      foodType: _foodType,
      allergenNotes: _allergens.text.trim(),
      imageUrl: _image.text.trim(),
    );

    setState(() => _saving = true);
    final listings = context.read<ListingsProvider>();
    try {
      final saved = _editing ? await listings.update(widget.existing!.id, draft) : await listings.create(draft);
      if (mounted) Navigator.of(context).pop(saved.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors = e.fieldErrors;
        _formError = e.fieldErrors.isEmpty ? e.message : null;
      });
      _formKey.currentState!.validate(); // re-run so server messages appear
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---- Date and time ---------------------------------------------------------

  Future<DateTime?> _pick(DateTime initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 2)),
      lastDate: now.add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ---- Layout ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final mobile = context.isMobile;
    final reserved = widget.existing?.reservedQuantity ?? 0;

    return SingleChildScrollView(
      // On phones, leave room for the keyboard under the sheet.
      padding: EdgeInsets.fromLTRB(
        mobile ? FlSpace.lg : FlSpace.xl,
        mobile ? 0 : FlSpace.xl,
        mobile ? FlSpace.lg : FlSpace.xl,
        FlSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Heading row with a close button.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          _editing ? 'Edit #${widget.existing!.tokenNumber}' : 'Post food',
                          style: context.text.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: FlSpace.xs),
                      Text(
                        _editing
                            ? 'Changes show on the counter straight away.'
                            : 'It goes on the counter as a token with its own number.',
                        style: context.text.bodyMedium?.copyWith(color: fl.inkSoft),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: FlSpace.xl),
            if (_formError != null) FormNotice(message: _formError!),

            LabeledField(
              label: 'What is it?',
              child: TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(hintText: 'e.g. Veg Pulao with Raita', counterText: ''),
                onChanged: (_) => _clearServer('title'),
                validator: (v) {
                  if (_server('title') != null) return _server('title');
                  final t = (v ?? '').trim();
                  if (t.length < 2) return 'Give the food a name';
                  return null;
                },
              ),
            ),

            _GroupLabel('Food type'),
            Wrap(
              spacing: FlSpace.sm,
              children: [
                for (final t in FoodType.values)
                  FilterTag(
                    label: t.label,
                    leading: VegMarker(type: t, size: 14),
                    selected: _foodType == t,
                    onTap: () => setState(() => _foodType = t),
                  ),
              ],
            ),
            const SizedBox(height: FlSpace.lg),

            // Quantity and unit side by side.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: LabeledField(
                    label: 'Quantity',
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      style: fl.mono.copyWith(fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(hintText: '20'),
                      onChanged: (_) => _clearServer('quantity'),
                      validator: (v) {
                        if (_server('quantity') != null) return _server('quantity');
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n < 1) return 'At least 1';
                        if (n > 1000) return 'At most 1000';
                        if (n < reserved) return '$reserved are reserved';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: FlSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GroupLabel('Counted in'),
                      Wrap(
                        spacing: FlSpace.sm,
                        children: [
                          for (final u in kListingUnits)
                            FilterTag(label: u, selected: _unit == u, onTap: () => setState(() => _unit = u)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (reserved > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: FlSpace.lg),
                child: Text(
                  '${Fmt.quantity(reserved, widget.existing!.unit)} already promised to approved requests.',
                  style: context.text.bodySmall,
                ),
              ),

            LabeledField(
              label: 'Collect from',
              child: TextFormField(
                controller: _location,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'e.g. Main Block Canteen, Counter 2'),
                onChanged: (_) => _clearServer('location'),
                validator: (v) =>
                    _server('location') ?? ((v ?? '').trim().length < 2 ? 'Say where to collect it from' : null),
              ),
            ),

            // The two times. On narrow screens they stack.
            LayoutBuilder(builder: (context, box) {
              final prepared = _DateTimeField(
                label: 'Prepared at',
                value: _preparedAt,
                error: _preparedError(),
                onTap: () async {
                  final t = await _pick(_preparedAt);
                  if (t != null) setState(() => _preparedAt = t);
                  _clearServer('preparedAt');
                },
              );
              final deadline = _DateTimeField(
                label: 'Pickup by',
                value: _deadline,
                error: _deadlineError(),
                onTap: () async {
                  final t = await _pick(_deadline);
                  if (t != null) setState(() => _deadline = t);
                  _clearServer('pickupDeadline');
                },
              );
              if (box.maxWidth < 440) {
                return Column(children: [prepared, const SizedBox(height: FlSpace.lg), deadline]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: prepared),
                  const SizedBox(width: FlSpace.lg),
                  Expanded(child: deadline),
                ],
              );
            }),
            const SizedBox(height: FlSpace.sm),
            // Quick deadlines: one tap sets "pickup by" to now + N hours.
            Wrap(
              spacing: FlSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Pickup in:', style: context.text.bodySmall),
                for (final h in const [1, 2, 4])
                  FilterTag(
                    label: '+$h h',
                    selected: false,
                    onTap: () {
                      setState(() => _deadline = _roundToFive(DateTime.now().add(Duration(hours: h, minutes: 4))));
                      _clearServer('pickupDeadline');
                    },
                  ),
              ],
            ),
            const SizedBox(height: FlSpace.lg),

            LabeledField(
              label: 'Allergens',
              optional: true,
              child: TextFormField(
                controller: _allergens,
                maxLength: 300,
                decoration: const InputDecoration(hintText: 'e.g. Contains nuts and dairy', counterText: ''),
                onChanged: (_) => _clearServer('allergenNotes'),
                validator: (_) => _server('allergenNotes'),
              ),
            ),
            LabeledField(
              label: 'Notes',
              optional: true,
              child: TextFormField(
                controller: _description,
                maxLines: 3,
                minLines: 2,
                maxLength: 500,
                decoration: const InputDecoration(hintText: 'Packing, containers, anything useful', counterText: ''),
                onChanged: (_) => _clearServer('description'),
                validator: (_) => _server('description'),
              ),
            ),
            LabeledField(
              label: 'Photo link',
              optional: true,
              child: TextFormField(
                controller: _image,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'https://...'),
                onChanged: (_) => _clearServer('imageUrl'),
                validator: (v) {
                  if (_server('imageUrl') != null) return _server('imageUrl');
                  final t = (v ?? '').trim();
                  if (t.isNotEmpty && !RegExp(r'^https?://\S+\.\S+').hasMatch(t)) {
                    return 'Image link must start with http:// or https://';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: FlSpace.sm),

            Wrap(
              spacing: FlSpace.md,
              runSpacing: FlSpace.md,
              children: [
                FlButton(
                  label: _editing ? 'Save changes' : 'Print token',
                  loadingLabel: _editing ? 'Saving' : 'Printing',
                  icon: _editing ? Icons.check : Icons.confirmation_number_outlined,
                  variant: FlButtonVariant.accent,
                  loading: _saving,
                  onPressed: _submit,
                ),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A label above a group of tags (same look as LabeledField's label).
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: FlSpace.xs),
        child: Text(text, style: context.text.titleSmall),
      );
}

/// A tappable box that shows a date and time and opens the pickers.
class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.label, required this.value, required this.onTap, this.error});

  final String label;
  final DateTime value;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final border = error != null ? fl.chilliDeep : fl.controlBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.titleSmall),
        const SizedBox(height: FlSpace.sm),
        Pressable(
          onTap: onTap,
          semanticLabel: '$label: ${Fmt.dayTime(value)}. Change',
          focusRadius: FlRadius.control,
          builder: (context, hovered) => Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: FlSpace.lg, vertical: FlSpace.sm),
            decoration: BoxDecoration(
              color: hovered ? fl.surface : fl.surfaceSunken,
              borderRadius: BorderRadius.circular(FlRadius.control),
              border: Border.all(color: border, width: error != null ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Fmt.time(value), style: fl.mono.copyWith(fontWeight: FontWeight.w700)),
                      Text(Fmt.day(value).toUpperCase(), style: fl.monoSmall),
                    ],
                  ),
                ),
                Icon(Icons.edit_calendar_outlined, color: fl.inkSoft, size: 20),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: FlSpace.xs),
            child: Text(
              error!,
              style: context.text.bodySmall?.copyWith(color: fl.chilliDeep, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
