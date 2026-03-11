// lib/shared/models/models.dart

// ─── USER PROFILE ─────────────────────────────────────────────────────────────

class UserProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String accountType; // 'voter' | 'organiser'
  final bool isAdmin;
  final DateTime createdAt;

  const UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.accountType,
    this.isAdmin = false,
    required this.createdAt,
  });

  bool get isOrganiser => accountType == 'organiser';
  bool get isVoter => accountType == 'voter';

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'],
        email: json['email'],
        fullName: json['full_name'],
        accountType: json['account_type'] ?? 'voter',
        isAdmin: json['is_admin'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );
}

// ─── VOTER (election eligibility) ─────────────────────────────────────────────

class VoterModel {
  final String id;
  final String electionId;
  final String email;
  final String fullName;
  final DateTime addedAt;

  const VoterModel({
    required this.id,
    required this.electionId,
    required this.email,
    required this.fullName,
    required this.addedAt,
  });

  factory VoterModel.fromJson(Map<String, dynamic> json) => VoterModel(
        id: json['id'],
        electionId: json['election_id'],
        email: json['email'],
        fullName: json['full_name'],
        addedAt: DateTime.parse(json['added_at']),
      );

  Map<String, dynamic> toJson() => {
        'election_id': electionId,
        'email': email,
        'full_name': fullName,
      };
}

// ─── ELECTION ─────────────────────────────────────────────────────────────────

class ElectionModel {
  final String id;
  final String title;
  final String? description;
  final String status; // draft | published | active | closed
  final DateTime startsAt;
  final DateTime endsAt;
  final String createdBy;
  final DateTime createdAt;
  final List<PositionModel> positions;
  final String? code; // Election entry code for guest voting

  const ElectionModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.createdBy,
    required this.createdAt,
    this.positions = const [],
    this.code,
  });

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';
  bool get isVisibleToVoters =>
      status == 'published' || status == 'active' || status == 'closed';

  factory ElectionModel.fromJson(Map<String, dynamic> json) => ElectionModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        status: json['status'],
        startsAt: DateTime.parse(json['starts_at']),
        endsAt: DateTime.parse(json['ends_at']),
        createdBy: json['created_by'],
        createdAt: DateTime.parse(json['created_at']),
        code: json['code'],
        positions: (json['positions'] as List<dynamic>? ?? [])
            .map((p) => PositionModel.fromJson(p))
            .toList(),
      );
}

// ─── POSITION ─────────────────────────────────────────────────────────────────

class PositionModel {
  final String id;
  final String electionId;
  final String title;
  final int displayOrder;
  final List<CandidateModel> candidates;

  const PositionModel({
    required this.id,
    required this.electionId,
    required this.title,
    required this.displayOrder,
    this.candidates = const [],
  });

  /// Candidates sorted by ballot_number if set, otherwise insertion order
  List<CandidateModel> get sortedCandidates {
    final hasBallot = candidates.any((c) => c.ballotNumber != null);
    if (!hasBallot) return candidates;
    final sorted = [...candidates];
    sorted.sort((a, b) {
      if (a.ballotNumber == null && b.ballotNumber == null) return 0;
      if (a.ballotNumber == null) return 1;
      if (b.ballotNumber == null) return -1;
      return a.ballotNumber!.compareTo(b.ballotNumber!);
    });
    return sorted;
  }

  factory PositionModel.fromJson(Map<String, dynamic> json) => PositionModel(
        id: json['id'],
        electionId: json['election_id'],
        title: json['title'],
        displayOrder: json['display_order'] ?? 0,
        candidates: (json['candidates'] as List<dynamic>? ?? [])
            .map((c) => CandidateModel.fromJson(c))
            .toList(),
      );
}

// ─── CANDIDATE ────────────────────────────────────────────────────────────────

class CandidateModel {
  final String id;
  final String positionId;
  final String name;
  final String? bio;
  final String? photoUrl;
  final int? ballotNumber; // Optional — displayed as "1", "2", "3" on ballot

  const CandidateModel({
    required this.id,
    required this.positionId,
    required this.name,
    this.bio,
    this.photoUrl,
    this.ballotNumber,
  });

  factory CandidateModel.fromJson(Map<String, dynamic> json) => CandidateModel(
        id: json['id'],
        positionId: json['position_id'],
        name: json['name'],
        bio: json['bio'],
        photoUrl: json['photo_url'],
        ballotNumber: json['ballot_number'],
      );
}

// ─── VOTE ─────────────────────────────────────────────────────────────────────

class VoteModel {
  final String id;
  final String voterId;
  final String positionId;
  final String candidateId;
  final DateTime submittedAt;

  const VoteModel({
    required this.id,
    required this.voterId,
    required this.positionId,
    required this.candidateId,
    required this.submittedAt,
  });

  factory VoteModel.fromJson(Map<String, dynamic> json) => VoteModel(
        id: json['id'],
        voterId: json['voter_id'],
        positionId: json['position_id'],
        candidateId: json['candidate_id'],
        submittedAt: DateTime.parse(json['submitted_at']),
      );
}

// ─── TALLY ────────────────────────────────────────────────────────────────────

class TallyResult {
  final String positionId;
  final String positionTitle;
  final List<CandidateTally> candidates; // sorted by vote count desc

  const TallyResult({
    required this.positionId,
    required this.positionTitle,
    required this.candidates,
  });

  int get totalVotes => candidates.fold(0, (sum, c) => sum + c.voteCount);
}

class CandidateTally {
  final String candidateId;
  final String candidateName;
  final String? photoUrl;
  final int? ballotNumber;
  final int voteCount;
  final double percentage;

  const CandidateTally({
    required this.candidateId,
    required this.candidateName,
    this.photoUrl,
    this.ballotNumber,
    required this.voteCount,
    required this.percentage,
  });
}
