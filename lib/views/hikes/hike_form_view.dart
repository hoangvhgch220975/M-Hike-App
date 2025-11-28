import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/hike_viewmodel.dart';
import '../../models/hike.dart';

class HikeFormView extends StatefulWidget {
  final Hike? hike; // if provided, we're editing

  const HikeFormView({super.key, this.hike});

  @override
  State<HikeFormView> createState() => _HikeFormViewState();
}

class _HikeFormViewState extends State<HikeFormView> {
  final nameController = TextEditingController();
  final dateController = TextEditingController(text: 'August 12, 2024');
  final lengthController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  String difficulty = 'Moderate';
  bool parkingAvailable = true;

  Color get primary => const Color(0xFF2C5E1A);
  Color get accent => const Color(0xFF87CEEB);

  Color backgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF101813) : const Color(0xFFF5F5F5);
  }

  Color surfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  Color borderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
  }

  Color secondaryText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade300 : const Color(0xFF8B4513);
  }

  Color primaryText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black;
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              onSurface: primaryText(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          "${_monthName(picked.month)} ${picked.day}, ${picked.year}";
      setState(() {
        dateController.text = formatted;
      });
    }
  }

  String _monthName(int month) {
    const months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month];
  }

  @override
  void initState() {
    super.initState();
    // If editing, populate controllers
    if (widget.hike != null) {
      final h = widget.hike!;
      nameController.text = h.name;
      dateController.text = h.date;
      lengthController.text = h.length.toString();
      locationController.text = h.location;
      descriptionController.text = h.description ?? '';
      difficulty = h.difficulty;
      // parkingAvailable isn't stored on Hike model; leave default
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HikeViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor(context),
      appBar: AppBar(
        title: Text(
          widget.hike == null ? "Add Hike" : "Edit Hike",
          style: TextStyle(
            color: primaryText(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor(context),
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: vm.formKey,
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 24),
              _buildForm(context),
              const SizedBox(height: 24),
              _saveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Text(
          "M - Hike",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Log your latest adventure.",
          style: TextStyle(
            color: secondaryText(context),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        _inputField(context, "Hike Name", nameController),
        const SizedBox(height: 16),

        _dateField(context),
        const SizedBox(height: 16),

        _inputField(context, "Length", lengthController,
            hint: "e.g., 5.5 km"),
        const SizedBox(height: 16),

        _difficultyDropdown(context),
        const SizedBox(height: 16),

        _parkingSwitch(context),
        const SizedBox(height: 16),

        _locationField(context),
        const SizedBox(height: 16),

        _textAreaField(context, "Description", descriptionController),
      ],
    );
  }

  Widget _inputField(BuildContext context, String label, TextEditingController c,
      {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(context)),
        const SizedBox(height: 6),
        TextFormField(
          controller: c,
          decoration: _inputDecoration(context, hint: hint),
          validator: (v) {
            if ((label == 'Hike Name' || label == 'Length' || label == 'Location') && (v == null || v.trim().isEmpty)) {
              return 'This field is required';
            }
            if (label == 'Length' && v != null && v.trim().isNotEmpty) {
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Invalid length';
            }
            return null;
          },
        ),
      ],
    );
  }

  TextStyle _labelStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: secondaryText(context),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: surfaceColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _dateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Date", style: _labelStyle(context)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: pickDate,
          child: AbsorbPointer(
            child: TextFormField(
              controller: dateController,
              decoration: _inputDecoration(context).copyWith(
                suffixIcon: Icon(Icons.calendar_today,
                    color: Colors.grey.shade500),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please choose a date' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _difficultyDropdown(BuildContext context) {
    final choices = ["Easy", "Moderate", "Hard", "Expert"];
    final onPrimary = ThemeData.estimateBrightnessForColor(primary) == Brightness.dark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Difficulty", style: _labelStyle(context)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: surfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor(context)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: choices.map((d) {
              final isSelected = d == difficulty;
              return ChoiceChip(
                label: Text(d, style: TextStyle(fontWeight: FontWeight.w600)),
                selected: isSelected,
                onSelected: (_) => setState(() => difficulty = d),
                selectedColor: primary,
                disabledColor: surfaceColor(context),
                backgroundColor: surfaceColor(context),
                elevation: isSelected ? 4 : 0,
                side: BorderSide(color: isSelected ? primary : borderColor(context)),
                labelStyle: TextStyle(
                  color: isSelected ? onPrimary : primaryText(context),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _parkingSwitch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor(context)),
      ),
      child: Row(
        children: [
          Text(
            "Parking Available",
            style: TextStyle(
              color: primaryText(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Switch(
            value: parkingAvailable,
            activeColor: primary,
            onChanged: (v) => setState(() => parkingAvailable = v),
          ),
        ],
      ),
    );
  }

  Widget _locationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Location", style: _labelStyle(context)),
        const SizedBox(height: 6),

        TextFormField(
          controller: locationController,
          decoration: _inputDecoration(context,
              hint: "Enter address or coordinates"),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Provide a location' : null,
        ),
        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: accent.withOpacity(0.2),
            foregroundColor: accent,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.map),
          label: const Text(
            "Pick on map",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _textAreaField(
      BuildContext context, String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(context)),
        const SizedBox(height: 6),
        TextFormField(
          controller: c,
          maxLines: 5,
          decoration: _inputDecoration(context, hint: "Share something..."),
        ),
      ],
    );
  }

  Widget _saveButton() {
    return ElevatedButton(
      onPressed: () async {
        final vm = Provider.of<HikeViewModel>(context, listen: false);

        // Populate VM fields
        vm.name = nameController.text.trim();
        vm.location = locationController.text.trim();
        vm.date = dateController.text.trim();
        vm.length = double.tryParse(lengthController.text.trim()) ?? 0.0;
        vm.difficulty = difficulty;
        vm.description = descriptionController.text.trim();

        if (!vm.formKey.currentState!.validate()) return;

        final success = await vm.saveHike(id: widget.hike?.id);

        if (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.hike == null ? 'Hike added' : 'Hike updated')));
            Navigator.of(context).pop(true);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save hike')));
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      child: const Text(
        "Save Hike",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
