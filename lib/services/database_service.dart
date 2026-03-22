import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/database_values.dart';
import '../core/enums.dart';
import '../core/pagination.dart';
import '../models/announcement_model.dart';
import '../models/gym_model.dart';
import '../models/client_profile_model.dart';
import '../models/food_log_model.dart';
import '../models/membership_model.dart';
import '../models/membership_counts.dart';
import '../models/subscription_model.dart';
import '../models/workout_plan_model.dart';

/// Database service wrapping Supabase queries.
///
/// Date windows passed into this service are treated as local app dates and
/// converted to UTC at the query boundary so that list/report filters remain
/// stable across time zones.
class DatabaseService {
  final SupabaseClient _client;

  DatabaseService(this._client);
 
  static const String _clientColumns =
      'id, user_id, gym_id, full_name, email, phone, age, sex, weight_kg, '
      'height_cm, goal, training_level, days_per_week, equipment, diet_type, '
      'restrictions, injuries, assigned_trainer_id, created_at, updated_at, '
      'training_time, medical_conditions, current_plan_phase, last_checkin_weight, '
      'weight_trend, sleep_quality, energy_level, adherence_percent, '
      'last_gym_visit, current_plan_name, assigned_trainer_name, language_preference';

  // ─── GYMS ─────────────────────────────────────────────────────────

  /// Create a new gym.
  Future<Gym> createGym({
    required String name,
    required String ownerId,
    String? address,
    String? city,
    String? phone,
  }) async {
    final data = await _client
        .from(AppConstants.gymsTable)
        .insert({
          'name': name,
          'owner_id': ownerId,
          'address': address,
          'city': city,
          'phone': phone,
        })
        .select()
        .single();

    // Also add the owner as a gym member so they can query tenant-scoped data.
    await _client.from(AppConstants.gymMembersTable).insert({
      'gym_id': data['id'],
      'user_id': ownerId,
      'role': DatabaseValues.gymMemberOwnerRole,
    });

    return Gym.fromJson(data);
  }

  /// Get unique cities where active gyms exist.
  Future<List<String>> getCities() async {
    final data = await _client
        .from(AppConstants.gymsTable)
        .select('city')
        .eq('is_active', true)
        .not('city', 'is', null);

    final cities = data.map((e) => e['city'] as String).toSet().toList();
    cities.sort();
    return cities;
  }

  /// Get active gyms in a specific city.
  Future<List<Gym>> getGymsByCity(String city) async {
    final data = await _client
        .from(AppConstants.gymsTable)
        .select()
        .eq('city', city)
        .eq('is_active', true)
        .order('name');
    
    return data.map((json) => Gym.fromJson(json)).toList();
  }

  /// Get gyms owned by a user.
  Future<List<Gym>> getGymsForOwner(String ownerId) async {
    final data = await _client
        .from(AppConstants.gymsTable)
        .select()
        .eq('owner_id', ownerId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return data.map((json) => Gym.fromJson(json)).toList();
  }

  /// Get gyms a user is a member of (any role).
  Future<List<Gym>> getGymsForUser(String userId) async {
    final memberData = await _client
        .from(AppConstants.gymMembersTable)
        .select('gym_id')
        .eq('user_id', userId);

    if (memberData.isEmpty) return [];

    final gymIds = memberData.map((m) => m['gym_id'] as String).toList();

    final gymData = await _client
        .from(AppConstants.gymsTable)
        .select()
        .inFilter('id', gymIds)
        .eq('is_active', true);

    return gymData.map((json) => Gym.fromJson(json)).toList();
  }

  /// Update gym details.
  Future<Gym> updateGym(Gym gym) async {
    final data = await _client
        .from(AppConstants.gymsTable)
        .update(gym.toJson())
        .eq('id', gym.id)
        .select()
        .single();

    return Gym.fromJson(data);
  }

  // ─── CLIENTS ──────────────────────────────────────────────────────

  /// Add a new client to a gym.
  Future<ClientProfile> addClient(ClientProfile client) async {
    final data = await _client
        .from(AppConstants.clientsTable)
        .insert(client.toJson()..remove('id'))
        .select(_clientColumns)
        .single();

    return ClientProfile.fromJson(data);
  }

  /// Get all clients for a gym.
  Future<List<ClientProfile>> getClientsForGym(String gymId) async {
    try {
      final data = await _client
          .from(AppConstants.clientsTable)
          .select(_clientColumns)
          .eq('gym_id', gymId)
          .order('created_at', ascending: false);

      return data.map((json) => ClientProfile.fromJson(json)).toList();
    } catch (e, stack) {
      debugPrint('❌ [getClientsForGym] ERROR for gym=$gymId: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Get paginated clients for a gym with server-side filters.
  ///
  /// This keeps search, goal filtering, and sort order consistent with explicit
  /// `limit`/`offset` paging so large gyms do not require loading the full list.
  Future<PagedResult<ClientProfile>> getClientsForGymPaged(
    String gymId, {
    int limit = 20,
    int offset = 0,
    String search = '',
    FitnessGoal? goalFilter,
    String sort = 'name_asc',
  }) async {
    dynamic applyFilters(
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    ) {
      var filtered = query.eq('gym_id', gymId);
      if (goalFilter != null) {
        filtered = filtered.eq('goal', goalFilter.value);
      }
      final trimmedSearch = search.trim();
      if (trimmedSearch.isNotEmpty) {
        final like = '%$trimmedSearch%';
        filtered = filtered.or(
          'full_name.ilike.$like,email.ilike.$like,phone.ilike.$like',
        );
      }
      return filtered;
    }

    try {
      var dataQuery = applyFilters(
        _client.from(AppConstants.clientsTable).select(_clientColumns),
      );
      var countQuery = applyFilters(
        _client.from(AppConstants.clientsTable).select('id'),
      );

      if (sort == 'name_desc') {
        dataQuery = (dataQuery as PostgrestFilterBuilder).order('full_name', ascending: false);
      } else if (sort == 'recent') {
        dataQuery = (dataQuery as PostgrestFilterBuilder).order('created_at', ascending: false);
      } else {
        dataQuery = (dataQuery as PostgrestFilterBuilder).order('full_name', ascending: true);
      }

      final count = await countQuery.count(CountOption.exact);
      final data = await dataQuery.range(offset, offset + limit - 1);
      final items = data.map(ClientProfile.fromJson).toList();

      return PagedResult<ClientProfile>(
        items: items,
        hasMore: (offset + items.length) < (count.count as num),
        nextOffset: (offset + items.length).toInt(),
        totalCount: count.count.toInt(),
      );
    } catch (e, stack) {
      debugPrint('❌ [getClientsForGymPaged] ERROR for gym=$gymId offset=$offset: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Get clients assigned to a specific trainer.
  Future<List<ClientProfile>> getClientsForTrainer(
    String gymId,
    String trainerId,
  ) async {
    final data = await _client
        .from(AppConstants.clientsTable)
        .select(_clientColumns)
        .eq('gym_id', gymId)
        .eq('assigned_trainer_id', trainerId)
        .order('created_at', ascending: false);

    return data.map((json) => ClientProfile.fromJson(json)).toList();
  }

  /// Update client profile.
  Future<ClientProfile> updateClient(ClientProfile client) async {
    final data = await _client
        .from(AppConstants.clientsTable)
        .update(client.toJson())
        .eq('id', client.id)
        .select(_clientColumns)
        .single();

    return ClientProfile.fromJson(data);
  }

  /// Delete a client.
  Future<void> deleteClient(String clientId) async {
    await _client.from(AppConstants.clientsTable).delete().eq('id', clientId);
  }

  // ─── MEMBERSHIPS ──────────────────────────────────────────────────

  /// Create a membership for a client.
  Future<Membership> createMembership(Membership membership) async {
    final data = await _client
        .from(AppConstants.membershipsTable)
        .insert(membership.toJson()..remove('id'))
        .select()
        .single();

    return Membership.fromJson(data);
  }

  /// Get active membership for a client.
  Future<Membership?> getActiveMembership(String clientId) async {
    final data = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('client_id', clientId)
        .eq('status', DatabaseValues.activeStatus)
        .order('end_date', ascending: false)
        .limit(1)
        .maybeSingle();

    return data != null ? Membership.fromJson(data) : null;
  }

  /// Get all memberships for a gym.
  Future<List<Membership>> getMembershipsForGym(String gymId) async {
    final data = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .order('end_date', ascending: true);

    return data.map((json) => Membership.fromJson(json)).toList();
  }

  /// Get paginated memberships for a gym with server-side filters.
  ///
  /// The `filter` argument is intentionally string-based because the UI exposes
  /// a lightweight filter bar (`all`, `active`, `expired`, `expiring`) rather
  /// than a full enum-backed domain model.
  Future<PagedResult<Membership>> getMembershipsForGymPaged(
    String gymId, {
    int limit = 20,
    int offset = 0,
    String filter = 'all',
  }) async {
    final now = DateTime.now().toIso8601String();
    final inSevenDays = DateTime.now()
        .add(const Duration(days: 7))
        .toIso8601String();

    dynamic applyFilters(
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    ) {
      var filtered = query.eq('gym_id', gymId);
      switch (filter) {
        case 'active':
          filtered = filtered
              .eq('status', MembershipStatus.active.value)
              .gte('end_date', now);
          break;
        case 'expired':
          filtered = filtered.or(
            'status.eq.${MembershipStatus.expired.value},end_date.lt.$now',
          );
          break;
        case 'expiring':
          filtered = filtered
              .eq('status', MembershipStatus.active.value)
              .gte('end_date', now)
              .lte('end_date', inSevenDays);
          break;
      }
      return filtered;
    }

    final dataQuery = applyFilters(
      _client.from(AppConstants.membershipsTable).select(),
    ).order('end_date', ascending: true);
    final countQuery = applyFilters(
      _client.from(AppConstants.membershipsTable).select(),
    );

    final count = await countQuery.count(CountOption.exact);
    final data = await dataQuery.range(offset, offset + limit - 1);
    final items = data.map(Membership.fromJson).toList();

    return PagedResult<Membership>(
      items: items,
      hasMore: (offset + items.length) < (count.count as num),
      nextOffset: (offset + items.length).toInt(),
      totalCount: count.count.toInt(),
    );
  }

  /// Fetch summary counts used by the memberships chip row without loading the
  /// full membership list into memory.
  Future<MembershipCounts> getMembershipCounts(String gymId) async {
    final now = DateTime.now().toIso8601String();
    final inSevenDays = DateTime.now()
        .add(const Duration(days: 7))
        .toIso8601String();

    final total = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .count(CountOption.exact);
    final active = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('status', MembershipStatus.active.value)
        .gte('end_date', now)
        .count(CountOption.exact);
    final expiring = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('status', MembershipStatus.active.value)
        .gte('end_date', now)
        .lte('end_date', inSevenDays)
        .count(CountOption.exact);

    return MembershipCounts(
      total: total.count,
      active: active.count,
      expiring: expiring.count,
    );
  }

  /// Get count of active clients in a gym.
  Future<int> getActiveClientCount(String gymId) async {
    final count = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('status', DatabaseValues.activeStatus)
        .count(CountOption.exact);

    return count.count;
  }

  /// Get memberships expiring within N days.
  Future<List<Membership>> getExpiringMemberships(
    String gymId, {
    int days = 7,
  }) async {
    final deadline = DateTime.now().add(Duration(days: days));

    final data = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('status', DatabaseValues.activeStatus)
        .lte('end_date', deadline.toIso8601String())
        .gte('end_date', DateTime.now().toIso8601String())
        .order('end_date', ascending: true);

    return data.map((json) => Membership.fromJson(json)).toList();
  }

  // ─── SUBSCRIPTIONS ────────────────────────────────────────────────

  /// Get gym's SaaS subscription.
  Future<Subscription?> getSubscription(String gymId) async {
    final data = await _client
        .from(AppConstants.subscriptionsTable)
        .select()
        .eq('gym_id', gymId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data != null ? Subscription.fromJson(data) : null;
  }

  // ─── DASHBOARD STATS ──────────────────────────────────────────────

  /// Get dashboard statistics for a gym.
  Future<Map<String, dynamic>> getDashboardStats(String gymId) async {
    final totalClients = await _client
        .from(AppConstants.clientsTable)
        .select('id')
        .eq('gym_id', gymId)
        .count(CountOption.exact);

    final activeMembers = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('status', DatabaseValues.activeStatus)
        .count(CountOption.exact);

    final expiredMembers = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('status', DatabaseValues.expiredStatus)
        .count(CountOption.exact);

    final expiringMemberships = await getExpiringMemberships(gymId, days: 7);

    return {
      'total_clients': totalClients.count,
      'active_members': activeMembers.count,
      'expired_members': expiredMembers.count,
      'expiring_soon': expiringMemberships.length,
    };
  }

  // ─── GYM CHECK-INS / TRAFFIC ──────────────────────────────────────

  /// Check in a user to a gym. Returns the new check-in record id.
  Future<String> checkInToGym({
    required String gymId,
    required String userId,
  }) async {
    final data = await _client
        .from(AppConstants.gymCheckinsTable)
        .insert({'gym_id': gymId, 'user_id': userId})
        .select('id')
        .single();
    return data['id'] as String;
  }

  /// Check out by setting checked_out_at on an existing check-in.
  Future<void> checkOutFromGym(String checkInId) async {
    await _client
        .from(AppConstants.gymCheckinsTable)
        .update({'checked_out_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', checkInId);
  }

  /// Returns the user's current active check-in for a gym, or null.
  Future<Map<String, dynamic>?> getActiveCheckIn({
    required String gymId,
    required String userId,
  }) async {
    return await _client
        .from(AppConstants.gymCheckinsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('user_id', userId)
        .isFilter('checked_out_at', null)
        .maybeSingle();
  }

  /// Stream of all check-ins for a gym (filtered to active in the provider).
  Stream<List<Map<String, dynamic>>> streamGymCheckIns(String gymId) {
    return _client
        .from(AppConstants.gymCheckinsTable)
        .stream(primaryKey: ['id'])
        .eq('gym_id', gymId);
  }

  // ─── FOOD LOGS ────────────────────────────────────────────────────

  /// Insert a food log entry.
  Future<void> logFood(FoodLog log) async {
    await _client
        .from(AppConstants.foodLogsTable)
        .insert(log.toInsertJson());
  }

  /// Fetch food logs for a user within a date range.
  Future<List<FoodLog>> getFoodLogs({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final data = await _client
        .from(AppConstants.foodLogsTable)
        .select()
        .eq('user_id', userId)
        .gte('logged_at', startDate.toUtc().toIso8601String())
        .lte('logged_at', endDate.toUtc().toIso8601String())
        .order('logged_at', ascending: false);
    return data.map(FoodLog.fromJson).toList();
  }

  /// Fetch a paged slice of food logs for a date window.
  ///
  /// This is paired with summary providers that still load the full bounded
  /// date range so totals stay correct while visible log rows page explicitly.
  Future<PagedResult<FoodLog>> getFoodLogsPaged({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
    int offset = 0,
  }) async {
    final count = await _client
        .from(AppConstants.foodLogsTable)
        .select()
        .eq('user_id', userId)
        .gte('logged_at', startDate.toUtc().toIso8601String())
        .lte('logged_at', endDate.toUtc().toIso8601String())
        .count(CountOption.exact);

    final data = await _client
        .from(AppConstants.foodLogsTable)
        .select()
        .eq('user_id', userId)
        .gte('logged_at', startDate.toUtc().toIso8601String())
        .lte('logged_at', endDate.toUtc().toIso8601String())
        .order('logged_at', ascending: false)
        .range(offset, offset + limit - 1);

    final items = data.map(FoodLog.fromJson).toList();
    return PagedResult<FoodLog>(
      items: items,
      hasMore: offset + items.length < count.count,
      nextOffset: offset + items.length,
      totalCount: count.count,
    );
  }

  /// Delete a food log entry (only the owner can delete their own).
  Future<void> deleteFoodLog(String id) async {
    await _client.from(AppConstants.foodLogsTable).delete().eq('id', id);
  }

  // ─── GYM CHECK-INS (continued) ────────────────────────────────────

  /// Fetch check-ins from the last [days] days for hourly traffic analysis.
  Future<List<Map<String, dynamic>>> getRecentCheckIns({
    required String gymId,
    int days = 28,
  }) async {
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toUtc()
        .toIso8601String();
    return await _client
        .from(AppConstants.gymCheckinsTable)
        .select('checked_in_at, checked_out_at')
        .eq('gym_id', gymId)
        .gte('checked_in_at', since)
        .order('checked_in_at', ascending: false);
  }

  // ─── MEMBER (CLIENT-FACING) ─────────────────────────────────────────────

  /// Active membership for a user (by their profile userId, not clientId).
  Future<Membership?> getActiveMembershipForUser(String userId) async {
    final data = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('user_id', userId)
        .eq('status', DatabaseValues.activeStatus)
        .order('created_at', ascending: false)
        .limit(1);
    if (data.isEmpty) return null;
    return Membership.fromJson(data.first);
  }

  /// Workout plan assigned to a client.
  Future<Map<String, dynamic>?> getWorkoutPlanForClient(
      String clientId) async {
    final data = await _client
        .from(AppConstants.workoutPlansTable)
        .select()
        .eq('client_id', clientId)
        .eq('status', DatabaseValues.activeStatus)
        .order('created_at', ascending: false)
        .limit(1);
    if (data.isEmpty) return null;
    return data.first;
  }

  /// All active workout plans for a gym (most recent first).
  Future<List<WorkoutPlan>> getWorkoutPlansForGym(String gymId,
      {int limit = 10}) async {
    final data = await _client
        .from(AppConstants.workoutPlansTable)
        .select()
        .eq('gym_id', gymId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => WorkoutPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new workout plan and return the persisted record.
  Future<WorkoutPlan> createWorkoutPlan(Map<String, dynamic> data) async {
    final result = await _client
        .from(AppConstants.workoutPlansTable)
        .insert(data)
        .select()
        .single();
    return WorkoutPlan.fromJson(result);
  }

  /// Diet plan assigned to a client.
  Future<Map<String, dynamic>?> getDietPlanForClient(String clientId) async {
    final data = await _client
        .from(AppConstants.dietPlansTable)
        .select()
        .eq('client_id', clientId)
        .eq('status', DatabaseValues.activeStatus)
        .order('created_at', ascending: false)
        .limit(1);
    if (data.isEmpty) return null;
    return data.first;
  }

  /// Weight progress check-ins for a client (last 30 entries).
  Future<List<Map<String, dynamic>>> getProgressCheckIns(
      String clientId) async {
    return await _client
        .from(AppConstants.progressCheckInsTable)
        .select(
          'id, gym_id, client_id, trainer_id, checkin_date, '
          'weight_kg, body_fat_percent, chest_cm, waist_cm, hips_cm, '
          'arm_cm, thigh_cm, sleep_quality, energy_level, soreness_level, '
          'adherence_percent, mood, notes, '
          'front_photo_url, side_photo_url, back_photo_url, created_at',
        )
        .eq('client_id', clientId)
        .order('checkin_date', ascending: false)
        .limit(30);
  }

  /// Number of gym check-ins by a user in the current calendar month.
  Future<int> getAttendanceThisMonth({
    required String gymId,
    required String userId,
  }) async {
    final now = DateTime.now();
    final monthStart =
        DateTime(now.year, now.month, 1).toUtc().toIso8601String();
    final result = await _client
        .from(AppConstants.gymCheckinsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('user_id', userId)
        .gte('checked_in_at', monthStart)
        .count();
    return result.count;
  }

  /// Log a new weight entry for a client.
  Future<void> logWeight({
    required String gymId,
    required String clientId,
    required double weightKg,
    String? notes,
  }) async {
    await _client.from(AppConstants.progressCheckInsTable).insert({
      'gym_id': gymId,
      'client_id': clientId,
      'checkin_date': DateTime.now().toIso8601String().split('T').first,
      'weight_kg': weightKg,
      'notes': notes,
    });
  }

  /// Check a user into the gym (member self-check-in).
  Future<void> memberCheckIn({
    required String gymId,
    required String userId,
  }) async {
    await _client.from(AppConstants.gymCheckinsTable).insert({
      'gym_id': gymId,
      'user_id': userId,
      'checked_in_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Fetch gym announcements (latest first, pinned first).
  Future<List<Map<String, dynamic>>> getAnnouncements(String gymId) async {
    return await _client
        .from(AppConstants.announcementsTable)
        .select()
        .eq('gym_id', gymId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .limit(20);
  }

  /// Fetch a paged announcements feed ordered by pinned-first, newest-first.
  Future<PagedResult<Announcement>> getAnnouncementsPaged(
    String gymId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final count = await _client
        .from(AppConstants.announcementsTable)
        .select()
        .eq('gym_id', gymId)
        .count(CountOption.exact);
    final data = await _client
        .from(AppConstants.announcementsTable)
        .select()
        .eq('gym_id', gymId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final items = data.map(Announcement.fromJson).toList();
    return PagedResult<Announcement>(
      items: items,
      hasMore: offset + items.length < count.count,
      nextOffset: offset + items.length,
      totalCount: count.count,
    );
  }

  /// Stream gym announcements in real-time.
  Stream<List<Map<String, dynamic>>> streamAnnouncements(String gymId) {
    return _client
        .from(AppConstants.announcementsTable)
        .stream(primaryKey: ['id'])
        .eq('gym_id', gymId)
        .order('created_at', ascending: false)
        .limit(20);
  }
  /// Insert a progress check-in record (used by Pro member measurements screen).
  Future<void> addProgressCheckIn(Map<String, dynamic> data) async {
    await _client.from(AppConstants.progressCheckInsTable).insert(data);
  }

  // ─── ELITE: Supplements ────────────────────────────────────────────────────

  /// Fetch supplement logs for a user (today + recent).
  Future<List<Map<String, dynamic>>> getSupplementLogs(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _client
        .from('supplement_logs')
        .select()
        .eq('user_id', userId)
        .gte('logged_at', startOfDay.toIso8601String())
        .order('logged_at', ascending: false);
  }

  /// Add a supplement log entry.
  Future<void> addSupplementLog(Map<String, dynamic> data) async {
    await _client.from('supplement_logs').insert(data);
  }

  // ─── ELITE: Trainer Chat ───────────────────────────────────────────────────

  /// Real-time stream of trainer-member chat messages.
  Stream<List<Map<String, dynamic>>> streamTrainerMessages(String memberId) {
    return _client
        .from('trainer_messages')
        .stream(primaryKey: ['id'])
        .eq('member_id', memberId)
        .order('created_at', ascending: true)
        .limit(100);
  }

  /// Send a message in the trainer chat.
  Future<void> sendTrainerMessage({
    required String memberId,
    required String senderId,
    required String senderRole,
    required String message,
    String? gymId,
  }) async {
    await _client.from('trainer_messages').insert({
      'member_id': memberId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'message': message,
      'gym_id': gymId,
    });
  }

  // ─── DASHBOARD / QUICK STATS ──────────────────────────────────────────────

  /// Get current occupant count for a gym using the occupancy view.
  Future<int> getCurrentOccupancyCount(String gymId) async {
    final result = await _client
        .from(AppConstants.occupancyView)
        .select('current_count')
        .eq('gym_id', gymId)
        .maybeSingle();
    return result?['current_count'] ?? 0;
  }

  /// Get equipment status summary for a gym.
  /// Returns counts grouped by status.
  Future<Map<String, int>> getEquipmentStatusSummary(String gymId) async {
    final result = await _client
        .from(AppConstants.equipmentStatusTable)
        .select('total_units, in_use, out_of_service')
        .eq('gym_id', gymId);

    int totalUnits = 0;
    int totalInUse = 0;
    int totalOutOfOrder = 0;

    for (final row in result) {
      totalUnits += (row['total_units'] as int?) ?? 0;
      totalInUse += (row['in_use'] as int?) ?? 0;
      totalOutOfOrder += (row['out_of_service'] as int?) ?? 0;
    }

    final totalAvailable = (totalUnits - totalInUse - totalOutOfOrder).clamp(0, totalUnits);

    return {
      'available': totalAvailable,
      'in_use': totalInUse,
      'out_of_order': totalOutOfOrder,
    };
  }

  // ─── Workout History ──────────────────────────────────────────────────────

  /// Returns the most recent [limit] completed workout sessions for a user.
  Future<List<Map<String, dynamic>>> getWorkoutHistory({
    required String userId,
    int limit = 30,
  }) async {
    try {
      final data = await _client
          .from('workout_sessions')
          .select(
              'id, workout_name, started_at, completed_at, total_sets, total_reps, notes')
          .eq('user_id', userId)
          .order('started_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }
}
