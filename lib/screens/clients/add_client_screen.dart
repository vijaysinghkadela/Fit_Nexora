import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/validators.dart';
import '../../models/client_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/gym_provider.dart';


/// Bottom sheet form for adding a new client.
class AddClientScreen extends ConsumerStatefulWidget {
  final ClientProfile? existingClient; // null = add mode, non-null = edit mode

  const AddClientScreen({super.key, this.existingClient});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _restrictionsController;
  late final TextEditingController _injuriesController;

  late String _sex;
  late FitnessGoal _goal;
  late TrainingLevel _trainingLevel;
  late DietType _dietType;
  late int _daysPerWeek;
  late EquipmentType _equipmentType;

  bool _isLoading = false;
  bool get _isEditMode => widget.existingClient != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingClient;
    _nameController = TextEditingController(text: c?.fullName ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _ageController = TextEditingController(text: c?.age?.toString() ?? '');
    _weightController =
        TextEditingController(text: c?.weightKg?.toString() ?? '');
    _heightController =
        TextEditingController(text: c?.heightCm?.toString() ?? '');
    _restrictionsController =
        TextEditingController(text: c?.restrictions ?? '');
    _injuriesController = TextEditingController(text: c?.injuries ?? '');
    _sex = c?.sex ?? 'male';
    _goal = c?.goal ?? FitnessGoal.generalFitness;
    _trainingLevel = c?.trainingLevel ?? TrainingLevel.beginner;
    _dietType = c?.dietType ?? DietType.nonVegetarian;
    _daysPerWeek = c?.daysPerWeek ?? 3;
    _equipmentType = c?.equipmentType ?? EquipmentType.fullGym;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _restrictionsController.dispose();
    _injuriesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gym = ref.read(selectedGymProvider);
      if (gym == null) throw Exception('No gym selected');

      final db = ref.read(databaseServiceProvider);

      final userState = ref.read(currentUserProvider);
      final currentUser = userState.value;

      // Auto-assign the trainer if the current user is a trainer and we're adding a new client
      String? assignedTrainerId = widget.existingClient?.assignedTrainerId;
      if (!_isEditMode &&
          currentUser != null &&
          currentUser.globalRole == UserRole.trainer) {
        assignedTrainerId = currentUser.id;
      }

      final clientData = ClientProfile(
        id: widget.existingClient?.id ?? '',
        userId: widget.existingClient?.userId,
        gymId: gym.id,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        age: int.tryParse(_ageController.text),
        sex: _sex,
        weightKg: double.tryParse(_weightController.text),
        heightCm: double.tryParse(_heightController.text),
        goal: _goal,
        trainingLevel: _trainingLevel,
        daysPerWeek: _daysPerWeek,
        equipmentType: _equipmentType,
        dietType: _dietType,
        restrictions: _restrictionsController.text.trim().isEmpty
            ? null
            : _restrictionsController.text.trim(),
        injuries: _injuriesController.text.trim().isEmpty
            ? null
            : _injuriesController.text.trim(),
        assignedTrainerId: assignedTrainerId,
        createdAt: widget.existingClient?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditMode) {
        await db.updateClient(clientData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client profile updated successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await db.addClient(clientData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New client added successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      if (mounted) {
        ref.invalidate(gymClientsProvider);
        ref.invalidate(pagedClientsControllerProvider);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
          left: BorderSide(color: AppColors.glassBorder, width: 1),
          right: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditMode ? 'Edit Client' : 'Add New Client',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Personal Info', Icons.person_outline),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      hint: 'Rahul Sharma',
                      icon: Icons.person_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'rahul@email.com',
                            icon: Icons.email_outlined,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? null
                                : AppValidators.email(v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            hint: '+91 9876543210',
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            validator: AppValidators.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: _buildTextField(
                            controller: _ageController,
                            label: 'Age',
                            hint: '25',
                            icon: Icons.cake_outlined,
                            keyboard: TextInputType.number,
                            validator: AppValidators.age,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: _buildSexSelector(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    _buildSectionHeader(
                        'Body Metrics', Icons.monitor_weight_outlined),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: _buildTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            hint: '72',
                            icon: Icons.monitor_weight_outlined,
                            keyboard: TextInputType.number,
                            validator: AppValidators.weightKg,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: _buildTextField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            hint: '175',
                            icon: Icons.height_rounded,
                            keyboard: TextInputType.number,
                            validator: AppValidators.heightCm,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    _buildSectionHeader(
                        'Fitness Profile', Icons.fitness_center_rounded),
                    const SizedBox(height: 14),
                    _buildDropdown<FitnessGoal>(
                      label: 'Fitness Goal',
                      value: _goal,
                      items: FitnessGoal.values,
                      labelBuilder: (g) => g.label,
                      onChanged: (v) => setState(() => _goal = v!),
                    ),
                    const SizedBox(height: 14),
                    _buildDropdown<TrainingLevel>(
                      label: 'Training Level',
                      value: _trainingLevel,
                      items: TrainingLevel.values,
                      labelBuilder: (l) => l.label,
                      onChanged: (v) => setState(() => _trainingLevel = v!),
                    ),
                    const SizedBox(height: 14),
                    _buildDaysPerWeekSelector(),
                    const SizedBox(height: 14),
                    _buildEquipmentSelector(),

                    const SizedBox(height: 28),
                    _buildSectionHeader(
                        'Diet & Restrictions', Icons.restaurant_menu_rounded),
                    const SizedBox(height: 14),
                    _buildDropdown<DietType>(
                      label: 'Dietary Preference',
                      value: _dietType,
                      items: DietType.values,
                      labelBuilder: (d) => d.label,
                      onChanged: (v) => setState(() => _dietType = v!),
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _restrictionsController,
                      label: 'Allergies / Restrictions',
                      hint: 'Lactose intolerant, no shellfish…',
                      icon: Icons.no_food_rounded,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 28),
                    _buildSectionHeader(
                        'Health Notes', Icons.health_and_safety_outlined),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _injuriesController,
                      label: 'Injuries / Limitations',
                      hint: 'Lower back pain, shoulder impingement…',
                      icon: Icons.healing_rounded,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                _isEditMode ? 'Save Changes' : 'Add Client',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms).fadeIn();
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: AppColors.textMuted.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  labelBuilder(item),
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: AppColors.bgElevated,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildSexSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sex',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildChip(
                  'Male', _sex == 'male', () => setState(() => _sex = 'male')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChip('Female', _sex == 'female',
                  () => setState(() => _sex = 'female')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaysPerWeekSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Training Days / Week',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final day = i + 1;
            final isSelected = day == _daysPerWeek;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _daysPerWeek = day),
                child: AnimatedContainer(
                  duration: 200.ms,
                  margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.bgInput,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border.withOpacity(0.5),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEquipmentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Equipment',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            _buildChip('Full Gym', _equipmentType == EquipmentType.fullGym,
                () => setState(() => _equipmentType = EquipmentType.fullGym)),
            _buildChip(
                'Home w/ Equip',
                _equipmentType == EquipmentType.homeWithEquipment,
                () => setState(
                    () => _equipmentType = EquipmentType.homeWithEquipment)),
            _buildChip(
                'Minimal',
                _equipmentType == EquipmentType.homeMinimal,
                () =>
                    setState(() => _equipmentType = EquipmentType.homeMinimal)),
            _buildChip(
                'Bodyweight',
                _equipmentType == EquipmentType.bodyweightOnly,
                () => setState(
                    () => _equipmentType = EquipmentType.bodyweightOnly)),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withOpacity(0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
