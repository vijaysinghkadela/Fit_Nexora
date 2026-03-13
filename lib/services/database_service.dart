import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/gym_model.dart';
import '../models/client_profile_model.dart';
import '../models/membership_model.dart';
import '../models/subscription_model.dart';

/// Database service wrapping Supabase queries.
class DatabaseService {
  final SupabaseClient _client;

  DatabaseService(this._client);

  // ─── GYMS ─────────────────────────────────────────────────────────

  /// Create a new gym.
  Future<Gym> createGym({
    required String name,
    required String ownerId,
    String? address,
    String? phone,
  }) async {
    final data = await _client
        .from(AppConstants.gymsTable)
        .insert({
          'name': name,
          'owner_id': ownerId,
          'address': address,
          'phone': phone,
        })
        .select()
        .single();

    // Also add the owner as a gym member with 'owner' role
    await _client.from(AppConstants.gymMembersTable).insert({
      'gym_id': data['id'],
      'user_id': ownerId,
      'role': 'owner',
    });

    return Gym.fromJson(data);
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
        .select()
        .single();

    return ClientProfile.fromJson(data);
  }

  /// Get all clients for a gym.
  Future<List<ClientProfile>> getClientsForGym(String gymId) async {
    final data = await _client
        .from(AppConstants.clientsTable)
        .select()
        .eq('gym_id', gymId)
        .order('created_at', ascending: false);

    return data.map((json) => ClientProfile.fromJson(json)).toList();
  }

  /// Get clients assigned to a specific trainer.
  Future<List<ClientProfile>> getClientsForTrainer(
    String gymId,
    String trainerId,
  ) async {
    final data = await _client
        .from(AppConstants.clientsTable)
        .select()
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
        .select()
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
        .eq('status', 'active')
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

  /// Get count of active clients in a gym.
  Future<int> getActiveClientCount(String gymId) async {
    final count = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('status', 'active')
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
        .eq('status', 'active')
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
        .select()
        .eq('gym_id', gymId)
        .count(CountOption.exact);

    final activeMembers = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('status', 'active')
        .count(CountOption.exact);

    final expiredMembers = await _client
        .from(AppConstants.membershipsTable)
        .select()
        .eq('gym_id', gymId)
        .eq('status', 'expired')
        .count(CountOption.exact);

    final expiringMemberships = await getExpiringMemberships(gymId, days: 7);

    return {
      'total_clients': totalClients.count,
      'active_members': activeMembers.count,
      'expired_members': expiredMembers.count,
      'expiring_soon': expiringMemberships.length,
    };
  }
}
