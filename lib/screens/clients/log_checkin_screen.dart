import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Mock client data model for this screen.
class _MockClient {
  final String id;
  final String name;
  final String membershipType;
  const _MockClient({
    required this.id,
    required this.name,
    required this.membershipType,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

const _mockClients = [
  _MockClient(id: '1', name: 'Rahul Sharma', membershipType: 'Master'),
  _MockClient(id: '2', name: 'Priya Nair', membershipType: 'Elite'),
  _MockClient(id: '3', name: 'Amit Verma', membershipType: 'Pro'),
  _MockClient(id: '4', name: 'Sara Khan', membershipType: 'Basic'),
  _MockClient(id: '5', name: 'Dev Patel', membershipType: 'Elite'),
  _MockClient(id: '6', name: 'Ananya Singh', membershipType: 'Master'),
  _MockClient(id: '7', name: 'Kiran Reddy', membershipType: 'Pro'),
  _MockClient(id: '8', name: 'Meera Joshi', membershipType: 'Basic'),
];

Color _membershipColor(String type, FitNexoraThemeTokens t) {
  if (type == 'Expired' || type == 'Inactive') return t.danger;
  switch (type.toLowerCase()) {
    case 'master':
      return const Color(0xFFFF3D5E);
    case 'elite':
      return t.brand;
    case 'pro':
      return t.accent;
    default:
      return t.info;
  }
}

/// Log client check-in screen.
class LogCheckinScreen extends ConsumerStatefulWidget {
  const LogCheckinScreen({super.key});

  static const routePath = '/clients/checkin';

  @override
  ConsumerState<LogCheckinScreen> createState() => _LogCheckinScreenState();
}

class _LogCheckinScreenState extends ConsumerState<LogCheckinScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  String _query = '';
  String? _selectedClientId;
  DateTime _checkInTime = DateTime.now();
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkGym());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkGym();
  }

  void _checkGym() {
    if (_redirected || !mounted) return;
    final gym = ref.read(selectedGymProvider);
    if (gym == null) {
      _redirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No gym selected. Please access check-in from your dashboard.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: context.fitTheme.danger,
          ),
        );
        context.go('/dashboard');
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<_MockClient> get _filtered {
    if (_query.isEmpty) return _mockClients;
    final q = _query.toLowerCase();
    return _mockClients
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.membershipType.toLowerCase().contains(q))
        .toList();
  }

  _MockClient? get _selectedClient => _selectedClientId == null
      ? null
      : _mockClients.firstWhere(
          (c) => c.id == _selectedClientId,
          orElse: () => const _MockClient(id: '', name: '', membershipType: ''),
        );

  Future<void> _pickTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_checkInTime),
      );
      if (time != null && mounted) {
        setState(() {
          _checkInTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _confirmCheckIn() {
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a client first',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: context.fitTheme.danger,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Check-in confirmed for ${_selectedClient?.name ?? ''}',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: context.fitTheme.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final gym = ref.watch(selectedGymProvider);

    // Guard: if no gym is selected, show empty scaffold while redirect is pending
    if (gym == null) {
      return Scaffold(
          backgroundColor: t.background, body: const SizedBox.shrink());
    }

    final filtered = _filtered;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/clients'),
        ),
        title: Text(
          'Log Check-in',
          style: GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Search bar
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ClientSearchBar(
                      controller: _searchController,
                      t: t,
                      onChanged: (v) => setState(() => _query = v),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  ),
                ),

                // Selected client indicator
                if (_selectedClient != null && _selectedClient!.id.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: t.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.accent.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: t.accent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Selected: ${_selectedClient!.name}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: t.accent,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedClientId = null),
                              child: Icon(Icons.close_rounded,
                                  color: t.accent, size: 16),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                    ),
                  ),

                // Client list header
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      filtered.isEmpty
                          ? 'No clients found'
                          : 'CLIENTS (${filtered.length})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: t.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ).animate(delay: 60.ms).fadeIn(duration: 400.ms),
                  ),
                ),

                // Client list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: GlassmorphicCard(
                      child: Column(
                        children: filtered.asMap().entries.map((entry) {
                          final i = entry.key;
                          final client = entry.value;
                          final isSelected = _selectedClientId == client.id;
                          final memberColor =
                              _membershipColor(client.membershipType, t);

                          return Column(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _selectedClientId =
                                    isSelected ? null : client.id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? t.accent.withOpacity(0.2)
                                              : t.surfaceMuted,
                                          border: isSelected
                                              ? Border.all(
                                                  color: t.accent, width: 2)
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            client.initial,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? t.accent
                                                  : t.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              client.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: t.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: memberColor
                                                    .withOpacity(0.13),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                client.membershipType,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: memberColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(Icons.check_circle_rounded,
                                            color: t.accent, size: 22)
                                      else
                                        Icon(Icons.radio_button_unchecked,
                                            color: t.border, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                              if (i < filtered.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 14,
                                  endIndent: 14,
                                  color: t.divider,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    )
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08),
                  ),
                ),

                // Check-in time row
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CheckInTimeRow(
                      t: t,
                      checkInTime: _checkInTime,
                      onChangeTime: _pickTime,
                    )
                        .animate(delay: 140.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08),
                  ),
                ),

                // Notes textarea
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOTES (OPTIONAL)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: t.border),
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 4,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: t.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Add any notes about this check-in...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: t.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08),
                  ),
                ),
              ],
            ),
          ),

          // Confirm button
          _ConfirmButton(t: t, onConfirm: _confirmCheckIn)
              .animate(delay: 350.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.15),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client search bar
// ---------------------------------------------------------------------------

class _ClientSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FitNexoraThemeTokens t;
  final ValueChanged<String> onChanged;
  const _ClientSearchBar({
    required this.controller,
    required this.t,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 14, color: t.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search clients by name or plan...',
          hintStyle: GoogleFonts.inter(fontSize: 14, color: t.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: t.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check-in time row
// ---------------------------------------------------------------------------

class _CheckInTimeRow extends StatelessWidget {
  final FitNexoraThemeTokens t;
  final DateTime checkInTime;
  final VoidCallback onChangeTime;
  const _CheckInTimeRow({
    required this.t,
    required this.checkInTime,
    required this.onChangeTime,
  });

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHECK-IN TIME',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: t.textMuted,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.access_time_rounded, color: t.brand, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDateTime(checkInTime),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onChangeTime,
                  style: TextButton.styleFrom(
                    foregroundColor: t.brand,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    'Change',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: t.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Confirm button
// ---------------------------------------------------------------------------

class _ConfirmButton extends StatelessWidget {
  final FitNexoraThemeTokens t;
  final VoidCallback onConfirm;
  const _ConfirmButton({required this.t, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: t.background,
      child: Container(
        decoration: BoxDecoration(
          color: t.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: t.accent.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onConfirm,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'CONFIRM CHECK-IN',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
