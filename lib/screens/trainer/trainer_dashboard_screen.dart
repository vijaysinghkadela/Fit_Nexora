import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../models/client_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/fit_management_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';
import '../clients/add_client_screen.dart';

const trainerDestinations = [
  FitShellDestination(
    icon: Icons.dashboard_rounded,
    iconPath: 'assets/images/logo.png',
    label: 'Home',
    route: '/trainer',
  ),
  FitShellDestination(
    icon: Icons.people_alt_rounded,
    label: 'Clients',
    route: '/trainer/clients',
  ),
  FitShellDestination(
    icon: Icons.fitness_center_rounded,
    label: 'Plans',
    route: '/workouts',
  ),
  FitShellDestination(
    icon: Icons.person_rounded,
    label: 'Profile',
    route: '/trainer/settings',
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
      destinations: trainerDestinations,
      mobileDestinations: trainerDestinations,
      userName: userName,
      userEmail: userEmail,
      onSignOut: () {
        ref.read(currentUserProvider.notifier).signOut().then((_) {
          if (context.mounted) {
            context.go('/login');
          }
        }).catchError((_) {
          if (context.mounted) context.go('/login');
        });
      },
      centerAction: FitShellCenterAction(
        icon: Icons.add_rounded,
        label: 'Add Client',
        onTap: () => _openAddClientSheet(context),
      ),
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
    final todayActiveAsync = ref.watch(trainerTodayActiveClientsProvider);
    final todayActive = todayActiveAsync.value ?? 0;

    Future<void> refreshAll() async {
      ref.invalidate(trainerClientsProvider);
      ref.invalidate(trainerTodayActiveClientsProvider);
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
          todayActive: todayActive,
          onAddClient: onAddClient,
        ),
        data: (clients) => _TrainerContent(
          userName: userName,
          gymName: gym?.name ?? 'Trainer Pro',
          clients: clients,
          todayActive: todayActive,
          onAddClient: onAddClient,
        ),
      ),
    );
  }
}

class _WeekBar {
  final String label;
  final int count;
  final double normalizedValue;
  final bool isProjection;
  const _WeekBar({
    required this.label,
    required this.count,
    required this.normalizedValue,
    this.isProjection = false,
  });
}

class _TrainerContent extends StatelessWidget {
  const _TrainerContent({
    required this.userName,
    required this.gymName,
    required this.clients,
    required this.todayActive,
    required this.onAddClient,
  });

  final String userName;
  final String gymName;
  final List<ClientProfile> clients;
  final int todayActive;
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
    final weekBars = _weeklyGrowthData(clients);
    final lastWeekCount =
        weekBars.length >= 2 ? weekBars[weekBars.length - 2].count : 0;
    final prevWeekCount =
        weekBars.length >= 3 ? weekBars[weekBars.length - 3].count : 0;
    final growthPct = prevWeekCount == 0
        ? 0
        : ((lastWeekCount - prevWeekCount) / prevWeekCount * 100).round();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: true,
          backgroundColor: colors.background.withOpacity(0.92),
          toolbarHeight: 84,
          titleSpacing: 20,
          title: _TrainerBrandHeader(gymName: gymName),
          actions: [
            _RoundActionIcon(
              icon: Icons.notifications_rounded,
              dotColor: colors.accent,
              onTap: () => context.push('/notifications'),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () => context.go('/trainer/settings'),
                child: _TrainerAvatar(name: userName),
              ),
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
                    color: colors.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.brand.withOpacity(0.22)),
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
              todayActiveClients: todayActive,
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
                            _GrowthTrendCard(weekBars: weekBars, growthPct: growthPct),
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
                    _GrowthTrendCard(weekBars: weekBars, growthPct: growthPct),
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

  List<_WeekBar> _weeklyGrowthData(List<ClientProfile> clients) {
    final now = DateTime.now();
    final weeks = <_WeekBar>[];

    for (int i = 6; i >= 0; i--) {
      final weekEnd = now.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 7));
      final count = clients
          .where(
            (c) =>
                c.createdAt.isAfter(weekStart) &&
                c.createdAt.isBefore(weekEnd),
          )
          .length;
      weeks.add(_WeekBar(label: 'W${7 - i}', count: count, normalizedValue: 0));
    }

    // Projection: 3-week moving average of last 3 weeks.
    final recent = weeks.sublist(4).map((w) => w.count).toList();
    final avgGrowth = recent.isEmpty
        ? 0
        : (recent.reduce((a, b) => a + b) / recent.length).round();
    weeks.add(
      _WeekBar(
        label: 'Proj',
        count: avgGrowth,
        normalizedValue: 0,
        isProjection: true,
      ),
    );

    final maxCount =
        weeks.map((w) => w.count).fold<int>(0, (a, b) => b > a ? b : a);
    if (maxCount == 0) {
      return List.generate(
        8,
        (i) => _WeekBar(
          label: i < 7 ? 'W${i + 1}' : 'Proj',
          count: 0,
          normalizedValue: 0.1 + (i / 7) * 0.5,
          isProjection: i == 7,
        ),
      );
    }

    return weeks
        .map(
          (w) => _WeekBar(
            label: w.label,
            count: w.count,
            normalizedValue:
                (0.08 + (w.count / maxCount) * 0.92).clamp(0.08, 1.0),
            isProjection: w.isProjection,
          ),
        )
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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
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
    required this.todayActiveClients,
    required this.averageAdherence,
    required this.pendingTasks,
  });

  final int activeClients;
  final int todayActiveClients;
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
                label: 'In Gym Today',
                value: '$todayActiveClients',
                footnote: '$activeClients total clients',
                accentIcon: Icons.location_on_rounded,
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
          label: AppLocalizations.of(context)!.addClient,
          filled: true,
          onTap: onAddClient,
        ),
        _ActionButton(
          icon: Icons.assignment_ind_rounded,
          label: 'Assign Plan',
          onTap: () => context.go('/trainer/assign-workout'),
        ),
        _ActionButton(
          icon: Icons.edit_note_rounded,
          label: AppLocalizations.of(context)!.createPlan,
          onTap: () => context.go('/workouts'),
        ),
        _ActionButton(
          icon: Icons.restaurant_menu_rounded,
          label: 'Diet Plans',
          onTap: () => context.go('/diet-plans'),
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
                  AppLocalizations.of(context)!.schedule,
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
  const _GrowthTrendCard({required this.weekBars, required this.growthPct});

  final List<_WeekBar> weekBars;
  final int growthPct;

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
                  'Weekly Growth Trend',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (growthPct != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (growthPct >= 0 ? colors.accent : colors.danger)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${growthPct >= 0 ? '+' : ''}$growthPct%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: growthPct >= 0 ? colors.accent : colors.danger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weekBars.asMap().entries.map((entry) {
                  final bar = entry.value;
                  final isHighlight = entry.key == weekBars.length - 2;
                  final barColor = bar.isProjection
                      ? colors.textMuted.withOpacity(0.4)
                      : isHighlight
                          ? colors.accent
                          : colors.brand.withOpacity(0.28);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 100 * bar.normalizedValue,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              border: bar.isProjection
                                  ? Border.all(
                                      color: colors.textMuted.withOpacity(0.5),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekBars
                  .asMap()
                  .entries
                  .where(
                    (e) => e.key % 2 == 0 || e.key == weekBars.length - 1,
                  )
                  .map(
                    (entry) => Text(
                      entry.value.label,
                      style: GoogleFonts.inter(
                        fontSize: 9,
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
