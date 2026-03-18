import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../../models/gym_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/fit_auth_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.gymOwner;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;
  String? _selectedCity;
  Gym? _selectedGym;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      setState(() =>
          _errorMessage = 'Please accept the terms to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(currentUserProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _selectedRole,
            gymId: _selectedGym?.id,
          );

      if (!mounted) return;
      switch (_selectedRole) {
        case UserRole.gymOwner:
          context.go('/onboarding');
          break;
        case UserRole.trainer:
          context.go('/trainer');
          break;
        case UserRole.client:
          context.go('/member');
          break;
        case UserRole.superAdmin:
          context.go('/admin');
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e.toString());
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String error) {
    debugPrint('Registration Error: $error');
    if (error.contains('already registered') ||
        error.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (error.contains('weak password')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    if (error.contains('network') || error.contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    }
    if (error.contains('configuration') || error.contains('dotenv')) {
      return 'Server configuration error. Please contact support.';
    }
    return 'Registration failed: ${error.replaceAll('Exception:', '').trim()}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return FitAuthScaffold(
      title: 'Create account',
      subtitle:
          'Start building your FitNexora workspace or member journey.',
      heroIcon: Icons.person_add_alt_1_rounded,
      footer: Column(
        children: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role selector
                _RoleSelector(
                  selectedRole: _selectedRole,
                  onChanged: (role) =>
                      setState(() => _selectedRole = role),
                ),
                const SizedBox(height: 20),

                // City selection
                Consumer(
                  builder: (context, ref, child) {
                    final citiesAsync = ref.watch(citiesProvider);
                    return citiesAsync.when(
                      data: (cities) {
                        if (cities.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: t.surfaceAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: t.border),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.location_off_rounded, color: t.textSecondary, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'No cities available in the database yet.',
                                  style: TextStyle(color: t.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'Select City',
                            prefixIcon: Icon(Icons.location_city_rounded),
                          ),
                          items: cities.map((city) {
                            return DropdownMenuItem(value: city, child: Text(city));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCity = value;
                              _selectedGym = null;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a city first';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, st) => Text('Error loading cities', style: TextStyle(color: t.danger)),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Gym selection
                if (_selectedCity != null)
                  Consumer(
                    builder: (context, ref, child) {
                      final gymsAsync = ref.watch(gymsByCityProvider(_selectedCity!));
                      return gymsAsync.when(
                        data: (gyms) {
                          if (gyms.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No gyms found in this city.', style: TextStyle(color: t.textSecondary)),
                            );
                          }
                          return DropdownButtonFormField<Gym>(
                            value: _selectedGym,
                            decoration: const InputDecoration(
                              labelText: 'Select Gym',
                              prefixIcon: Icon(Icons.storefront_rounded),
                            ),
                            items: gyms.map((gym) {
                              return DropdownMenuItem(value: gym, child: Text(gym.name));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGym = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a gym';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, st) => Text('Error loading gyms', style: TextStyle(color: t.danger)),
                      );
                    },
                  ),
                if (_selectedCity != null) const SizedBox(height: 14),

                // Error banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: t.danger.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: t.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: t.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn()
                      .shake(hz: 2, offset: const Offset(4, 0)),
                  const SizedBox(height: 16),
                ],

                // Full name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon:
                        Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.call_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon:
                        const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Terms checkbox
                GestureDetector(
                  onTap: () =>
                      setState(() => _agreedToTerms = !_agreedToTerms),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _agreedToTerms
                              ? t.brand
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _agreedToTerms
                                ? t.brand
                                : t.border,
                            width: 1.5,
                          ),
                        ),
                        child: _agreedToTerms
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: t.textSecondary),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Privacy Policy',
                                style: TextStyle(
                                  color: t.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Register button with gradient
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.brand, t.brandSecondary],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: t.brand.withOpacity(0.36),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18)),
                      ),
                      onPressed:
                          _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create account',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role selector chips
// ---------------------------------------------------------------------------

class _RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    const roles = [
      _RoleChip(
          role: UserRole.gymOwner,
          label: 'Owner',
          icon: Icons.storefront_outlined),
      _RoleChip(
          role: UserRole.trainer,
          label: 'Trainer',
          icon: Icons.fitness_center_outlined),
      _RoleChip(
          role: UserRole.client,
          label: 'Member',
          icon: Icons.person_outline_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: roles.map((chip) {
            final isSelected = chip.role == selectedRole;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(chip.role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                      right: chip.role == roles.last.role ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? t.brand.withOpacity(0.13)
                        : t.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? t.brand : t.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        chip.icon,
                        size: 22,
                        color: isSelected ? t.brand : t.textSecondary,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        chip.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? t.brand
                              : t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RoleChip {
  final UserRole role;
  final String label;
  final IconData icon;

  const _RoleChip(
      {required this.role, required this.label, required this.icon});
}
