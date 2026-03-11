// lib/core/constants/supabase_constants.dart

class SupabaseConstants {
  static const String supabaseUrl = 'https://lobpbjijedsrmmnkmkdg.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_4f8wnnryvK50nS5yvIghzQ_sDLyUWJE';

  // Tables
  static const String userProfilesTable = 'user_profiles';
  static const String votersTable = 'voters'; // election eligibility
  static const String electionsTable = 'elections';
  static const String positionsTable = 'positions';
  static const String candidatesTable = 'candidates';
  static const String votesTable = 'votes';
  static const String auditLogTable = 'audit_log';

  // Account types
  static const String accountTypeVoter = 'voter';
  static const String accountTypeOrganiser = 'organiser';

  // Election statuses
  static const String statusDraft = 'draft';
  static const String statusPublished = 'published';
  static const String statusActive = 'active';
  static const String statusClosed = 'closed';
}
