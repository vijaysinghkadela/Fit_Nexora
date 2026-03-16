import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';

/// Search exercise screen — can be used as full screen or bottom sheet.
/// Route: `/workout/exercise-search`
class SearchExerciseScreen extends ConsumerStatefulWidget {
  final bool isBottomSheet;
  final void Function(String exerciseName)? onAdd;

  const SearchExerciseScreen({
    super.key,
    this.isBottomSheet = false,
    this.onAdd,
  });

  @override
  ConsumerState<SearchExerciseScreen> createState() =>
      _SearchExerciseScreenState();
}

class _SearchExerciseScreenState extends ConsumerState<SearchExerciseScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _query = '';

  final List<String> _categories = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  final List<_ExerciseItem> _allExercises = const [
    _ExerciseItem(name: 'Barbell Bench Press', muscle: 'Chest', icon: Icons.fitness_center_rounded, category: 'Chest'),
    _ExerciseItem(name: 'Incline Dumbbell Press', muscle: 'Chest', icon: Icons.fitness_center_rounded, category: 'Chest'),
    _ExerciseItem(name: 'Cable Fly', muscle: 'Chest', icon: Icons.sports_gymnastics_rounded, category: 'Chest'),
    _ExerciseItem(name: 'Pull-Up', muscle: 'Lats, Biceps', icon: Icons.sports_gymnastics_rounded, category: 'Back'),
    _ExerciseItem(name: 'Barbell Row', muscle: 'Back, Rhomboids', icon: Icons.fitness_center_rounded, category: 'Back'),
    _ExerciseItem(name: 'Lat Pulldown', muscle: 'Lats', icon: Icons.sports_gymnastics_rounded, category: 'Back'),
    _ExerciseItem(name: 'Barbell Squat', muscle: 'Quads, Glutes', icon: Icons.fitness_center_rounded, category: 'Legs'),
    _ExerciseItem(name: 'Romanian Deadlift', muscle: 'Hamstrings, Glutes', icon: Icons.fitness_center_rounded, category: 'Legs'),
    _ExerciseItem(name: 'Leg Press', muscle: 'Quads', icon: Icons.sports_gymnastics_rounded, category: 'Legs'),
    _ExerciseItem(name: 'Overhead Press', muscle: 'Shoulders', icon: Icons.fitness_center_rounded, category: 'Shoulders'),
    _ExerciseItem(name: 'Lateral Raise', muscle: 'Deltoids', icon: Icons.sports_gymnastics_rounded, category: 'Shoulders'),
    _ExerciseItem(name: 'Barbell Curl', muscle: 'Biceps', icon: Icons.fitness_center_rounded, category: 'Arms'),
    _ExerciseItem(name: 'Tricep Pushdown', muscle: 'Triceps', icon: Icons.sports_gymnastics_rounded, category: 'Arms'),
    _ExerciseItem(name: 'Plank', muscle: 'Core', icon: Icons.self_improvement_rounded, category: 'Core'),
    _ExerciseItem(name: 'Cable Crunch', muscle: 'Abs', icon: Icons.sports_gymnastics_rounded, category: 'Core'),
  ];

  List<_ExerciseItem> get _filtered {
    return _allExercises.where((e) {
      final matchesCategory =
          _selectedCategory == 'All' || e.category == _selectedCategory;
      final matchesQuery = _query.isEmpty ||
          e.name.toLowerCase().contains(_query.toLowerCase()) ||
          e.muscle.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final filtered = _filtered;

    final content = Column(
      children: [
        // Handle for bottom sheet
        if (widget.isBottomSheet) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Search Field ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            style: GoogleFonts.inter(
                fontSize: 14, color: t.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: Icon(Icons.search_rounded, color: t.textMuted, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: Icon(Icons.clear_rounded,
                          color: t.textMuted, size: 18),
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: t.surfaceAlt,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: t.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: t.brand, width: 1.4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Filter Chips ──────────────────────────────────────────────
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;

              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? t.brand
                        : t.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? t.brand : t.border,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : t.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),
        Divider(height: 1, color: t.divider),

        // ── Exercise List ────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48, color: t.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No exercises found',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _ExerciseListItem(
                      exercise: filtered[index],
                      onAdd: () {
                        widget.onAdd?.call(filtered[index].name);
                        if (widget.isBottomSheet) {
                          Navigator.maybePop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${filtered[index].name} added to workout'),
                              backgroundColor: t.accent,
                            ),
                          );
                        }
                      },
                    )
                        .animate(delay: (index * 40).ms)
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.05);
                  },
                ),
        ),
      ],
    );

    if (widget.isBottomSheet) {
      return Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Add Exercise',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
      ),
      body: content,
    );
  }
}

class _ExerciseListItem extends StatelessWidget {
  final _ExerciseItem exercise;
  final VoidCallback onAdd;

  const _ExerciseListItem({
    required this.exercise,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return GlassmorphicCard(
      borderRadius: 14,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(exercise.icon, color: t.brand, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      exercise.muscle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: t.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                backgroundColor: t.brand.withValues(alpha: 0.12),
                foregroundColor: t.brand,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Add',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseItem {
  final String name;
  final String muscle;
  final IconData icon;
  final String category;

  const _ExerciseItem({
    required this.name,
    required this.muscle,
    required this.icon,
    required this.category,
  });
}
