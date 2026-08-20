import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/simple_calculator.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

const _notesBackground = Color(0xFFF4F7F4);
const _notesSurface = Color(0xFFFFFFFF);
const _notesInk = Color(0xFF14231C);
const _notesMuted = Color(0xFF627168);
const _notesLine = Color(0xFFDDE8DF);
const _notesPrimary = Color(0xFF176B45);
const _notesDanger = Color(0xFFC83A2B);
const _notesAccent = Color(0xFFE86F4A);

/// Admin-only workspace for personal reminders/notes plus a quick
/// calculator. Reached from [AdminAccountScreen] ("General Notes"). Notes
/// are scoped to the signed-in admin's own uid both here and in
/// firestore.rules, so each admin only ever sees their own notes.
class AdminGeneralNotesScreen extends StatelessWidget {
  const AdminGeneralNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final adminUid = appState.profile?.uid ?? '';
    return Scaffold(
      backgroundColor: _notesBackground,
      appBar: AppBar(
        title: const Text(
          'General notes',
          style: TextStyle(color: _notesInk, fontWeight: FontWeight.w900),
        ),
        backgroundColor: _notesBackground,
        foregroundColor: _notesInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _AdminNoteEditorScreen(adminUid: adminUid),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New note'),
        backgroundColor: _notesPrimary,
      ),
      body: SafeArea(
        child: ListView(
          physics: appRefreshScrollPhysics,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          children: [
            const _SectionLabel(title: 'Quick calculator'),
            const SizedBox(height: 10),
            const _QuickCalculatorCard(),
            const SizedBox(height: 22),
            const _SectionLabel(title: 'Notes'),
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 10),
              child: Text(
                'Private to your admin account.',
                style: TextStyle(
                  color: _notesMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            StreamBuilder<List<AdminNote>>(
              stream: appState.firestoreService.watchAdminNotes(adminUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _NotesCard(child: LoadingView());
                }
                final notes = snapshot.data ?? const <AdminNote>[];
                if (notes.isEmpty) {
                  return const _NotesCard(
                    child: EmptyState(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'No notes yet',
                      message:
                          'Tap "New note" to save a reminder or quick '
                          'business detail.',
                    ),
                  );
                }
                return Column(
                  children: notes
                      .map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NoteCard(note: note),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _notesInk,
        fontWeight: FontWeight.w900,
        fontSize: 15,
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _notesSurface,
        border: Border.all(color: _notesLine),
        borderRadius: radius,
      ),
      child: child,
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final AdminNote note;

  @override
  Widget build(BuildContext context) {
    final updated = DateFormat('dd MMM yyyy, h:mm a').format(note.updatedAt);
    final preview = note.content.trim();
    return Material(
      color: _notesSurface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _AdminNoteEditorScreen(
              adminUid: note.adminUid,
              note: note,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _notesLine),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty ? 'Untitled note' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _notesInk,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _notesMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Updated $updated',
                style: const TextStyle(
                  color: _notesMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNoteEditorScreen extends StatefulWidget {
  const _AdminNoteEditorScreen({required this.adminUid, this.note});

  final String adminUid;
  final AdminNote? note;

  @override
  State<_AdminNoteEditorScreen> createState() =>
      _AdminNoteEditorScreenState();
}

class _AdminNoteEditorScreenState extends State<_AdminNoteEditorScreen> {
  late final _titleController =
      TextEditingController(text: widget.note?.title ?? '');
  late final _contentController =
      TextEditingController(text: widget.note?.content ?? '');
  var _isSaving = false;

  bool get _isEditing => widget.note != null;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = true);
    try {
      final appState = context.read<AppState>();
      final existing = widget.note;
      final note = existing == null
          ? AdminNote(
              id: const Uuid().v4(),
              adminUid: widget.adminUid,
              title: title,
              content: content,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : existing.copyWith(title: title, content: content);
      await appState.firestoreService.saveAdminNote(note);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final appState = context.read<AppState>();
      await appState.firestoreService.deleteAdminNote(widget.note!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error);
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _notesBackground,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit note' : 'New note',
          style: const TextStyle(color: _notesInk, fontWeight: FontWeight.w900),
        ),
        backgroundColor: _notesBackground,
        foregroundColor: _notesInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _isSaving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: _notesDanger),
              tooltip: 'Delete note',
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: appRefreshScrollPhysics,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            if (_isEditing && widget.note!.updatedAt != widget.note!.createdAt)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Last updated '
                  '${DateFormat('dd MMM yyyy, h:mm a').format(widget.note!.updatedAt)}',
                  style: const TextStyle(
                    color: _notesMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            AppTextField(
              controller: _titleController,
              label: 'Title',
              prefixIcon: Icons.title,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _contentController,
              label: 'Note',
              maxLines: 10,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _notesPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A basic four-function calculator (with percentage) for quick admin
/// arithmetic. Purely ephemeral UI state driven by [SimpleCalculator] — no
/// history is persisted, per product requirements.
class _QuickCalculatorCard extends StatefulWidget {
  const _QuickCalculatorCard();

  @override
  State<_QuickCalculatorCard> createState() => _QuickCalculatorCardState();
}

class _QuickCalculatorCardState extends State<_QuickCalculatorCard> {
  var _state = SimpleCalculator.initial;

  void _digit(String digit) =>
      setState(() => _state = SimpleCalculator.inputDigit(_state, digit));

  void _decimal() =>
      setState(() => _state = SimpleCalculator.inputDecimal(_state));

  void _operator(String operator) =>
      setState(() => _state = SimpleCalculator.inputOperator(_state, operator));

  void _equals() => setState(() => _state = SimpleCalculator.equals(_state));

  void _percent() => setState(() => _state = SimpleCalculator.percent(_state));

  void _clear() => setState(() => _state = SimpleCalculator.clear());

  void _backspace() =>
      setState(() => _state = SimpleCalculator.backspace(_state));

  @override
  Widget build(BuildContext context) {
    return _NotesCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: _notesBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _state.display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _notesInk,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _CalcRow(
            buttons: [
              _CalcButton(label: 'C', onTap: _clear, kind: _CalcButtonKind.muted),
              _CalcButton(
                label: '⌫',
                onTap: _backspace,
                kind: _CalcButtonKind.muted,
              ),
              _CalcButton(
                label: '%',
                onTap: _percent,
                kind: _CalcButtonKind.muted,
              ),
              _CalcButton(
                label: '÷',
                onTap: () => _operator('÷'),
                kind: _CalcButtonKind.accent,
              ),
            ],
          ),
          _CalcRow(
            buttons: [
              _CalcButton(label: '7', onTap: () => _digit('7')),
              _CalcButton(label: '8', onTap: () => _digit('8')),
              _CalcButton(label: '9', onTap: () => _digit('9')),
              _CalcButton(
                label: '×',
                onTap: () => _operator('×'),
                kind: _CalcButtonKind.accent,
              ),
            ],
          ),
          _CalcRow(
            buttons: [
              _CalcButton(label: '4', onTap: () => _digit('4')),
              _CalcButton(label: '5', onTap: () => _digit('5')),
              _CalcButton(label: '6', onTap: () => _digit('6')),
              _CalcButton(
                label: '-',
                onTap: () => _operator('-'),
                kind: _CalcButtonKind.accent,
              ),
            ],
          ),
          _CalcRow(
            buttons: [
              _CalcButton(label: '1', onTap: () => _digit('1')),
              _CalcButton(label: '2', onTap: () => _digit('2')),
              _CalcButton(label: '3', onTap: () => _digit('3')),
              _CalcButton(
                label: '+',
                onTap: () => _operator('+'),
                kind: _CalcButtonKind.accent,
              ),
            ],
          ),
          _CalcRow(
            buttons: [
              _CalcButton(label: '0', onTap: () => _digit('0')),
              _CalcButton(label: '.', onTap: _decimal),
              _CalcButton(
                label: '=',
                onTap: _equals,
                kind: _CalcButtonKind.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({required this.buttons});

  final List<_CalcButton> buttons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (final button in buttons) ...[
            Expanded(child: button),
            if (button != buttons.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

enum _CalcButtonKind { number, muted, accent, primary }

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.onTap,
    this.kind = _CalcButtonKind.number,
  });

  final String label;
  final VoidCallback onTap;
  final _CalcButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    switch (kind) {
      case _CalcButtonKind.number:
        background = _notesBackground;
        foreground = _notesInk;
        break;
      case _CalcButtonKind.muted:
        background = _notesLine;
        foreground = _notesInk;
        break;
      case _CalcButtonKind.accent:
        background = _notesAccent.withValues(alpha: 0.14);
        foreground = _notesAccent;
        break;
      case _CalcButtonKind.primary:
        background = _notesPrimary;
        foreground = Colors.white;
        break;
    }
    return AspectRatio(
      aspectRatio: 1.3,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
