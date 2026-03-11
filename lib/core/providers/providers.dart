// lib/core/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
// import '../../shared/models/models.dart';

// ─── SERVICE ──────────────────────────────────────────────────────────────────

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// ─── AUTH ─────────────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseServiceProvider).authStateChanges;
});

final currentUserProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState.session == null) return null;
  return ref.read(supabaseServiceProvider).getCurrentUserProfile();
});

// ─── ELECTIONS (voter-facing) ─────────────────────────────────────────────────

/// Elections the logged-in voter is eligible for (published, active, closed)
final myElectionsProvider = FutureProvider<List<ElectionModel>>((ref) async {
  return ref.read(supabaseServiceProvider).getMyElections();
});

final electionProvider =
    FutureProvider.family<ElectionModel, String>((ref, electionId) async {
  return ref.read(supabaseServiceProvider).getElection(electionId);
});

// ─── VOTING ───────────────────────────────────────────────────────────────────

final myVoterRecordProvider =
    FutureProvider.family<VoterModel?, String>((ref, electionId) async {
  return ref.read(supabaseServiceProvider).getMyVoterRecord(electionId);
});

final votedPositionsProvider =
    FutureProvider.family<List<String>, String>((ref, electionId) async {
  return ref.read(supabaseServiceProvider).getVotedPositions(electionId);
});

// ─── RESULTS ──────────────────────────────────────────────────────────────────

final electionResultsProvider =
    FutureProvider.family<List<TallyResult>, String>((ref, electionId) async {
  return ref.read(supabaseServiceProvider).getElectionResults(electionId);
});

final voterTurnoutProvider =
    FutureProvider.family<int, String>((ref, electionId) async {
  return ref.read(supabaseServiceProvider).getVoterTurnout(electionId);
});

final electionVoterCountProvider =
    FutureProvider.family<int, String>((ref, electionId) async {
  return ref.read(supabaseServiceProvider).getElectionVoterCount(electionId);
});

// ─── ADMIN ────────────────────────────────────────────────────────────────────

final allElectionsProvider = FutureProvider<List<ElectionModel>>((ref) async {
  return ref.read(supabaseServiceProvider).getAllElections();
});

final electionVotersProvider =
    FutureProvider.family<List<VoterModel>, String>((ref, electionId) async {
  return ref.read(supabaseServiceProvider).getElectionVoters(electionId);
});
