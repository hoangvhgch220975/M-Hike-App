import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../db/app_db.dart';
import '../../models/observation.dart';
import '../../models/media_item.dart';

class ObservationFormView extends StatefulWidget {
  final int? hikeId; // required for adding
  final int? observationId; // present when editing

  const ObservationFormView({super.key, this.hikeId, this.observationId});

  @override
  State<ObservationFormView> createState() => _ObservationFormViewState();
}

class _ObservationFormViewState extends State<ObservationFormView> {
  final _captionCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _hikeId;
  int? _observationId;
  List<MediaItem> _media = []; // existing media (from DB) when editing
  List<String> _newMediaPaths = []; // newly picked media paths

  @override
  void initState() {
    super.initState();
    _hikeId = widget.hikeId;
    _observationId = widget.observationId;
    _loadIfEditing();
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIfEditing() async {
    if (_observationId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final obs = await AppDatabase.instance.getObservationById(_observationId!);
      if (!mounted) return;
      if (obs != null) {
        _captionCtrl.text = obs.caption;
        _contentCtrl.text = obs.content;
        _hikeId = obs.hikeId;
        _media = obs.media; // MediaItem list
      }
    } catch (e) {
      // ignore for now
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() {
      _newMediaPaths.add(file.path);
    });
  }

  Widget _buildMediaGrid() {
    final demoImages = <String>[]; // keep demo removed when real data present

    // Build combined list: existing media paths followed by new ones
    final combined = [for (var m in _media) m.path] + _newMediaPaths;

    if (combined.isEmpty) {
      // show existing placeholder grid from original UI for empty state
      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        physics: const NeverScrollableScrollPhysics(),
        children: [
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
                  Text('Add Media', style: TextStyle(fontSize: 11, color: Color(0xff6b7280), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: combined.map((path) {
        final isNew = _newMediaPaths.contains(path);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                color: Colors.white,
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isNew) {
                      _newMediaPaths.remove(path);
                    } else {
                      // mark existing media for deletion by removing from _media
                      _media.removeWhere((m) => m.path == path);
                    }
                  });
                },
                child: Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.close, size: 18, color: Colors.white)),
                ),
              ),
            )
          ],
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_hikeId == null) {
      // cannot save without hike id
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing hike reference')));
      return;
    }

    final caption = _captionCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (caption.isEmpty && content.isEmpty && _media.isEmpty && _newMediaPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add some content or media')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_observationId == null) {
        // Insert new observation
        final obs = Observation(hikeId: _hikeId!, caption: caption, content: content, time: DateTime.now().toIso8601String());
        final newId = await AppDatabase.instance.insertObservation(obs);
        // insert media if any
        if (_newMediaPaths.isNotEmpty) {
          final mediaItems = _newMediaPaths.map((p) => MediaItem(observationId: newId, path: p, type: 'image')).toList();
          await AppDatabase.instance.insertMediaItems(mediaItems);
        }
      } else {
        // Update existing observation
        final obs = Observation(id: _observationId, hikeId: _hikeId!, caption: caption, content: content, time: DateTime.now().toIso8601String());
        await AppDatabase.instance.updateObservation(obs);

        // Remove existing media rows for this observation; then insert remaining + new ones
        final existing = await AppDatabase.instance.getMediaForObservation(_observationId!);
        for (final m in existing) {
          await AppDatabase.instance.deleteMediaItem(m.id!);
        }

        final combined = [for (var m in _media) m.path] + _newMediaPaths;
        if (combined.isNotEmpty) {
          final mediaItems = combined.map((p) => MediaItem(observationId: _observationId!, path: p, type: 'image')).toList();
          await AppDatabase.instance.insertMediaItems(mediaItems);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Observation saved')));
      Navigator.of(context).pop(true); // signal calling screens to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save observation')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xfff5f5f5),
        automaticallyImplyLeading: true,
        title: Text(
          _observationId == null ? 'New Observation' : 'Edit Observation',
          style: const TextStyle(
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

            // Caption
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Caption', style: TextStyle(fontSize: 14, color: Color(0xff6b7280), fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(controller: _captionCtrl, decoration: InputDecoration(hintText: 'A brief title for your observation', filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffd1d5db))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xff2d572c))))),
              ],
            ),

            const SizedBox(height: 24),

            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Content', style: TextStyle(fontSize: 14, color: Color(0xff6b7280), fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(controller: _contentCtrl, maxLines: 6, decoration: InputDecoration(hintText: 'Describe what you saw, heard, or felt...', filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffd1d5db))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xff2d572c))))),
              ],
            ),

            const SizedBox(height: 32),

            const Text('Media', style: TextStyle(fontSize: 14, color: Color(0xff6b7280), fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),

            _buildMediaGrid(),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Submit
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              color: const Color(0xfff5f5f5),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2d572c),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
