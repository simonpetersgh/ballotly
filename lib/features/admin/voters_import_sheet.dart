// lib/features/admin/presentation/screens/admin_election_voters_screen.dart
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';

// ─── VOTER IMPORT SHEET ─────────────────────────────────────────────────────────────

enum _ImportStep { pick, map, preview, importing, done }

class VoterImportSheet extends StatefulWidget {
  final String electionId;
  const VoterImportSheet({required this.electionId});

  @override
  State<VoterImportSheet> createState() => VoterImportSheetState();
}

class VoterImportSheetState extends State<VoterImportSheet> {
  _ImportStep _step = _ImportStep.pick;

  List<String> _headers = [];
  List<List<String>> _rows = [];

  String? _emailCol;
  String? _nameCol;

  List<Map<String, String>> _valid = [];
  List<Map<String, String>> _invalid = [];

  String? _pickError;
  String? _importError;
  int _importedCount = 0;

  // ── Pick ──────────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() => _pickError = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        setState(() => _pickError = 'Could not read file.');
        return;
      }
      _parseCSV(utf8.decode(bytes));
    } catch (e) {
      setState(() => _pickError = 'Failed to open file: $e');
    }
  }

  void _parseCSV(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.length < 2) {
      setState(
        () => _pickError =
            'CSV must have a header row and at least one data row.',
      );
      return;
    }

    final headers = _splitLine(lines[0]);
    if (headers.length < 2) {
      setState(() => _pickError = 'CSV must have at least 2 columns.');
      return;
    }

    final rows = lines.skip(1).map(_splitLine).toList();

    // Auto-detect columns
    String? detectedEmail;
    String? detectedName;
    for (final h in headers) {
      final l = h.toLowerCase().trim();
      if (detectedEmail == null &&
          (l.contains('email') || l.contains('e-mail'))) {
        detectedEmail = h;
      }
      if (detectedName == null &&
          (l.contains('name') ||
              l.contains('full') ||
              l.contains('student') ||
              l.contains('member'))) {
        detectedName = h;
      }
    }

    setState(() {
      _headers = headers;
      _rows = rows;
      _emailCol = detectedEmail;
      _nameCol = detectedName;
      _step = _ImportStep.map;
      _pickError = null;
    });
  }

  List<String> _splitLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString().trim());
    return result;
  }

  // ── Map → Preview ─────────────────────────────────────────────────────────

  void _buildPreview() {
    final ei = _headers.indexOf(_emailCol!);
    final ni = _headers.indexOf(_nameCol!);

    final mapped = _rows
        .map(
          (r) => {
            'email': (ei < r.length ? r[ei] : '').trim().toLowerCase(),
            'full_name': (ni < r.length ? r[ni] : '').trim(),
          },
        )
        .toList();

    setState(() {
      _valid = mapped
          .where(
            (r) =>
                r['email']!.contains('@') &&
                r['email']!.isNotEmpty &&
                r['full_name']!.isNotEmpty,
          )
          .toList();
      _invalid = mapped
          .where(
            (r) =>
                !r['email']!.contains('@') ||
                r['email']!.isEmpty ||
                r['full_name']!.isEmpty,
          )
          .toList();
      _step = _ImportStep.preview;
    });
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _import(WidgetRef ref) async {
    setState(() {
      _step = _ImportStep.importing;
      _importError = null;
    });
    try {
      await ref
          .read(supabaseServiceProvider)
          .importVoters(electionId: widget.electionId, voters: _valid);
      setState(() {
        _importedCount = _valid.length;
        _step = _ImportStep.done;
      });
    } catch (e) {
      setState(() {
        _importError = e.toString().replaceFirst('Exception: ', '');
        _step = _ImportStep.preview;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.upload_file_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _stepTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () =>
                          Navigator.pop(context, _step == _ImportStep.done),
                    ),
                  ],
                ),
              ),

              // Step dots
              if (_step != _ImportStep.done && _step != _ImportStep.importing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: _StepIndicator(current: _step),
                ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildBody(ref),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _stepTitle {
    switch (_step) {
      case _ImportStep.pick:
        return 'Import Voters from CSV';
      case _ImportStep.map:
        return 'Map Columns';
      case _ImportStep.preview:
        return 'Preview Import';
      case _ImportStep.importing:
        return 'Importing...';
      case _ImportStep.done:
        return 'Import Complete';
    }
  }

  Widget _buildBody(WidgetRef ref) {
    switch (_step) {
      case _ImportStep.pick:
        return _pickBody();
      case _ImportStep.map:
        return _mapBody();
      case _ImportStep.preview:
        return _previewBody(ref);
      case _ImportStep.importing:
        return _importingBody();
      case _ImportStep.done:
        return _doneBody();
    }
  }

  // ── Pick body ─────────────────────────────────────────────────────────────

  Widget _pickBody() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CSV Format',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your file must have columns for email and full name. '
                'Extra columns are fine — you will map the right ones in the next step.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'id,full_name,email,department\n'
                  '1,Kwame Mensah,kwame@uni.edu.gh,CS\n'
                  '2,Ama Owusu,ama@uni.edu.gh,Law',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_pickError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _pickError!,
              style: const TextStyle(color: AppTheme.danger, fontSize: 13),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: const Text('Choose CSV File'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Map body ──────────────────────────────────────────────────────────────

  Widget _mapBody() {
    final canProceed =
        _emailCol != null && _nameCol != null && _emailCol != _nameCol;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_rows.length} data rows found. Select which column contains each field.',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        _ColumnDropdown(
          label: 'Email column',
          hint: 'Column with email addresses',
          icon: Icons.email_outlined,
          value: _emailCol,
          headers: _headers,
          onChanged: (v) => setState(() => _emailCol = v),
        ),
        const SizedBox(height: 14),

        _ColumnDropdown(
          label: 'Full name column',
          hint: 'Column with full names',
          icon: Icons.person_outline_rounded,
          value: _nameCol,
          headers: _headers,
          onChanged: (v) => setState(() => _nameCol = v),
        ),

        if (_emailCol != null && _nameCol != null && _emailCol == _nameCol)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Email and name cannot be the same column.',
              style: TextStyle(color: AppTheme.danger, fontSize: 12),
            ),
          ),

        const SizedBox(height: 20),

        // Raw preview
        const Text(
          'File preview (first 3 rows):',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _TableRow(cells: _headers, isHeader: true),
              ..._rows.take(3).map((r) => _TableRow(cells: r)),
              if (_rows.length > 3)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '...and ${_rows.length - 3} more rows',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = _ImportStep.pick),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: canProceed ? _buildPreview : null,
                child: const Text('Preview'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Preview body ──────────────────────────────────────────────────────────

  Widget _previewBody(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SummaryChip(
              count: _valid.length,
              label: 'will import',
              color: AppTheme.success,
            ),
            const SizedBox(width: 8),
            if (_invalid.isNotEmpty)
              _SummaryChip(
                count: _invalid.length,
                label: 'will skip',
                color: AppTheme.danger,
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_importError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _importError!,
              style: const TextStyle(color: AppTheme.danger, fontSize: 13),
            ),
          ),

        if (_valid.isNotEmpty) ...[
          const Text(
            'Valid — will be imported',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _valid.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppTheme.border),
              itemBuilder: (_, i) {
                final v = _valid[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.success,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          v['full_name']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        v['email']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_invalid.isNotEmpty) ...[
          const Text(
            'Will be skipped — invalid data',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.danger,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.04),
              border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _invalid.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppTheme.danger.withOpacity(0.1)),
              itemBuilder: (_, i) {
                final v = _invalid[i];
                final reason = v['email']!.isEmpty
                    ? 'Missing email'
                    : !v['email']!.contains('@')
                    ? 'Invalid email'
                    : 'Missing name';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.danger,
                        size: 15,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${v['full_name']!.isEmpty ? '(no name)' : v['full_name']!}  ·  '
                          '${v['email']!.isEmpty ? '(no email)' : v['email']!}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = _ImportStep.map),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _valid.isEmpty ? null : () => _import(ref),
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: Text('Import ${_valid.length}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Importing body ────────────────────────────────────────────────────────

  Widget _importingBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Importing ${_valid.length} voters...',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Done body ─────────────────────────────────────────────────────────────

  Widget _doneBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.success,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$_importedCount voters imported',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          if (_invalid.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${_invalid.length} rows skipped.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Done'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── SMALL WIDGETS ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final _ImportStep current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = [_ImportStep.pick, _ImportStep.map, _ImportStep.preview];
    final labels = ['Pick file', 'Map columns', 'Preview'];
    final idx = steps.indexOf(current);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < idx;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppTheme.primary : AppTheme.border,
            ),
          );
        }
        final si = i ~/ 2;
        final done = si < idx;
        final active = si == idx;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done || active ? AppTheme.primary : AppTheme.cardBg,
                border: Border.all(
                  color: done || active ? AppTheme.primary : AppTheme.border,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        '${si + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[si],
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ColumnDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> headers;
  final ValueChanged<String?> onChanged;

  const _ColumnDropdown({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.headers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items: headers
              .map((h) => DropdownMenuItem(value: h, child: Text(h)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  const _TableRow({required this.cells, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isHeader ? AppTheme.primary.withOpacity(0.05) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: cells
            .take(4)
            .map(
              (c) => Expanded(
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
                    color: isHeader
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
