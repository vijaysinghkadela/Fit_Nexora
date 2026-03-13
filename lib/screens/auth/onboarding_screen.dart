import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Post-registration onboarding for gym owners.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gymNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _gymNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createGym() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) throw Exception('User not found');

      final db = ref.read(databaseServiceProvider);
      final gym = await db.createGym(
        name: _gymNameController.text.trim(),
        ownerId: currentUser.id,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      ref.read(selectedGymProvider.notifier).state = gym;

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating gym: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          _buildBackgroundEffects(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      _buildProgressIndicator(),
                      const SizedBox(height: 40),
                      if (_currentStep == 0) _buildWelcomeStep(),
                      if (_currentStep == 1) _buildGymDetailsStep(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundEffects() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.accent.withValues(alpha: 0.1),
                AppColors.accent.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        final isActive = index <= _currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 12,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isActive ? AppColors.accent : AppColors.border,
          ),
        ).animate(delay: Duration(milliseconds: index * 100)).fadeIn();
      }),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: const Icon(Icons.rocket_launch_rounded,
              size: 40, color: Colors.white),
        ).animate().scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 32),
        Text(
          'You\'re in! 🎉',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 12),
        Text(
          'Let\'s set up your gym in under a minute.\nReady?',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ).animate(delay: 400.ms).fadeIn(),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Let\'s go →',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildGymDetailsStep() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your Gym Details',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll use this to set up your workspace.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Gym Name
              TextFormField(
                controller: _gymNameController,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Gym Name *',
                  hintText: 'Iron Paradise Fitness',
                  prefixIcon: Icon(Icons.fitness_center_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Gym name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Address
              TextFormField(
                controller: _addressController,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: '123 Main Street, City',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: AppColors.textMuted, size: 20),
                ),
              ),

              const SizedBox(height: 18),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Gym Phone',
                  hintText: '+91 9876543210',
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: AppColors.textMuted, size: 20),
                ),
              ),

              const SizedBox(height: 28),

              // Plan selection hint
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You\'ll start on the Basic plan. Upgrade anytime.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    child: const Text('← Back'),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createGym,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'Launch Gym 🚀',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
