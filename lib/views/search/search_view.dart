import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../db/app_db.dart';
import '../../models/hike.dart';
import '../hikes/hike_detail_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  List<Hike> _results = [];
  String _query = '';

  // Recent searches (most recent first)
  List<String> _recent = [];
  static const String _prefsKey = 'recent_searches';
  static const int _maxRecent = 3;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    if (!mounted) return;
    setState(() => _recent = list);
  }

  Future<void> _saveSearch(String q) async {
    final value = q.trim();
    if (value.isEmpty) return;
    // Move to front, remove duplicates
    _recent.removeWhere((r) => r.toLowerCase() == value.toLowerCase());
    _recent.insert(0, value);
    if (_recent.length > _maxRecent) _recent = _recent.sublist(0, _maxRecent);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _recent);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _removeRecent(String value) async {
    _recent.removeWhere((r) => r == value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _recent);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _clearRecent() async {
    _recent.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (!mounted) return;
    setState(() {});
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _query = value.trim();
    if (_query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final items = await AppDatabase.instance.searchHikes(_query);
        if (!mounted) return;
        setState(() {
          _results = items;
          _isSearching = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    });
  }

  void _onSubmitted(String v) {
    final value = v.trim();
    if (value.isEmpty) return;
    _saveSearch(value);
    _onChanged(value);
    FocusScope.of(context).unfocus();
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {
      _query = '';
      _results = [];
      _isSearching = false;
    });
  }

  void _onResultTap(Hike hike) async {
    // Navigate to the hike detail page. The detail view may return `true` to
    // indicate the item was deleted/changed, in which case we refresh results.
    if (hike.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open hike (missing id)')));
      return;
    }

    _saveSearch(hike.name);

    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (_) => HikeDetailView(hikeId: hike.id!)),
    );

    // If the detail view indicates a change (e.g., deletion), refresh current results
    if (result == true) {
      if (_query.isNotEmpty) {
        _onChanged(_query);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hike updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: SizedBox(
          height: 44,
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
              hintText: 'Search for hikes...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, color: theme.hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: colorScheme.primary, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: _clear,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(color: theme.cardColor, shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 16, color: theme.iconTheme.color),
                      ),
                    )
                  : null,
            ),
            onSubmitted: _onSubmitted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Simply pop back to previous screen with navbar
              Navigator.pop(context);
            },
            child: Text('Cancel', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return _buildSuggestions();
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return _buildEmptyResults();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final hike = _results[index];
        return HikeItem(
          title: hike.name,
          park: hike.location,
          distance: '${hike.length.toStringAsFixed(1)} km',
          difficulty: hike.difficulty,
          imageUrl: 'lib/assets/images/imageholder.png', // placeholder; replace if hike has image
          onTap: () => _onResultTap(hike),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _results.length,
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            const Text('No hikes found', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
            const SizedBox(height: 12),
            const Text(
              'Try a different keyword or check your hikes list.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    // Simple static suggestions — you can replace these with recent searches or top hikes
    final suggestions = ['Lakeview', 'Emerald', 'Lakeside', 'Skyline'];

    // Build a combined list: recent searches first (if any), then static suggestions
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: _clearRecent,
                child: Text('Clear', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
              )
            ],
          ),
          const SizedBox(height: 8),
          ..._recent.map((s) {
            return Column(
              children: [
                ListTile(
                  tileColor: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(s, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  leading: Icon(Icons.history, color: theme.iconTheme.color),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 20, color: theme.iconTheme.color),
                    onPressed: () => _removeRecent(s),
                  ),
                  onTap: () {
                    _controller.text = s;
                    _saveSearch(s);
                    _onChanged(s);
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
          const Divider(),
        ],

        const SizedBox(height: 8),
        const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        ...suggestions.map((s) {
          return Column(
            children: [
              ListTile(
                tileColor: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(s, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                leading: Icon(Icons.trending_up, color: theme.iconTheme.color),
                onTap: () {
                  _controller.text = s;
                  _saveSearch(s);
                  _onChanged(s);
                },
              ),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }
}

class HikeItem extends StatelessWidget {
  final String title;
  final String park;
  final String distance;
  final String difficulty;
  final String imageUrl;
  final VoidCallback? onTap;

  const HikeItem({
    super.key,
    required this.title,
    required this.park,
    required this.distance,
    required this.difficulty,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, 4))],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: imageUrl.startsWith('http') ? NetworkImage(imageUrl) : AssetImage(imageUrl) as ImageProvider,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    park,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(distance, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text("•", style: TextStyle(color: Color(0xFFCCCCCC))),
                      ),
                      Text(difficulty, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
