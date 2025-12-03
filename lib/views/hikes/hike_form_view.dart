import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/hike_viewmodel.dart';
import '../../models/hike.dart';
import '../map/map_picker_view.dart';

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
  final durationController = TextEditingController(text: '1');

  String difficulty = 'Moderate';
  bool parkingAvailable = true;
  int estimatedDuration = 1;

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
      durationController.text = (h.estimatedDuration ?? 1).toString();
      difficulty = h.difficulty;
      parkingAvailable = h.hasParking;
      estimatedDuration = h.estimatedDuration ?? 1;
      // Populate the ViewModel with the existing hike values so saving doesn't overwrite flags
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = Provider.of<HikeViewModel>(context, listen: false);
        vm.name = h.name;
        vm.location = h.location;
        vm.date = h.date;
        vm.length = h.length;
        vm.difficulty = h.difficulty;
        vm.description = h.description;
        vm.isComplete = h.isComplete;
        vm.isRemarkable = h.isRemarkable;
        vm.hasParking = h.hasParking;
        vm.estimatedDuration = h.estimatedDuration;
        vm.latitude = h.latitude;
        vm.longitude = h.longitude;
        vm.isMapPicked = h.isMapPicked;
        vm.isLengthFromMap = h.isLengthFromMap;
      });
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

        _lengthField(context),
        const SizedBox(height: 16),

        _difficultyDropdown(context),
        const SizedBox(height: 16),

        _parkingSwitch(context),
        const SizedBox(height: 16),

        _durationField(context),
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

  Widget _durationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Estimated Duration (days)", style: _labelStyle(context)),
        const SizedBox(height: 6),
        TextFormField(
          controller: durationController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(context, hint: "e.g., 1, 2, 3..."),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Duration is required';
            }
            final n = int.tryParse(v.trim());
            if (n == null || n <= 0) {
              return 'Please enter a valid number of days';
            }
            if (n > 5) {
              return 'Duration cannot exceed 5 days';
            }
            return null;
          },
          onChanged: (v) {
            final n = int.tryParse(v.trim());
            if (n != null && n > 0) {
              setState(() => estimatedDuration = n);
            }
          },
        ),
      ],
    );
  }

  Widget _locationField(BuildContext context) {
    final vm = Provider.of<HikeViewModel>(context);
    final isMapLocation = vm.isMapPicked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Location", style: _labelStyle(context)),
            if (isMapLocation) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, size: 14, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      "From Map",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        TextFormField(
          controller: locationController,
          enabled: !isMapLocation,
          decoration: _inputDecoration(context,
              hint: isMapLocation
                  ? "Location picked from map"
                  : "Enter address or coordinates"),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Provide a location' : null,
          style: TextStyle(
            color: isMapLocation ? Colors.grey : primaryText(context),
          ),
        ),
        const SizedBox(height: 12),

        // Map picker button - Nút chọn vị trí trên map
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMapLocation
                ? [primary.withOpacity(0.1), accent.withOpacity(0.1)]
                : [primary.withOpacity(0.05), accent.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isMapLocation ? primary : borderColor(context),
              width: isMapLocation ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Main map picker button
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapPickerView(),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    print('📥 [FORM] RECEIVED FROM MAP: $result');

                    setState(() {
                      locationController.text = result['location'] ?? 'Unknown Location';
                      print('✅ [FORM] Location set: ${locationController.text}');

                      // Set length from map distance if available
                      if (result['distance'] != null) {
                        print('✅ [FORM] Setting length to: ${result['distance']}');
                        lengthController.text = result['distance'].toString();
                        print('✅ [FORM] Length controller now: ${lengthController.text}');
                      } else {
                        print('⚠️ [FORM] No distance in result! Map HTML needs update.');
                      }
                    });

                    final vm = Provider.of<HikeViewModel>(context, listen: false);
                    vm.location = result['location'] ?? 'Unknown Location';
                    vm.latitude = result['latitude'];
                    vm.longitude = result['longitude'];
                    vm.isMapPicked = true;
                    print('✅ [FORM] VM flags set - isMapPicked: true');

                    // Set length from map
                    if (result['distance'] != null) {
                      vm.length = result['distance'] as double;
                      vm.isLengthFromMap = true;
                      print('✅ [FORM] VM length set: ${vm.length} km, isLengthFromMap: true');
                    } else {
                      print('⚠️ [FORM] VM length NOT set - no distance in payload');
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon container with gradient background
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, primary.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMapLocation
                                ? "Location Selected"
                                : "Pick Location on Map",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryText(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMapLocation
                                ? "Tap to change location"
                                : "Choose location & calculate distance",
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow or checkmark icon
                      Icon(
                        isMapLocation ? Icons.check_circle : Icons.arrow_forward_ios,
                        color: isMapLocation ? primary : Colors.grey.shade400,
                        size: isMapLocation ? 28 : 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Clear button when location is selected
              if (isMapLocation) ...[
                Divider(
                  height: 1,
                  color: borderColor(context).withOpacity(0.5),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      locationController.clear();
                      lengthController.clear();
                    });
                    final vm = Provider.of<HikeViewModel>(context, listen: false);
                    vm.location = '';
                    vm.latitude = null;
                    vm.longitude = null;
                    vm.isMapPicked = false;
                    vm.length = 0.0;
                    vm.isLengthFromMap = false;
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Clear Map Selection",
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _lengthField(BuildContext context) {
    final vm = Provider.of<HikeViewModel>(context);
    final isLengthFromMap = vm.isLengthFromMap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Length (km)", style: _labelStyle(context)),
            if (isLengthFromMap) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.straighten, size: 14, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      "From Map",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: lengthController,
          enabled: !isLengthFromMap,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(context,
              hint: isLengthFromMap
                  ? "Length calculated from map route"
                  : "e.g., 5.5"),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Length is required';
            }
            final n = double.tryParse(v.trim());
            if (n == null || n <= 0) return 'Invalid length';
            return null;
          },
          style: TextStyle(
            color: isLengthFromMap ? Colors.grey : primaryText(context),
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
        // Ensure the ViewModel receives the parking value from the form
        vm.hasParking = parkingAvailable;
        // Parse and set estimated duration
        vm.estimatedDuration = int.tryParse(durationController.text.trim()) ?? 1;
        // If we're editing an existing hike, preserve its completion/remarkable state
        // Don't set isComplete/isRemarkable here — saveHike() will fetch the
        // existing database record (if id != null) and preserve those flags.

        if (!vm.formKey.currentState!.validate()) return;

        final success = await vm.saveHike(id: widget.hike?.id);

        if (success) {
          // Refresh VM data so feed/plan/remarkable lists update across the app
          await vm.reloadAll();

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
