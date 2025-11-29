import 'package:flutter/material.dart';

class ObservationFormView extends StatelessWidget {
  const ObservationFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xfff5f5f5),
        automaticallyImplyLeading: true,
        title: const Text(
          'New Observation',
          style: TextStyle(
            color: Color(0xff2d572c),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            _buildTextField(
              label: 'Caption',
              placeholder: 'A brief title for your observation',
            ),

            const SizedBox(height: 24),

            _buildTextArea(
              label: 'Content',
              placeholder: 'Describe what you saw, heard, or felt...',
            ),

            const SizedBox(height: 32),

            const Text(
              'Media',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xff6b7280),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            _buildMediaGrid(),

            const SizedBox(height: 24),

            _buildCameraButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildTextField({
    required String label,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xff6b7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xff2d572c)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xff6b7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 6,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xff2d572c)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGrid() {
    List<String> demoImages = [
      "https://lh3.googleusercontent.com/aida-public/AB6AXuBbXgDqT1yMZlr2I4JMdYWypi7XipDUANymhDI_MRNqG7fQGM9beiaNHiBTKCVLeA-igReYDyym4Xcobj_uk0M8f2zZRI2LB-YzW41RYCNXfXC88XjJBFXB8MfQo5fycCAe4zWU-NOrBktNLcDx871x2wjgitE6AvoqjVt2hpjbxCMNqM-XDVc4X0fT6qFMH5nLcAuzYoPCa9dWWBCPfFQqQY_2YoFikFVboKItPy0DTtHEhrWzFwmVveyu35VTmDFv9RL-GEmk1sX9",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuDCBqa7W8n9VX347j2b3Y2q7D1EUV9r2xJmsE-9TjHkXHBA-sIHX7M49k3rFKSDwanv_hSdCtk5TduVsAfKYCCuBLB2GkdbdZGfztubltpVUujtM6jYUaB6fUzXRRuJqs_ZRNz9yvJRyKoAxSrMukNI2_eu1r6E4E_sC8pNN0Bsv6UfMMaDK0IJwCiVQk_6HHEyTGFVnSgovok6hZvvViIoJNRnwZCy-qylepjjYrnuMVklXM_7Mbd2VVD_T5o7BEcKcJBIYovYbiup",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuAEv0loD6gwKtVLc3Psaz9sWjuFGBfwS9UfPq3S7TPFCyFjf9jE-fb0lz9SQd0Y-hLRSejybKuVLQvkHSrorjlNTo4ELHv8VO5N8LPvmlVMKGRpdY4pktlk-3S5qE6eCCrPHjOk9i-Nq8LGfDmuwIBwDMkv2E0nT1FSKGW9l0Op8QD40emWztlyROPu8HmixtNPtCGlWxRg1toVZdcdFTrkRTwOAnDnCAkpuS-GlkpWBdtTjH4v0avz6hzY5Kfb_VHLixf4JnCxjGKF"
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...demoImages.map((url) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                  color: Colors.white,
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              )
            ],
          );
        }),

        // Add Media Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffd1d5db), width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_photo_alternate, color: Color(0xff9ca3af)),
                SizedBox(height: 4),
                Text(
                  'Add Media',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff6b7280),
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildCameraButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color.fromARGB(18, 0, 0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.photo_camera, color: Color(0xff2d572c)),
          SizedBox(width: 8),
          Text(
            'Capture from Camera',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff1f2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: const Color(0xfff5f5f5),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2d572c),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          onPressed: () {},
          child: const Text(
            'Submit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
