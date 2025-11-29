import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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
  // Newly picked media: store map entries with path and type ('image'|'video')
  List<Map<String, String>> _newMedia = [];

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
    // Ensure permissions (camera/gallery) are granted before picking
    final ok = await _ensurePermissionsForMedia(forVideo: false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }

    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() {
      _newMedia.add({'path': file.path, 'type': 'image'});
    });
  }

  // Pick multiple images from gallery
  Future<void> _pickMultiImage() async {
    final ok = await _ensurePermissionsForMedia(forVideo: false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }

    final List<XFile>? files = await _picker.pickMultiImage(imageQuality: 80);
    if (files == null || files.isEmpty) return;
    setState(() {
      for (final f in files) {
        _newMedia.add({'path': f.path, 'type': 'image'});
      }
    });
  }

  Future<void> _pickVideo(ImageSource source) async {
    // Ensure camera/microphone/storage permissions
    final ok = await _ensurePermissionsForMedia(forVideo: true);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }

    final XFile? file = await _picker.pickVideo(source: source);
    if (file == null) return;
    setState(() {
      _newMedia.add({'path': file.path, 'type': 'video'});
    });
  }

  // Pick multiple videos from gallery using image_picker (one-by-one)
  Future<void> _pickMultipleVideos() async {
    // Many devices don't provide a native multiple-video picker via image_picker.
    // To avoid depending on the file_picker plugin (which caused build failures),
    // we let the user pick videos one-by-one from gallery until they cancel.
    final ok = await _ensurePermissionsForMedia(forVideo: true);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }

    bool keepPicking = true;
    while (keepPicking) {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null) break; // user cancelled
      setState(() {
        _newMedia.add({'path': file.path, 'type': 'video'});
      });

      // Ask user if they want to pick another
      final pickAnother = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add another video?'),
          content: const Text('Do you want to select another video from the gallery?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
          ],
        ),
      );
      if (pickAnother != true) keepPicking = false;
    }
  }

  // Request platform permissions required for camera/gallery/video recording
  Future<bool> _ensurePermissionsForMedia({required bool forVideo}) async {
    try {
      List<Permission> perms = [];
      if (Platform.isAndroid) {
        // On Android 13+ you should request READ_MEDIA_* permissions. Using
        // Permission.photos from permission_handler maps to READ_MEDIA_IMAGES
        // / READ_MEDIA_VIDEO as appropriate. This avoids relying on legacy
        // storage permissions which can be denied on newer OS versions.
        perms = [Permission.camera, Permission.photos];
        if (forVideo) perms.add(Permission.microphone);
      } else if (Platform.isIOS) {
        // On iOS request photos + camera; microphone for video
        perms = [Permission.photos, Permission.camera];
        if (forVideo) perms.add(Permission.microphone);
      } else {
        // Fallback: request camera if available
        perms = [Permission.camera];
        if (forVideo) perms.add(Permission.microphone);
      }

      final statuses = await perms.request();
      debugPrint('Requested permissions: ${perms.map((p) => p.toString()).toList()}');
      debugPrint('Permission statuses: ${statuses.map((k, v) => MapEntry(k.toString(), v.toString()))}');

      // If any permission is permanently denied, suggest opening app settings
      final permanentlyDenied = statuses.entries.where((e) => e.value.isPermanentlyDenied).toList();
      final denied = statuses.entries.where((e) => e.value.isDenied).toList();

      if (permanentlyDenied.isNotEmpty) {
        // Explain why and offer to open app settings
        if (!mounted) return false;
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permissions required'),
            content: const Text('Some permissions are permanently denied. Open app settings to enable camera or storage permissions?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Open settings')),
            ],
          ),
        );
        if (open == true) await openAppSettings();
        return false;
      }

      if (denied.isNotEmpty) {
        // User denied but not permanently; show a friendly message and return false
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions were denied. Please allow camera/gallery access.')));
        return false;
      }

      // Consider granted or limited as OK
      return statuses.values.every((s) => s.isGranted || s.isLimited);
    } catch (e) {
      // If permission handler fails, log and allow the picker to try (some platforms
      // will still show system pickers). Return false to be conservative.
      debugPrint('Permission check failed: $e');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to check permissions')));
      return false;
    }
  }

  Widget _buildMediaGrid() {
    final demoImages = <String>[]; // keep demo removed when real data present

    // Build combined list: existing MediaItem objects followed by new media maps
    final combined = <dynamic>[for (var m in _media) m] + _newMedia;

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
      children: combined.map((entry) {
        String path;
        String type;
        bool isNew = false;

        if (entry is MediaItem) {
          path = entry.path;
          type = entry.type;
          isNew = false;
        } else if (entry is Map<String, String>) {
          path = entry['path'] ?? '';
          type = entry['type'] ?? 'image';
          isNew = true;
        } else {
          // Skip unsupported entry types
          return const SizedBox.shrink();
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: type.toLowerCase() == 'image'
                    ? Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                    : // For video files show a simple placeholder with a play icon.
                    Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
                              const SizedBox(height: 6),
                              Text(
                                path.split('/').last,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isNew) {
                      _newMedia.removeWhere((m) => m['path'] == path);
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
    if (caption.isEmpty && content.isEmpty && _media.isEmpty && _newMedia.isEmpty) {
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
        if (_newMedia.isNotEmpty) {
          final mediaItems = _newMedia.map((m) => MediaItem(observationId: newId, path: m['path']!, type: m['type']!)).toList();
          await AppDatabase.instance.insertMediaItems(mediaItems);
        }
      } else {
        // Update existing observation
        final obs = Observation(id: _observationId, hikeId: _hikeId!, caption: caption, content: content, time: DateTime.now().toIso8601String());
        await AppDatabase.instance.updateObservation(obs);

        // Remove existing media rows for this observation; then insert remaining + new ones
        // Delete all existing rows then re-insert current + new ones
        final existing = await AppDatabase.instance.getMediaForObservation(_observationId!);
        for (final m in existing) {
          await AppDatabase.instance.deleteMediaItem(m.id!);
        }

        final List<MediaItem> toInsert = [];
        // remaining existing media (kept in _media)
        for (final m in _media) {
          toInsert.add(MediaItem(observationId: _observationId!, path: m.path, type: m.type));
        }
        // new media
        for (final nm in _newMedia) {
          toInsert.add(MediaItem(observationId: _observationId!, path: nm['path']!, type: nm['type']!));
        }

        if (toInsert.isNotEmpty) {
          await AppDatabase.instance.insertMediaItems(toInsert);
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
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_camera),
                                title: const Text('Take photo'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.videocam),
                                title: const Text('Record video'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _pickVideo(ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Pick images'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _pickMultiImage();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.video_library),
                                title: const Text('Pick videos'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _pickMultipleVideos();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Video controls: allow picking video from camera or gallery
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
