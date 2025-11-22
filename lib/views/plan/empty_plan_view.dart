import 'package:flutter/material.dart';

class EmptyPlanView extends StatelessWidget {
  const EmptyPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Plan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ),

      body: Center(
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

              const Text(
                "Ready for an Adventure?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                "Tap the '+' button to map out your trail.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF13ec37),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
        onPressed: () {
          // TODO: Navigate to create hike
        },
      ),
    );
  }
}
