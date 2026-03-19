import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>> _rawRows = [];
  _TaskStatus _selectedTab = _TaskStatus.todo;

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  void _fetchTodos() {
    _future = Supabase.instance.client.from('todos').select().catchError((error) {
      debugPrint('Todos error: $error');
      return <Map<String, dynamic>>[];
    });
  }

  Future<void> _handleRefresh() async {
    setState(_fetchTodos);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundAlt,
              colors.background,
              colors.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -100,
              child: _GlowOrb(
                color: colors.brand.withOpacity(0.16),
                size: 260,
              ),
            ),
            Positioned(
              bottom: -140,
              right: -120,
              child: _GlowOrb(
                color: colors.accent.withOpacity(0.1),
                size: 320,
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: colors.brand,
                backgroundColor: colors.surface,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done &&
                        !snapshot.hasData) {
                      return _TodosLoadingView(selectedTab: _selectedTab);
                    }

                    if (snapshot.hasError) {
                      return _TodosErrorView(
                        message: snapshot.error.toString(),
                        onRetry: () => setState(_fetchTodos),
                      );
                    }

                    final tasks = _buildTasks(snapshot.data ?? const []);
                    final counts = {
                      for (final status in _TaskStatus.values)
                        status: tasks.where((task) => task.status == status).length,
                    };

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                            child: _TodosHeader(
                              onSearchTap: () {
                                context.showSnackBar(
                                  'Search and quick filters are coming next.',
                                );
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                            child: _StatusTabs(
                              selectedTab: _selectedTab,
                              counts: counts,
                              onSelected: (tab) {
                                setState(() => _selectedTab = tab);
                              },
                            ),
                          ),
                        ),
                        ..._buildSections(
                          context: context,
                          tasks: tasks,
                          bottomPadding: bottomInset,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              right: 22,
              bottom: 88 + bottomInset,
              child: FloatingActionButton(
                backgroundColor: colors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                onPressed: () => _showCreateTaskSheet(context),
                child: const Icon(Icons.add_rounded, size: 30),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _TodosBottomBar(
        currentRoute: '/todos',
        bottomInset: bottomInset,
      ),
    );
  }

  List<Widget> _buildSections({
    required BuildContext context,
    required List<_TaskViewModel> tasks,
    required double bottomPadding,
  }) {
    final filtered = tasks.where((task) => task.status == _selectedTab).toList();

    if (filtered.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 24, 18, 110 + bottomPadding),
            child: _EmptyTaskState(status: _selectedTab),
          ),
        ),
      ];
    }

    if (_selectedTab == _TaskStatus.todo) {
      final dueToday =
          filtered.where((task) => task.section == _TaskSection.today).toList();
      final upcoming = filtered
          .where((task) => task.section == _TaskSection.upcoming)
          .toList();

      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
            child: _TaskSectionHeader(
              title: 'Due Today',
              trailing: '${dueToday.length} Tasks',
              emphasizeTrailing: true,
            ),
          ),
        ),
        _TaskListSliver(tasks: dueToday),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
            child: _TaskSectionHeader(
              title: 'Upcoming',
              trailing: upcoming.isEmpty
                  ? 'Plan ahead'
                  : upcoming.first.dayLabel,
            ),
          ),
        ),
        _TaskListSliver(tasks: upcoming),
        SliverToBoxAdapter(
          child: SizedBox(height: 110 + bottomPadding),
        ),
      ];
    }

    final title = _selectedTab == _TaskStatus.inProgress
        ? 'Currently Moving'
        : 'Completed';
    final trailing = _selectedTab == _TaskStatus.inProgress
        ? 'Focus block'
        : 'Recent wins';

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
          child: _TaskSectionHeader(title: title, trailing: trailing),
        ),
      ),
      _TaskListSliver(tasks: filtered),
      SliverToBoxAdapter(
        child: SizedBox(height: 110 + bottomPadding),
      ),
    ];
  }

  List<_TaskViewModel> _buildTasks(List<Map<String, dynamic>> rows) {
    _rawRows = rows;
    if (rows.isEmpty) {
      return _fallbackTasks;
    }

    final tasks = <_TaskViewModel>[];
    for (var index = 0; index < rows.length; index++) {
      final todo = rows[index];
      final title = _readString(
        todo,
        ['title', 'name', 'task', 'label'],
      );
      if (title.isEmpty) continue;

      final dueDate = _readDateTime(
        todo,
        ['due_at', 'due_date', 'scheduled_for', 'date', 'created_at'],
      );
      final subtitle = _readString(
        todo,
        ['description', 'details', 'notes', 'summary'],
      );
      final status = _statusFrom(todo);
      final priority = _priorityFrom(todo, index);
      final section = _sectionFrom(dueDate, status);
      tasks.add(
        _TaskViewModel(
          id: (todo['id'] ?? '$index-$title').toString(),
          title: title,
          subtitle: subtitle.isEmpty ? _defaultSubtitle(index) : subtitle,
          status: status,
          priority: priority,
          dueLabel: _dueLabel(dueDate, index, section),
          dayLabel: _dayLabel(dueDate),
          section: section,
        ),
      );
    }

    return tasks.isEmpty ? _fallbackTasks : tasks;
  }

  String _readString(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  DateTime? _readDateTime(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed.toLocal();
      }
    }
    return null;
  }

  _TaskStatus _statusFrom(Map<String, dynamic> item) {
    final statusValue = _readString(
      item,
      ['status', 'stage', 'state'],
    ).toLowerCase();
    final isDone = item['is_done'] == true ||
        item['completed'] == true ||
        item['done'] == true;
    if (isDone || statusValue.contains('done') || statusValue.contains('complete')) {
      return _TaskStatus.done;
    }
    if (statusValue.contains('progress') ||
        statusValue.contains('active') ||
        statusValue.contains('doing')) {
      return _TaskStatus.inProgress;
    }
    return _TaskStatus.todo;
  }

  _TaskPriority _priorityFrom(Map<String, dynamic> item, int index) {
    final priorityValue = _readString(
      item,
      ['priority', 'urgency', 'level'],
    ).toLowerCase();
    if (priorityValue.contains('high')) return _TaskPriority.high;
    if (priorityValue.contains('medium')) return _TaskPriority.medium;
    if (priorityValue.contains('low')) return _TaskPriority.low;
    return _TaskPriority.values[index % _TaskPriority.values.length];
  }

  _TaskSection _sectionFrom(DateTime? dueDate, _TaskStatus status) {
    if (status != _TaskStatus.todo) return _TaskSection.today;
    if (dueDate == null) return _TaskSection.today;
    final now = DateTime.now();
    return DateUtils.isSameDay(dueDate, now) || dueDate.isBefore(now)
        ? _TaskSection.today
        : _TaskSection.upcoming;
  }

  String _dueLabel(DateTime? dueDate, int index, _TaskSection section) {
    if (dueDate != null) {
      if (section == _TaskSection.today) return dueDate.timeLabel;
      return '${dueDate.dayMonth} - ${dueDate.timeLabel}';
    }
    const defaultsToday = ['08:00 AM', '11:30 AM', '04:00 PM'];
    const defaultsUpcoming = ['Oct 24 - 09:00 AM', 'Oct 25 - 01:30 PM'];
    return section == _TaskSection.today
        ? defaultsToday[index % defaultsToday.length]
        : defaultsUpcoming[index % defaultsUpcoming.length];
  }

  String _dayLabel(DateTime? dueDate) {
    if (dueDate == null) return 'Tomorrow';
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    if (DateUtils.isSameDay(dueDate, tomorrow)) {
      return 'Tomorrow, ${dueDate.formatWith('MMM d')}';
    }
    if (DateUtils.isSameDay(dueDate, today)) {
      return 'Today';
    }
    return dueDate.formatWith('EEE, MMM d');
  }

  String _defaultSubtitle(int index) {
    const defaults = [
      'Check equipment and playlist before the first session.',
      'Review strength notes and update the latest client milestone.',
      'Prepare meal guidance and the next accountability check-in.',
      'Confirm inventory and floor-readiness for tomorrow.',
    ];
    return defaults[index % defaults.length];
  }
  void _showCreateTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskFormSheet(
        onSave: (data) async {
          await Supabase.instance.client.from('todos').insert(data);
          if (mounted) setState(_fetchTodos);
        },
      ),
    );
  }

  void _showTaskDetail(BuildContext context, Map<String, dynamic> raw, _TaskViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailSheet(
        raw: raw,
        vm: vm,
        onSave: (data) async {
          await Supabase.instance.client
              .from('todos')
              .update(data)
              .eq('id', vm.id);
          if (mounted) setState(_fetchTodos);
        },
        onDelete: () async {
          await Supabase.instance.client
              .from('todos')
              .delete()
              .eq('id', vm.id);
          if (mounted) setState(_fetchTodos);
        },
      ),
    );
  }
}

enum _TaskStatus { todo, inProgress, done }

enum _TaskSection { today, upcoming }

enum _TaskPriority { high, medium, low }

class _TaskViewModel {
  const _TaskViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.priority,
    required this.dueLabel,
    required this.dayLabel,
    required this.section,
  });

  final String id;
  final String title;
  final String subtitle;
  final _TaskStatus status;
  final _TaskPriority priority;
  final String dueLabel;
  final String dayLabel;
  final _TaskSection section;
}

class _TodosHeader extends StatelessWidget {
  const _TodosHeader({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: colors.brandGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.glow.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.fitness_center_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FitNexora',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
              Text(
                'TRAINER DASHBOARD',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.brand,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        GlassmorphicCard(
          borderRadius: 999,
          onTap: onSearchTap,
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Icon(Icons.search_rounded),
          ),
        ),
      ],
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.selectedTab,
    required this.counts,
    required this.onSelected,
  });

  final _TaskStatus selectedTab;
  final Map<_TaskStatus, int> counts;
  final ValueChanged<_TaskStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Row(
      children: _TaskStatus.values.map((status) {
        final isSelected = selectedTab == status;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? colors.brand : colors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _statusLabel(status),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? colors.brand : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${counts[status] ?? 0}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colors.brand.withOpacity(0.85)
                          : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _statusLabel(_TaskStatus status) {
    switch (status) {
      case _TaskStatus.todo:
        return 'To Do';
      case _TaskStatus.inProgress:
        return 'In Progress';
      case _TaskStatus.done:
        return 'Done';
    }
  }
}

class _TaskSectionHeader extends StatelessWidget {
  const _TaskSectionHeader({
    required this.title,
    required this.trailing,
    this.emphasizeTrailing = false,
  });

  final String title;
  final String trailing;
  final bool emphasizeTrailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.9,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: emphasizeTrailing
                ? colors.brand.withOpacity(0.18)
                : colors.surfaceAlt.withOpacity(0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            trailing,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: emphasizeTrailing ? colors.brand : colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskListSliver extends StatelessWidget {
  const _TaskListSliver({required this.tasks});

  final List<_TaskViewModel> tasks;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      sliver: SliverList.separated(
        itemCount: tasks.length,
        itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final _TaskViewModel task;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final priorityStyle = _priorityStyle(task.priority, colors);
    final isDone = task.status == _TaskStatus.done;

    return Opacity(
      opacity: isDone ? 0.7 : 1,
      child: GlassmorphicCard(
        onTap: () {
          final state = context.findAncestorStateOfType<_TodosScreenState>();
          if (state != null) {
            final rawRow = state._rawRows.firstWhere(
              (r) => (r['id'] ?? '').toString() == task.id,
              orElse: () => <String, dynamic>{},
            );
            state._showTaskDetail(context, rawRow, task);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDone ? colors.brand : colors.border,
                    width: isDone ? 1.6 : 1.2,
                  ),
                  color: isDone
                      ? colors.brand.withOpacity(0.16)
                      : Colors.transparent,
                ),
                child: isDone
                    ? Icon(Icons.check_rounded, size: 18, color: colors.brand)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: priorityStyle.background,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            priorityStyle.label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: priorityStyle.foreground,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.45,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          task.section == _TaskSection.today
                              ? Icons.schedule_rounded
                              : Icons.calendar_today_rounded,
                          size: 16,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.dueLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PriorityStyle _priorityStyle(
    _TaskPriority priority,
    FitNexoraThemeTokens colors,
  ) {
    switch (priority) {
      case _TaskPriority.high:
        return const _PriorityStyle(
          label: 'HIGH',
          foreground: Color(0xFFFF8B8B),
          background: Color(0x33D95C66),
        );
      case _TaskPriority.medium:
        return _PriorityStyle(
          label: 'MEDIUM',
          foreground: colors.warning,
          background: colors.warning.withOpacity(0.18),
        );
      case _TaskPriority.low:
        return _PriorityStyle(
          label: 'LOW',
          foreground: colors.accent,
          background: colors.accent.withOpacity(0.18),
        );
    }
  }
}

class _PriorityStyle {
  const _PriorityStyle({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

class _EmptyTaskState extends StatelessWidget {
  const _EmptyTaskState({required this.status});

  final _TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Center(
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: colors.brandGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  status == _TaskStatus.done
                      ? Icons.verified_rounded
                      : Icons.checklist_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                status == _TaskStatus.done
                    ? 'No completed items yet'
                    : 'Your board is clear',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                status == _TaskStatus.inProgress
                    ? 'Tasks that are currently moving will appear here.'
                    : 'Pull to refresh or add a new task to start planning the day.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodosLoadingView extends StatelessWidget {
  const _TodosLoadingView({required this.selectedTab});

  final _TaskStatus selectedTab;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 140),
      children: [
        _TodosHeader(onSearchTap: () {}),
        const SizedBox(height: 22),
        _StatusTabs(
          selectedTab: selectedTab,
          counts: const {
            _TaskStatus.todo: 0,
            _TaskStatus.inProgress: 0,
            _TaskStatus.done: 0,
          },
          onSelected: (_) {},
        ),
        const SizedBox(height: 26),
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: 138,
            decoration: BoxDecoration(
              color: colors.surfaceAlt.withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _TodosErrorView extends StatelessWidget {
  const _TodosErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.warning, size: 42),
                const SizedBox(height: 16),
                Text(
                  'Unable to load tasks',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TodosBottomBar extends StatelessWidget {
  const _TodosBottomBar({
    required this.currentRoute,
    required this.bottomInset,
  });

  final String currentRoute;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final items = const [
      _BottomNavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'HOME',
        route: '/trainer',
      ),
      _BottomNavItem(
        icon: Icons.check_box_outline_blank_rounded,
        activeIcon: Icons.check_box_rounded,
        label: 'TASKS',
        route: '/todos',
      ),
      _BottomNavItem(
        icon: Icons.group_outlined,
        activeIcon: Icons.group_rounded,
        label: 'CLIENTS',
        route: '/clients',
      ),
      _BottomNavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: 'STATS',
        route: '/traffic',
      ),
      _BottomNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'SETUP',
        route: '/settings',
      ),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.92),
        border: Border(top: BorderSide(color: colors.divider)),
        boxShadow: [
          BoxShadow(
            color: colors.background.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final isSelected = item.route == currentRoute;
          return InkWell(
            onTap: () {
              if (!isSelected) context.go(item.route);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected ? colors.brand : colors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? colors.brand : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ─── Task Form Sheet (Create new task) ──────────────────────────────────────

class _TaskFormSheet extends StatefulWidget {
  const _TaskFormSheet({required this.onSave});
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  String _status = 'todo';
  DateTime? _dueAt;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;
    setState(() {
      _dueAt = time == null
          ? picked
          : DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await widget.onSave({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority,
        'status': _status,
        if (_dueAt != null) 'due_at': _dueAt!.toIso8601String(),
        if (userId != null) 'user_id': userId,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return _SheetScaffold(
      title: 'New Task',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetField(
            label: 'Title',
            child: TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: GoogleFonts.inter(color: colors.textPrimary),
              decoration: _inputDecoration(colors, 'Task title...'),
            ),
          ),
          const SizedBox(height: 16),
          _SheetField(
            label: 'Description (optional)',
            child: TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(color: colors.textPrimary),
              decoration: _inputDecoration(colors, 'Add more details...'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SheetField(
                  label: 'Priority',
                  child: _PriorityDropdown(
                    value: _priority,
                    colors: colors,
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetField(
                  label: 'Status',
                  child: _StatusDropdown(
                    value: _status,
                    colors: colors,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SheetField(
            label: 'Due Date & Time',
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: colors.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      _dueAt == null
                          ? 'Tap to set due date'
                          : '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year}  ${_dueAt!.hour.toString().padLeft(2, '0')}:${_dueAt!.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        color: _dueAt == null ? colors.textMuted : colors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Create Task',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Task Detail / Edit Sheet ────────────────────────────────────────────────

class _TaskDetailSheet extends StatefulWidget {
  const _TaskDetailSheet({
    required this.raw,
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });

  final Map<String, dynamic> raw;
  final _TaskViewModel vm;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Future<void> Function() onDelete;

  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _priority;
  late String _status;
  DateTime? _dueAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.vm.title);
    _descCtrl = TextEditingController(text: widget.vm.subtitle);
    final pRaw = (widget.raw['priority'] ?? '').toString().toLowerCase();
    _priority = ['high', 'medium', 'low'].contains(pRaw) ? pRaw : 'medium';
    final sRaw = (widget.raw['status'] ?? '').toString().toLowerCase();
    _status = sRaw.contains('done') || sRaw.contains('complete')
        ? 'done'
        : sRaw.contains('progress')
            ? 'in_progress'
            : 'todo';
    final dueRaw = widget.raw['due_at'] ?? widget.raw['due_date'];
    if (dueRaw is String) _dueAt = DateTime.tryParse(dueRaw)?.toLocal();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _dueAt != null
          ? TimeOfDay(hour: _dueAt!.hour, minute: _dueAt!.minute)
          : TimeOfDay.now(),
    );
    if (!mounted) return;
    setState(() {
      _dueAt = time == null
          ? picked
          : DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority,
        'status': _status,
        if (_dueAt != null) 'due_at': _dueAt!.toIso8601String(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.onDelete();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final isFallback = widget.raw.isEmpty;

    return _SheetScaffold(
      title: 'Task Detail',
      trailing: isFallback
          ? null
          : IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
              onPressed: _saving ? null : _confirmDelete,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFallback)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: colors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a sample task. Create real tasks using the + button.',
                      style: GoogleFonts.inter(color: colors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          _SheetField(
            label: 'Title',
            child: TextField(
              controller: _titleCtrl,
              enabled: !isFallback,
              style: GoogleFonts.inter(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              decoration: _inputDecoration(colors, 'Task title...'),
            ),
          ),
          const SizedBox(height: 16),
          _SheetField(
            label: 'Description',
            child: TextField(
              controller: _descCtrl,
              enabled: !isFallback,
              maxLines: 3,
              style: GoogleFonts.inter(color: colors.textPrimary),
              decoration: _inputDecoration(colors, 'Add more details...'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SheetField(
                  label: 'Priority',
                  child: _PriorityDropdown(
                    value: _priority,
                    colors: colors,
                    enabled: !isFallback,
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetField(
                  label: 'Status',
                  child: _StatusDropdown(
                    value: _status,
                    colors: colors,
                    enabled: !isFallback,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SheetField(
            label: 'Due Date & Time',
            child: GestureDetector(
              onTap: isFallback ? null : _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: colors.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      _dueAt == null
                          ? widget.vm.dueLabel
                          : '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year}  ${_dueAt!.hour.toString().padLeft(2, '0')}:${_dueAt!.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(color: colors.textPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isFallback) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brand,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared Sheet Helpers ────────────────────────────────────────────────────

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colors.border),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

InputDecoration _inputDecoration(FitNexoraThemeTokens colors, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: colors.textMuted),
    filled: true,
    fillColor: colors.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.brand, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _PriorityDropdown extends StatelessWidget {
  const _PriorityDropdown({
    required this.value,
    required this.colors,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final FitNexoraThemeTokens colors;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: enabled ? (v) => onChanged(v ?? value) : null,
      dropdownColor: colors.surface,
      style: GoogleFonts.inter(color: colors.textPrimary),
      decoration: _inputDecoration(colors, ''),
      items: const [
        DropdownMenuItem(value: 'high', child: Text('High')),
        DropdownMenuItem(value: 'medium', child: Text('Medium')),
        DropdownMenuItem(value: 'low', child: Text('Low')),
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.value,
    required this.colors,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final FitNexoraThemeTokens colors;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: enabled ? (v) => onChanged(v ?? value) : null,
      dropdownColor: colors.surface,
      style: GoogleFonts.inter(color: colors.textPrimary),
      decoration: _inputDecoration(colors, ''),
      items: const [
        DropdownMenuItem(value: 'todo', child: Text('To Do')),
        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
        DropdownMenuItem(value: 'done', child: Text('Done')),
      ],
    );
  }
}

const _fallbackTasks = [
  _TaskViewModel(
    id: 'task-1',
    title: 'Morning HIIT Session Prep',
    subtitle: 'Check equipment and music playlist',
    status: _TaskStatus.todo,
    priority: _TaskPriority.high,
    dueLabel: '08:00 AM',
    dayLabel: 'Tomorrow, Oct 24',
    section: _TaskSection.today,
  ),
  _TaskViewModel(
    id: 'task-2',
    title: 'Client Progress Review',
    subtitle: 'Update Alex M. strength metrics',
    status: _TaskStatus.todo,
    priority: _TaskPriority.medium,
    dueLabel: '11:30 AM',
    dayLabel: 'Tomorrow, Oct 24',
    section: _TaskSection.today,
  ),
  _TaskViewModel(
    id: 'task-3',
    title: 'Nutrition Plan Draft',
    subtitle: 'Meal prep guide for Sarah J.',
    status: _TaskStatus.todo,
    priority: _TaskPriority.low,
    dueLabel: '04:00 PM',
    dayLabel: 'Tomorrow, Oct 24',
    section: _TaskSection.today,
  ),
  _TaskViewModel(
    id: 'task-4',
    title: 'Inventory Check',
    subtitle: 'Verify protein stock and towels',
    status: _TaskStatus.todo,
    priority: _TaskPriority.medium,
    dueLabel: 'Oct 24 - 09:00 AM',
    dayLabel: 'Tomorrow, Oct 24',
    section: _TaskSection.upcoming,
  ),
  _TaskViewModel(
    id: 'task-5',
    title: 'Meal Plan Adjustments',
    subtitle: 'Finalize macros for the evening coaching group.',
    status: _TaskStatus.inProgress,
    priority: _TaskPriority.low,
    dueLabel: '02:15 PM',
    dayLabel: 'Today',
    section: _TaskSection.today,
  ),
  _TaskViewModel(
    id: 'task-6',
    title: 'Studio Lighting Reset',
    subtitle: 'Done after the last transformation shoot.',
    status: _TaskStatus.done,
    priority: _TaskPriority.low,
    dueLabel: 'Yesterday - 07:45 PM',
    dayLabel: 'Yesterday',
    section: _TaskSection.today,
  ),
];
