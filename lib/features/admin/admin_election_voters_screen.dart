// lib/features/admin/presentation/screens/admin_election_voters_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/admin/voters_import_sheet.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/models/models.dart';
// import '../../../../shared/widgets/shared_widgets.dart';

class AdminElectionVotersScreen extends ConsumerStatefulWidget {
  final String electionId;
  const AdminElectionVotersScreen({super.key, required this.electionId});

  @override
  ConsumerState<AdminElectionVotersScreen> createState() =>
      _AdminElectionVotersScreenState();
}

class _AdminElectionVotersScreenState
    extends ConsumerState<AdminElectionVotersScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  bool _adding = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() {
        _search = _searchController.text.toLowerCase();
      }),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addVoter() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    if (email.isEmpty || name.isEmpty) {
      setState(() {
        _error = 'Email and name are both required.';
      });
      return;
    }
    if (!email.contains('@')) {
      setState(() {
        _error = 'Enter a valid email address.';
      });
      return;
    }
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      await ref
          .read(supabaseServiceProvider)
          .addVoter(
            electionId: widget.electionId,
            email: email,
            fullName: name,
          );
      _emailController.clear();
      _nameController.clear();
      ref.refresh(electionVotersProvider(widget.electionId));
    } catch (e) {
      setState(() {
        _error = e.toString().contains('duplicate')
            ? 'This email is already on the voter list.'
            : 'Failed to add voter.';
      });
    } finally {
      if (mounted)
        setState(() {
          _adding = false;
        });
    }
  }

  Future<void> _removeVoter(String voterId) async {
    await ref.read(supabaseServiceProvider).removeVoter(voterId);
    ref.refresh(electionVotersProvider(widget.electionId));
  }

  Future<void> _openImport() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoterImportSheet(electionId: widget.electionId),
    );
    if (result == true) {
      ref.refresh(electionVotersProvider(widget.electionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final votersAsync = ref.watch(electionVotersProvider(widget.electionId));
    final electionAsync = ref.watch(electionProvider(widget.electionId));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // Header bar
          Container(
            color: AppTheme.cardBg,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/admin'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: electionAsync.when(
                    data: (e) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Text(
                              'Voter List',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusChip(status: e.status),
                          ],
                        ),
                      ],
                    ),
                    loading: () => const Text('Voter List'),
                    error: (_, __) => const Text('Voter List'),
                  ),
                ),
                TextButton.icon(
                  onPressed: _openImport,
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: const Text('Import CSV'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ResponsiveScaffoldBody(
              child: votersAsync.when(
                loading: () => const LoadingState(),
                error: (e, _) => ErrorState(message: e.toString()),
                data: (voters) {
                  final filtered = _search.isEmpty
                      ? voters
                      : voters
                            .where(
                              (v) =>
                                  v.fullName.toLowerCase().contains(_search) ||
                                  v.email.toLowerCase().contains(_search),
                            )
                            .toList();

                  return CustomScrollView(
                    slivers: [
                      // Add voter
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Add Voter',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${voters.length} total',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (_error != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.danger.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AppTheme.danger,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Full Name',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _adding ? null : _addVoter,
                                    icon: _adding
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person_add,
                                            size: 16,
                                          ),
                                    label: Text(
                                      _adding ? 'Adding...' : 'Add Voter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Search bar
                      if (voters.length > 6)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search voters...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                isDense: true,
                                suffixIcon: _search.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () =>
                                            _searchController.clear(),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),

                      if (filtered.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                _search.isNotEmpty
                                    ? 'No voters match "$_search".'
                                    : 'No voters on this list yet.',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((_, i) {
                            final v = filtered[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  child: Text(
                                    v.fullName.isNotEmpty
                                        ? v.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  v.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  v.email,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppTheme.danger,
                                    size: 20,
                                  ),
                                  onPressed: () => _removeVoter(v.id),
                                  tooltip: 'Remove voter',
                                ),
                              ),
                            );
                          }, childCount: filtered.length),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
