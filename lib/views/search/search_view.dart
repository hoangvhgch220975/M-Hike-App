import 'dart:async';

import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../models/hike.dart';
import '../feed/feed_view.dart';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
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

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {
      _query = '';
      _results = [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // light-grey
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
              hintText: 'Search for hikes...',
              hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: const BorderSide(color: Color(0xFF225749), width: 2),
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: _clear,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                    )
                  : null,
            ),
            onSubmitted: (v) => _onChanged(v),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Prefer popping back to previous screen (likely Feed). If not possible, replace with FeedView.
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedView()),
                );
              }
            },
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF225749), fontWeight: FontWeight.w600)),
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
          onTap: () {
            // TODO: navigate to hike detail view
          },
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final s = suggestions[index];
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
          leading: const Icon(Icons.history, color: Color(0xFF6B7280)),
          onTap: () {
            _controller.text = s;
            _onChanged(s);
          },
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: suggestions.length,
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 4))],
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
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    park,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        distance,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text("•", style: TextStyle(color: Color(0xFFCCCCCC))),
                      ),
                      Text(
                        difficulty,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
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
