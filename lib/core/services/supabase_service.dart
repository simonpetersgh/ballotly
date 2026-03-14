// lib/core/services/supabase_service.dart
import 'package:myapp/core/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;

  // ─── AUTH STATE ───────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ─── VOTER AUTH (OTP only) ────────────────────────────────────────────────

  /// Voter auth — single method for both new and returning users.
  /// Supabase creates the auth record on first use, reuses it on subsequent calls.
  Future<void> voterSendOtp(String email) async {
    await _client.auth.signInWithOtp(email: email, shouldCreateUser: true);
  }

  /// Voter sign up — email + OTP, no password.
  /// Checks no account exists yet then sends OTP.
  Future<void> voterSignUp({
    required String email,
    required String fullName,
  }) async {
    final existing = await _client
        .from(SupabaseConstants.userProfilesTable)
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (existing != null) {
      throw Exception(
        'An account with this email already exists. Please sign in.',
      );
    }

    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
      data: {
        'full_name': fullName,
        // 'account_type': SupabaseConstants.accountTypeVoter,
      },
    );
  }

  /// Voter sign in — email + OTP.
  /// Checks account exists first.
  Future<void> voterSignIn(String email) async {
    final existing = await _client
        .from(SupabaseConstants.userProfilesTable)
        .select('id, account_type')
        .eq('email', email)
        .maybeSingle();

    if (existing == null) {
      throw Exception(
        'No account found for this email. Please register first.',
      );
    }

    await _client.auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  /// Verify OTP — works for both voter sign up and sign in.
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  // ─── ORGANISER AUTH (email + password + OTP confirm) ──────────────────────

  /// Organiser sign up — email + password.
  /// Supabase sends OTP confirmation email automatically.
  Future<void> organiserSignUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final existing = await _client
        .from(SupabaseConstants.userProfilesTable)
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (existing != null) {
      throw Exception('An account with this email already exists.');
    }

    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        // 'account_type': SupabaseConstants.accountTypeOrganiser,
      },
      emailRedirectTo: null, // we handle OTP confirm in-app
    );
  }

  /// Verify organiser email confirmation OTP after sign up.
  Future<AuthResponse> verifyOrganiserOtp({
    required String email,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  /// Organiser sign in — email + password only.
  Future<AuthResponse> organiserSignIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Create user_profile record after successful auth.
  /// Called once after OTP verify on both voter and organiser registration.
  Future<void> createUserProfile({
    required String fullName,
    required String accountType,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user.');

    await _client.from(SupabaseConstants.userProfilesTable).upsert({
      'id': user.id,
      'email': user.email,
      'full_name': fullName,
      // date created will be set automatically
      // 'account_type': accountType,
    });
  }

  Future<void> signOut() async => await _client.auth.signOut();

  // ─── USER PROFILE ─────────────────────────────────────────────────────────

  Future<UserProfileModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from(SupabaseConstants.userProfilesTable)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserProfileModel.fromJson(data);
  }

  // ─── ELECTIONS (voter-facing) ──────────────────────────────────────────────

  /// Returns elections the logged-in voter is eligible for.
  /// Only returns published, active, and closed elections.
  Future<List<ElectionModel>> getMyElections() async {
    final user = currentUser;
    if (user == null) return [];

    // Get election IDs this voter is eligible for
    final voterRows = await _client
        .from(SupabaseConstants.votersTable)
        .select('election_id')
        .eq('email', user.email!);

    final electionIds = (voterRows as List)
        .map((v) => v['election_id'] as String)
        .toList();

    if (electionIds.isEmpty) return [];

    final data = await _client
        .from(SupabaseConstants.electionsTable)
        .select('*, positions(*, candidates(*))')
        .inFilter('id', electionIds)
        .inFilter('status', ['published', 'active', 'closed'])
        .order('created_at', ascending: false);

    return (data as List).map((e) => ElectionModel.fromJson(e)).toList();
  }

  Future<ElectionModel> getElection(String electionId) async {
    final data = await _client
        .from(SupabaseConstants.electionsTable)
        .select('*, positions(*, candidates(*))')
        .eq('id', electionId)
        .single();

    return ElectionModel.fromJson(data);
  }

  // ─── ELECTIONS (admin-facing) ──────────────────────────────────────────────
/// Returns all elections created by the current user (My Elections).
  Future<List<ElectionModel>> getMyCreatedElections() async {
    final user = currentUser;
    if (user == null) return [];
    final data = await _client
        .from(SupabaseConstants.electionsTable)
        .select('*, positions(*, candidates(*))')
        .eq('created_by', user.id)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ElectionModel.fromJson(e)).toList();
  }

  Future<List<ElectionModel>> getAllElections() async {
    final data = await _client
        .from(SupabaseConstants.electionsTable)
        .select('*, positions(*, candidates(*))')
        .order('created_at', ascending: false);

    return (data as List).map((e) => ElectionModel.fromJson(e)).toList();
  }

  /// Step 1 — Create election shell. Returns election with just basic details.
  Future<ElectionModel> createElection({
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final user = currentUser!;
    final data = await _client
        .from(SupabaseConstants.electionsTable)
        .insert({
          'title': title,
          'description': description,
          'status': SupabaseConstants.statusDraft,
          'starts_at': startsAt.toIso8601String(),
          'ends_at': endsAt.toIso8601String(),
          'created_by': user.id,
        })
        .select()
        .single();

    return ElectionModel.fromJson({...data, 'positions': []});
  }

  /// Update election basic details — works as long as status is draft.
  Future<void> updateElectionDetails({
    required String electionId,
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await _client
        .from(SupabaseConstants.electionsTable)
        .update({
          'title': title,
          'description': description,
          'starts_at': startsAt.toIso8601String(),
          'ends_at': endsAt.toIso8601String(),
        })
        .eq('id', electionId)
        .eq('status', SupabaseConstants.statusDraft);
  }

  /// Update election verification settings.
  /// verificationMode: 'manual' | 'otp'
  /// secondaryTokenEnabled: whether voters must supply a secondary token.
  ///
  /// PREMIUM GATE (commented out — uncomment when payment is integrated):
  // Future<void> updateElectionVerification({...}) async {
  //   if (mode == 'otp') {
  //     final paid = await _isElectionPaid(electionId);
  //     if (!paid) throw PremiumRequiredException('OTP verification requires a paid election.');
  //   }
  // }
  Future<void> updateElectionVerification({
    required String electionId,
    required String verificationMode,
    required bool secondaryTokenEnabled,
  }) async {
    await _client
        .from(SupabaseConstants.electionsTable)
        .update({
          'verification_mode': verificationMode,
          'secondary_token_enabled': secondaryTokenEnabled,
        })
        .eq('id', electionId);
  }

  /// Update election status — handles all manual transitions.
  Future<void> updateElectionStatus(String electionId, String status) async {
    await _client
        .from(SupabaseConstants.electionsTable)
        .update({'status': status})
        .eq('id', electionId);
  }

  Future<void> deleteElection(String electionId) async {
    await _client
        .from(SupabaseConstants.electionsTable)
        .delete()
        .eq('id', electionId)
        .eq('status', SupabaseConstants.statusDraft); // only draft elections
  }

  // ─── POSITIONS ────────────────────────────────────────────────────────────

  Future<PositionModel> createPosition({
    required String electionId,
    required String title,
    required int displayOrder,
  }) async {
    final data = await _client
        .from(SupabaseConstants.positionsTable)
        .insert({
          'election_id': electionId,
          'title': title,
          'display_order': displayOrder,
        })
        .select()
        .single();

    return PositionModel.fromJson({...data, 'candidates': []});
  }

  Future<void> updatePosition({
    required String positionId,
    required String title,
    required int displayOrder,
  }) async {
    await _client
        .from(SupabaseConstants.positionsTable)
        .update({'title': title, 'display_order': displayOrder})
        .eq('id', positionId);
  }

  Future<void> deletePosition(String positionId) async {
    await _client
        .from(SupabaseConstants.positionsTable)
        .delete()
        .eq('id', positionId);
  }

  // ─── CANDIDATES ───────────────────────────────────────────────────────────

  Future<CandidateModel> createCandidate({
    required String positionId,
    required String name,
    String? bio,
    String? photoUrl,
    int? ballotNumber,
  }) async {
    final data = await _client
        .from(SupabaseConstants.candidatesTable)
        .insert({
          'position_id': positionId,
          'name': name,
          'bio': bio,
          'photo_url': photoUrl,
          'ballot_number': ballotNumber,
        })
        .select()
        .single();

    return CandidateModel.fromJson(data);
  }

  Future<void> updateCandidate({
    required String candidateId,
    required String name,
    String? bio,
    String? photoUrl,
    int? ballotNumber,
  }) async {
    await _client
        .from(SupabaseConstants.candidatesTable)
        .update({
          'name': name,
          'bio': bio,
          'photo_url': photoUrl,
          'ballot_number': ballotNumber,
        })
        .eq('id', candidateId);
  }

  Future<void> deleteCandidate(String candidateId) async {
    await _client
        .from(SupabaseConstants.candidatesTable)
        .delete()
        .eq('id', candidateId);
  }

  // ─── VOTERS (election eligibility) ────────────────────────────────────────

  /// Look up a voter by email + primary token (+ optional secondary token).
  /// Used by guest manual verification and logged-in voter token confirmation.
  Future<VoterModel?> getVoterByToken({
    required String electionId,
    required String email,
    required String primaryToken,
    String? secondaryToken,
  }) async {
    var query = _client
        .from(SupabaseConstants.votersTable)
        .select()
        .eq('election_id', electionId)
        .eq('email', email.trim().toLowerCase())
        .eq('primary_token', primaryToken.trim());

    if (secondaryToken != null && secondaryToken.isNotEmpty) {
      query = query.eq('secondary_token', secondaryToken.trim());
    }

    final data = await query.maybeSingle();
    if (data == null) return null;
    return VoterModel.fromJson(data);
  }

  // ─── VOTING ───────────────────────────────────────────────────────────────


  Future<List<VoterModel>> getElectionVoters(String electionId) async {
    final data = await _client
        .from(SupabaseConstants.votersTable)
        .select()
        .eq('election_id', electionId)
        .order('added_at', ascending: false);

    return (data as List).map((v) => VoterModel.fromJson(v)).toList();
  }

  Future<VoterModel> addVoter({
    required String electionId,
    required String email,
    required String fullName,
    String? primaryToken,
    String? secondaryToken
  }) async {
    final user = currentUser!;
    final data = await _client
        .from(SupabaseConstants.votersTable)
        .insert({
          'election_id': electionId,
          'email': email.toLowerCase().trim(),
          'full_name': fullName,
          'added_by': user.id,
        })
        .select()
        .single();

    return VoterModel.fromJson(data);
  }

  Future<void> removeVoter(String voterId) async {
    await _client
        .from(SupabaseConstants.votersTable)
        .delete()
        .eq('id', voterId);
  }

  Future<void> importVoters({
    required String electionId,
    required List<Map<String, String>> voters, // [{email, full_name}]
  }) async {
    final user = currentUser!;
    final rows = voters
        .map(
          (v) => {
            'election_id': electionId,
            'email': v['email']!.toLowerCase().trim(),
            'full_name': v['full_name']!,
            'added_by': user.id,
          },
        )
        .toList();

    await _client
        .from(SupabaseConstants.votersTable)
        .upsert(rows, onConflict: 'election_id,email'); // skip duplicates
  }

  // ─── VOTING ───────────────────────────────────────────────────────────────

  /// Returns the voter eligibility record for the current user in an election.
  Future<VoterModel?> getMyVoterRecord(String electionId) async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from(SupabaseConstants.votersTable)
        .select()
        .eq('election_id', electionId)
        .eq('email', user.email!)
        .maybeSingle();

    if (data == null) return null;
    return VoterModel.fromJson(data);
  }

  /// Returns position IDs the current voter has already voted in.
  Future<List<String>> getVotedPositions(String electionId) async {
    final voter = await getMyVoterRecord(electionId);
    if (voter == null) return [];

    final data = await _client
        .from(SupabaseConstants.votesTable)
        .select('position_id')
        .eq('voter_id', voter.id);

    return (data as List).map((v) => v['position_id'] as String).toList();
  }

  Future<void> castVote({
    required String voterId,
    required String positionId,
    required String candidateId,
  }) async {
    await _client.from(SupabaseConstants.votesTable).insert({
      'voter_id': voterId,
      'position_id': positionId,
      'candidate_id': candidateId,
    });

    await _client.from(SupabaseConstants.auditLogTable).insert({
      'event_type': 'vote_cast',
      'actor_id': currentUser?.id,
      'metadata': {'position_id': positionId},
    });
  }

  // ─── RESULTS ──────────────────────────────────────────────────────────────

  Future<List<TallyResult>> getElectionResults(String electionId) async {
    final positionsData = await _client
        .from(SupabaseConstants.positionsTable)
        .select('*, candidates(*)')
        .eq('election_id', electionId)
        .order('display_order');

    final positionIds = (positionsData as List)
        .map((p) => p['id'] as String)
        .toList();

    if (positionIds.isEmpty) return [];

    final votesData = await _client
        .from(SupabaseConstants.votesTable)
        .select('position_id, candidate_id')
        .inFilter('position_id', positionIds);

    final results = <TallyResult>[];

    for (final position in positionsData) {
      final positionId = position['id'] as String;
      final candidates = (position['candidates'] as List? ?? []);

      final voteCounts = <String, int>{
        for (final c in candidates) c['id'] as String: 0,
      };

      for (final vote in (votesData as List)) {
        if (vote['position_id'] == positionId) {
          final cId = vote['candidate_id'] as String;
          voteCounts[cId] = (voteCounts[cId] ?? 0) + 1;
        }
      }

      final totalVotes = voteCounts.values.fold(0, (a, b) => a + b);

      final tallies = candidates.map((c) {
        final count = voteCounts[c['id']] ?? 0;
        return CandidateTally(
          candidateId: c['id'],
          candidateName: c['name'],
          photoUrl: c['photo_url'],
          ballotNumber: c['ballot_number'],
          voteCount: count,
          percentage: totalVotes > 0 ? (count / totalVotes) * 100 : 0,
        );
      }).toList()..sort((a, b) => b.voteCount.compareTo(a.voteCount));

      results.add(
        TallyResult(
          positionId: positionId,
          positionTitle: position['title'],
          candidates: tallies,
        ),
      );
    }

    return results;
  }

  Future<int> getVoterTurnout(String electionId) async {
    final positionIds = await _getPositionIds(electionId);
    if (positionIds.isEmpty) return 0;

    final data = await _client
        .from(SupabaseConstants.votesTable)
        .select('voter_id')
        .inFilter('position_id', positionIds);

    return ((data as List).map((v) => v['voter_id']).toSet()).length;
  }

  Future<int> getElectionVoterCount(String electionId) async {
    final data = await _client
        .from(SupabaseConstants.votersTable)
        .select('id')
        .eq('election_id', electionId)
        .count(CountOption.exact);

    return data.count;
  }

  Future<List<String>> _getPositionIds(String electionId) async {
    final data = await _client
        .from(SupabaseConstants.positionsTable)
        .select('id')
        .eq('election_id', electionId);

    return (data as List).map((p) => p['id'] as String).toList();
  }

  // ─── ADMIN USERS ──────────────────────────────────────────────────────────

  // Future<List<UserProfileModel>> getAllOrganisers() async {
  //   final data = await _client
  //       .from(SupabaseConstants.userProfilesTable)
  //       .select()
  //       .eq('account_type', SupabaseConstants.accountTypeOrganiser)
  //       .order('created_at', ascending: false);

  //   return (data as List).map((v) => UserProfileModel.fromJson(v)).toList();
  // }

  // ─── GUEST / PUBLIC ───────────────────────────────────────────────────────

  /// Look up a published/active/closed election by its short code.
  /// Returns null if code is not found or election is in draft.
  Future<ElectionModel?> getElectionByCode(String code) async {
    final data = await _client
        .from(SupabaseConstants.electionsTable)
        .select('*, positions(*, candidates(*))')
        .eq('code', code.trim().toUpperCase())
        .inFilter('status', ['published', 'active', 'closed'])
        .maybeSingle();

    if (data == null) return null;
    return ElectionModel.fromJson(data);
  }

  /// Returns the voter record for a given email + electionId.
  /// Used by guest flow after OTP verification to confirm eligibility.
  Future<VoterModel?> getVoterByEmail({
    required String electionId,
    required String email,
  }) async {
    final data = await _client
        .from(SupabaseConstants.votersTable)
        .select()
        .eq('election_id', electionId)
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();

    if (data == null) return null;
    return VoterModel.fromJson(data);
  }

  /// Returns position IDs already voted for by a voter record ID.
  /// Used in guest flow (same as getVotedPositions but by voterId directly).
  Future<List<String>> getVotedPositionsByVoterId(String voterId) async {
    final data = await _client
        .from(SupabaseConstants.votesTable)
        .select('position_id')
        .eq('voter_id', voterId);

    return (data as List).map((v) => v['position_id'] as String).toList();
  }

  /// Public results — no auth required. Only works for closed elections.
  Future<List<TallyResult>> getPublicElectionResults(String electionId) async {
    // Re-uses the same tally logic; RLS must allow anon reads on closed elections.
    return getElectionResults(electionId);
  }
}
