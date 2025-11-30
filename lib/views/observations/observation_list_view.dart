import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../models/observation.dart';
import 'observation_item.dart';
import 'observation_detail_view.dart';

class ObservationListView extends StatefulWidget {
  final int hikeId;
  const ObservationListView({super.key, required this.hikeId});

  @override
  State<ObservationListView> createState() => _ObservationListViewState();
}

class _ObservationListViewState extends State<ObservationListView> {
  bool _isLoading = true;
  List<Observation> _observations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await AppDatabase.instance.getObservationsByHike(widget.hikeId);
      if (!mounted) return;
      setState(() {
        _observations = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: true,
        title: Text(
          'All Observations',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ) ?? const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
              ? Center(
                  child: Text(
                    'Failed to load observations',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final obs = _observations[index];
                      // Make each item navigable. If the detail view returns
                      // `true` (indicating a change like edit/delete), pop true
                      // from this list so upstream callers can react (e.g. reload hike).
                      return ObservationItem(
                        observation: obs,
                        onTap: () async {
                          if (obs.id == null) return;
                          final result = await Navigator.of(context).push<bool?>(
                            MaterialPageRoute(builder: (_) => ObservationDetailView(observationId: obs.id!)),
                          );
                          if (result == true) {
                            // Propagate change to whoever opened this list
                            if (context.mounted) Navigator.of(context).pop(true);
                          }
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _observations.length,
                  ),
                )),
    );
  }
}
