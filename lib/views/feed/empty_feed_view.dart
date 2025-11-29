// lib/views/feed/empty_feed_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/hike_viewmodel.dart';
import '../hikes/hike_form_view.dart';

class EmptyFeedView extends StatefulWidget {
  /// When [embedded] is true the widget renders only the empty-state
  /// content (no Scaffold, no header). This is useful when the view is
  /// embedded inside another page that already renders the app bar.
  final bool embedded;
  const EmptyFeedView({super.key, this.embedded = false});

  @override
  State<EmptyFeedView> createState() => _EmptyFeedViewState();
}

class _EmptyFeedViewState extends State<EmptyFeedView> {
  Future<void> _refreshData() async {
    final viewModel = Provider.of<HikeViewModel>(context, listen: false);
    await viewModel.loadFeed();
    await viewModel.loadRemarkable();
  }

  Future<void> _openHikeForm() async {
    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (ctx) => const HikeFormView()),
    );

    if (result == true) {
      final viewModel = Provider.of<HikeViewModel>(context, listen: false);
      await viewModel.loadFeed();
      await viewModel.loadRemarkable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build the inner empty-state widget (no scaffold/wrapper). When
    // embedded == true we return this directly to avoid duplicating the
    // FeedView's SafeArea/AppBar. When embedded == false we wrap it in a
    // Scaffold that provides a minimal AppBar (logo + title) for standalone use.
    final Widget inner = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            // Note: the AppBar is provided by the Scaffold below when not
            // embedded. This keeps the inner content free of headers so it
            // can be embedded without duplication.

            const SizedBox(height: 40),

            // EMPTY STATE CONTENT with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                color: colorScheme.primary,
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery
                          .of(context)
                          .size
                          .height - 200,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ILLUSTRATION IMAGE
                          SizedBox(
                            height: 240,
                            width: 240,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                "https://lh3.googleusercontent.com/aida-public/AB6AXuC8Cpp1dGMKyQG12tmVi-BWG_KS6jDfv_EI4aFnDW8hpeJxLrR5JAur5LW0zfGzgCPOrvJsljL9j42_PShKrMpGq42g94KqwA2DUms5WUJmeqpF-mvLwXdFTdWY48IHoawxszAkj4jzEQOeHng8-jIMlta-0TMol11NhAad4GUMcCtanBe75s8LUKMdQDsHPSiFNIBapa_MKc_o03eiXXQW1LnWbTaVJlOpqaI4dh-ect3leEOYzmOKR5RRz4RCTYTDSl-xu4T0YBH-",
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // TITLE + DESCRIPTION
                          Text(
                            "Your Adventure Awaits",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Looks like you haven't completed a hike yet. Every great journey starts with a single step.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14),
                          ),

                          const SizedBox(height: 32),

                          // BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _openHikeForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 6,
                                shadowColor: colorScheme.primary.withOpacity(
                                    0.3),
                              ),
                              child: Text(
                                "Start Your First Hike",
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colorScheme.onPrimary),
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
          ],
        ),
      ),
    );

    // When embedded, return the inner content directly. When standalone,
    // provide a minimal AppBar (logo + centered title) and place the
    // inner content inside the Scaffold body.
    if (widget.embedded) return inner;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Image.asset('lib/assets/images/hike_logo.png', width: 32,
              height: 32,
              fit: BoxFit.contain),
        ),
        title: Text('Hike Feed', style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(child: inner),
    );
  }
}

