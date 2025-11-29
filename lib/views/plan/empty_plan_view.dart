import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/hike_viewmodel.dart';
import '../hikes/hike_form_view.dart';

class EmptyPlanView extends StatefulWidget {
  const EmptyPlanView({super.key});

  @override
  State<EmptyPlanView> createState() => _EmptyPlanViewState();
}

class _EmptyPlanViewState extends State<EmptyPlanView> {
  Future<void> _refreshData() async {
    final viewModel = Provider.of<HikeViewModel>(context, listen: false);
    await viewModel.loadPlan(); // Load only planned hikes
  }

  Future<void> _openHikeForm() async {
    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (ctx) => const HikeFormView()),
    );

    if (result == true) {
      final vm = Provider.of<HikeViewModel>(context, listen: false);
      await vm.loadPlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: theme.cardColor.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Image.asset('lib/assets/images/hike_logo.png', width: 32, height: 32, fit: BoxFit.contain),
        ),
        title: Text('Plan', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
      ),

      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 100,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: NetworkImage(
                            "https://lh3.googleusercontent.com/aida-public/AB6AXuCT9Wk5hRs2Aedn2xpgHTl_Kv_cjlKoEOPelJjFhFCxviIWVcXCyLS7C_EcBVdOSjhBgfc7HYDBHQQmh6EOU_nthbxSe384LVrbQ-Tz8VDn1vfBKFNQ5c4yBdiSsWzRre8JOByYCS5Mh0_owX9Zn-V2NDxVcLRcKpntp1P-oEmlsuTe-m7zE9-zZoUl51KIUweQEj45GnkH_CyPINKE6CGMtYaK7LEKtxTCav_Ag0JcSNhXIDR-Oia8laKQYtZ1fX7ddZL_CBzoKi0E",
                          ),
                          fit: BoxFit.contain,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      "Ready for an Adventure?",
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Tap the '+' button to map out your trail.",
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: theme.hintColor),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Add button shown in empty state
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openHikeForm,
                        icon: const Icon(Icons.add),
                        label: const Text('Add your first hike'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
