import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/fit_management_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';
import '../clients/add_client_screen.dart';

const _trainerDestinations = [
  FitShellDestination(
    icon: Icons.dashboard_rounded,
    label: 'Trainer',
    route: '/trainer',
  ),
  FitShellDestination(
    icon: Icons.people_alt_rounded,
    label: 'Clients',
    route: '/clients',
  ),
  FitShellDestination(
    icon: Icons.fitness_center_rounded,
    label: 'Workouts',
    route: '/workouts',
  ),
  FitShellDestination(
    icon: Icons.person_rounded,
    label: 'Profile',
    route: '/settings',
  ),
];

/// Trainer-facing dashboard aligned to the stitched mobile-first dashboard.
class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final userName = (currentUser?.fullName ?? '').trim().isEmpty
        ? 'Coach Alex'
        : currentUser!.fullName;
    final userEmail = currentUser?.email ?? '';

    return FitManagementScaffold(
      currentRoute: '/trainer',
      destinations: _trainerDestinations,
      mobileDestinations: _trainerDestinations,
      userName: userName,
      userEmail: userEmail,
      onSignOut: () {
        ref.read(currentUserProvider.notifier).signOut().then((_) {
          if (context.mounted) {
            context.go('/login');
          }
        });
      },
      child: _TrainerDashboardBody(
        userName: userName,
        onAddClient: () => _openAddClientSheet(context),
      ),
    );
  }

  void _openAddClientSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddClientScreen(),
    );
  }
}

class _TrainerDashboardBody extends ConsumerWidget {
  const _TrainerDashboardBody({
    required this.userName,
    required this.onAddClient,
  });

  final String userName;
  final VoidCallback onAddClient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.fitTheme;
    final gym = ref.watch(selectedGymProvider);
    final clientsAsync = ref.watch(trainerClientsProvider);

    Future<void> refreshAll() async {
      ref.invalidate(trainerClientsProvider);
      await ref.read(trainerClientsProvider.future);
    }

    return RefreshIndicator(
      onRefresh: refreshAll,
      color: colors.brand,
      backgroundColor: colors.surface,
      child: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _TrainerContent(
          userName: userName,
          gymName: gym?.name ?? 'Trainer Pro',
          clients: const [],
          onAddClient: onAddClient,
        ),
        data: (clients) => _TrainerContent(
          userName: userName,
          gymName: gym?.name ?? 'Trainer Pro',
          clients: clients,
          onAddClient: onAddClient,
        ),
      ),
    );
  }
}

class _TrainerContent extends StatelessWidget {
  const _TrainerContent({
    required this.userName,
    required this.gymName,
    required this.clients,
    required this.onAddClient,
  });

  final String userName;
  final String gymName;
  final List<ClientProfile> clients;
  final VoidCallback onAddClient;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final firstName = userName.split(' ').first;
    final avgAdherence = clients.isEmpty
        ? 92
        : (clients
                    .map((client) => client.adherencePercent ?? 84)
                    .reduce((a, b) => a + b) /
                clients.length)
            .round();
    final pendingTasks = clients
        .where((client) => (client.adherencePercent ?? 100) < 75)
        .length;
    final schedule = _scheduleForClients(clients);
    final trendValues = _clientTrendValues(clients);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: true,
          backgroundColor: colors.background.withValues(alpha: 0.92),
          toolbarHeight: 84,
          titleSpacing: 20,
          title: _TrainerBrandHeader(gymName: gymName),
          actions: [
            _RoundActionIcon(
              icon: Icons.notifications_rounded,
              dotColor: colors.accent,
              onTap: () => context.go('/settings'),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: _TrainerAvatar(name: userName),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Coach',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  firstName,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your gym ecosystem',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.brand.withValues(alpha: 0.22)),
                  ),
                  child: Text(
                    clients.length >= 10 ? 'Elite Tier Trainer' : 'Trainer Pro',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _TrainerMetricGrid(
              activeClients: clients.length,
              averageAdherence: avgAdherence,
              pendingTasks: pendingTasks,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _QuickActionRow(
              onAddClient: onAddClient,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1024) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _ScheduleCard(schedule: schedule),
                            const SizedBox(height: 20),
                            _GrowthTrendCard(values: trendValues),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: _ClientManagementCard(clients: clients),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _ScheduleCard(schedule: schedule),
                    const SizedBox(height: 20),
                    _GrowthTrendCard(values: trendValues),
                    const SizedBox(height: 20),
                    _ClientManagementCard(clients: clients),
                  ],
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  List<_ScheduleEntry> _scheduleForClients(List<ClientProfile> clients) {
    final seededClients = clients.take(3).toList();
    final labels = [
      ('09:00', 'HIIT Intensity Session'),
      ('11:30', 'Plan Review (Nutrition)'),
      ('14:00', 'Strength Assessment'),
    ];

    if (seededClients.isEmpty) {
      return [
        const _ScheduleEntry(
          time: '09:00',
          clientName: 'Sarah Jenkins',
          focus: 'HIIT Intensity Session',
          tone: _ScheduleTone.brand,
        ),
        const _ScheduleEntry(
          time: '11:30',
          clientName: 'Marc Russo',
          focus: 'Plan Review (Nutrition)',
          tone: _ScheduleTone.success,
        ),
        const _ScheduleEntry(
          time: '14:00',
          clientName: 'Emily Chen',
          focus: 'Strength Assessment',
          tone: _ScheduleTone.muted,
        ),
      ];
    }

    return seededClients.asMap().entries.map((entry) {
      final index = entry.key;
      final client = entry.value;
      final tone = switch (index) {
        0 => _ScheduleTone.brand,
        1 => _ScheduleTone.success,
        _ => _ScheduleTone.muted,
      };
      return _ScheduleEntry(
        time: labels[index].$1,
        clientName: client.fullName ?? 'Client',
        focus: client.currentPlanName ?? labels[index].$2,
        tone: tone,
      );
    }).toList();
  }

  List<double> _clientTrendValues(List<ClientProfile> clients) {
    final weekdays = List<double>.filled(7, 0.0);

    for (final client in clients) {
      final day = client.createdAt.weekday - 1;
      weekdays[day] += 1;
    }

    final maxValue = weekdays.fold<double>(0, math.max);
    if (maxValue == 0) {
      return const [0.4, 0.58, 0.52, 0.74, 0.7, 0.95, 0.45];
    }

    return weekdays
        .map((value) => (0.32 + (value / maxValue) * 0.63).clamp(0.28, 0.96))
        .toList();
  }
}

class _TrainerBrandHeader extends StatelessWidget {
  const _TrainerBrandHeader({required this.gymName});

  final String gymName;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.brand, colors.accent],
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.fitness_center_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FitNexora',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            Text(
              gymName,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundActionIcon extends StatelessWidget {
  const _RoundActionIcon({
    required this.icon,
    required this.onTap,
    this.dotColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.glassFill,
            shape: BoxShape.circle,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(icon, color: colors.textSecondary, size: 20),
              ),
              if (dotColor != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerAvatar extends StatelessWidget {
  const _TrainerAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return CircleAvatar(
      radius: 21,
      backgroundColor: colors.surfaceAlt,
      child: Text(
        name.isEmpty ? 'T' : name[0].toUpperCase(),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _TrainerMetricGrid extends StatelessWidget {
  const _TrainerMetricGrid({
    required this.activeClients,
    required this.averageAdherence,
    required this.pendingTasks,
  });

  final int activeClients;
  final int averageAdherence;
  final int pendingTasks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 820
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _TrainerMetricCard(
                label: 'Active Clients',
                value: '$activeClients',
                footnote: '+${math.max(1, activeClients ~/ 8)} this week',
                accentIcon: Icons.group_rounded,
                accentColor: context.fitTheme.accent,
              ),
            ),
            SizedBox(
              width: width,
              child: _TrainerMetricCard(
                label: 'Avg Adherence',
                value: '$averageAdherence%',
                footnote: 'Consistency across assigned plans',
                accentIcon: Icons.verified_rounded,
                accentColor: context.fitTheme.brand,
                progress: averageAdherence / 100,
              ),
            ),
            SizedBox(
              width: width,
              child: _TrainerMetricCard(
                label: 'Pending Tasks',
                value: '$pendingTasks',
                footnote: pendingTasks == 0
                    ? 'Everything cleared'
                    : '${math.max(1, pendingTasks ~/ 2)} plan reviews due',
                accentIcon: Icons.assignment_late_rounded,
                accentColor: context.fitTheme.warning,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrainerMetricCard extends StatelessWidget {
  const _TrainerMetricCard({
    required this.label,
    required this.value,
    required this.footnote,
    required this.accentIcon,
    required this.accentColor,
    this.progress,
  });

  final String label;
  final String value;
  final String footnote;
  final IconData accentIcon;
  final Color accentColor;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                Icon(accentIcon, color: accentColor, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 31,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              footnote,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: colors.ringTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.onAddClient});

  final VoidCallback onAddClient;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ActionButton(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Add Client',
          filled: true,
          onTap: onAddClient,
        ),
        _ActionButton(
          icon: Icons.edit_note_rounded,
          label: 'Create Plan',
          onTap: () => context.go('/workouts'),
        ),
        _ActionButton(
          icon: Icons.campaign_rounded,
          label: 'Announce',
          onTap: () => context.go('/todos'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: filled ? colors.brandGradient : null,
            color: filled ? null : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled ? Colors.transparent : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.white : colors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ScheduleTone { brand, success, muted }

class _ScheduleEntry {
  const _ScheduleEntry({
    required this.time,
    required this.clientName,
    required this.focus,
    required this.tone,
  });

  final String time;
  final String clientName;
  final String focus;
  final _ScheduleTone tone;
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final List<_ScheduleEntry> schedule;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Today\'s Schedule',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/clients'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < schedule.length; i++) ...[
              _ScheduleRow(entry: schedule[i]),
              if (i != schedule.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.entry});

  final _ScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final accent = switch (entry.tone) {
      _ScheduleTone.brand => colors.brand,
      _ScheduleTone.success => colors.accent,
      _ScheduleTone.muted => colors.textMuted,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            entry.time,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textMuted,
            ),
          ),
        ),
        Container(
          width: 3,
          height: 42,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.clientName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                entry.focus,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GrowthTrendCard extends StatelessWidget {
  const _GrowthTrendCard({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client Growth Trend',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: values.asMap().entries.map((entry) {
                  final isHighlight = entry.key == 5;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 100 * entry.value,
                          decoration: BoxDecoration(
                            color: isHighlight
                                ? colors.accent
                                : colors.brand.withValues(alpha: 0.28),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['MON', 'WED', 'SAT', 'SUN']
                  .map(
                    (label) => Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.textMuted,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientManagementCard extends StatelessWidget {
  const _ClientManagementCard({required this.clients});

  final List<ClientProfile> clients;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final visibleClients = clients.isEmpty
        ? _fallbackClients
        : clients.take(4).toList();

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Management',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage active trainees and check-ins',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _SearchPill(onTap: () => context.go('/clients')),
              ],
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < visibleClients.length; i++) ...[
              _ClientRow(client: visibleClients[i]),
              if (i != visibleClients.length - 1)
                Divider(color: colors.divider, height: 22),
            ],
          ],
        ),
      ),
    );
  }

  static final List<ClientProfile> _fallbackClients = [
    ClientProfile(
      id: '1',
      gymId: 'fallback',
      fullName: 'Sarah Jenkins',
      adherencePercent: 92,
      currentPlanName: 'Recent Progress +2.4kg Lean Mass',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ClientProfile(
      id: '2',
      gymId: 'fallback',
      fullName: 'Marc Russo',
      adherencePercent: 76,
      currentPlanName: 'Last Seen 2 days ago',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ClientProfile(
      id: '3',
      gymId: 'fallback',
      fullName: 'Emily Chen',
      adherencePercent: 88,
      currentPlanName: 'Recent Progress +3% Body Fat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ClientProfile(
      id: '4',
      gymId: 'fallback',
      fullName: 'Jason Miller',
      adherencePercent: 64,
      currentPlanName: 'Status Resuming Oct 15',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.search_rounded,
          color: colors.textSecondary,
          size: 18,
        ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client});

  final ClientProfile client;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final name = (client.fullName ?? 'Client').trim();
    final initials = name
        .split(' ')
        .where((segment) => segment.isNotEmpty)
        .take(2)
        .map((segment) => segment[0].toUpperCase())
        .join();
    final adherence = client.adherencePercent ?? 84;
    final statusColor = adherence >= 85
        ? colors.accent
        : adherence >= 70
            ? colors.warning
            : colors.danger;

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: colors.surfaceAlt,
          child: Text(
            initials.isEmpty ? 'C' : initials,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                client.currentPlanName ?? 'Current training plan active',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Adherence',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$adherence%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
