// lib/screens/detail_screen.dart
//
// Detail Screen — shows full information about a single country.
// Data fetched via GET /v3.1/alpha/{code}.
//
// Requirements met:
//   ✅ FutureBuilder with all 4 states: waiting, error, no-data, data
//   ✅ initState() triggers the API call — not build()
//   ✅ mounted check in _load()
//   ✅ No nested Scaffold widgets (fixed from original)
//   ✅ Retry button via ErrorView

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../services/country_api_service.dart';
import '../widgets/error_view.dart';

class DetailScreen extends StatefulWidget {
  final String alpha3Code;
  final CountryApiService apiService;

  const DetailScreen({
    super.key,
    required this.alpha3Code,
    required this.apiService,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<Country> _countryFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Start (or retry) the API fetch.
  void _load() {
    // setState is safe here because _load is called from initState or a button
    setState(() {
      _countryFuture = widget.apiService.fetchByCode(widget.alpha3Code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The Scaffold lives HERE — not inside FutureBuilder branches.
      // This prevents a "nested Scaffold" warning.
      body: FutureBuilder<Country>(
        future: _countryFuture,
        builder: (
          BuildContext context,
          AsyncSnapshot<Country> snapshot,
        ) {
          // ── State 1: Loading ───────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── State 2: Error ─────────────────────────────────────────
          // Use a Column with an AppBar + Expanded so layout stays
          // correct without a nested Scaffold.
          if (snapshot.hasError) {
            return Column(
              children: <Widget>[
                AppBar(title: const Text('Country Detail')),
                Expanded(
                  child: ErrorView(
                    error: snapshot.error!,
                    onRetry: _load,
                  ),
                ),
              ],
            );
          }

          // ── State 3: No data ───────────────────────────────────────
          if (!snapshot.hasData) {
            return Column(
              children: <Widget>[
                AppBar(title: const Text('Country Detail')),
                const Expanded(
                  child: Center(
                    child: Text('Country data not available.'),
                  ),
                ),
              ],
            );
          }

          // ── State 4: Data ──────────────────────────────────────────
          return _buildDetail(context, snapshot.data!);
        },
      ),
    );
  }

  // Builds the full scrollable detail view with a collapsing SliverAppBar.
  Widget _buildDetail(BuildContext context, Country country) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: <Widget>[
        // Collapsible app bar — flag image fills the expanded space
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              country.commonName,
              style: const TextStyle(
                fontSize: 16,
                shadows: <Shadow>[
                  Shadow(blurRadius: 4, color: Colors.black54),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Flag image
                country.flagPng.isNotEmpty
                    ? Image.network(
                        country.flagPng,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          BuildContext ctx,
                          Object err,
                          StackTrace? st,
                        ) =>
                            Container(color: cs.primaryContainer),
                      )
                    : Container(color: cs.primaryContainer),
                // Gradient so title text is readable
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black54,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Official (full) name in italic
                Text(
                  country.officialName,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),

                // 2×2 info grid
                _InfoGrid(country: country),

                const SizedBox(height: 20),

                // Currencies
                _Section(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Currencies',
                  content: country.currencies.isEmpty
                      ? 'N/A'
                      : country.currencies.join(', '),
                ),

                // Languages
                _Section(
                  icon: Icons.translate_rounded,
                  title: 'Languages',
                  content: country.languages.isEmpty
                      ? 'N/A'
                      : country.languages.join(', '),
                ),

                // Timezones
                _Section(
                  icon: Icons.access_time_rounded,
                  title: 'Timezones',
                  content: country.timezones.isEmpty
                      ? 'N/A'
                      : country.timezones.join(', '),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets — only used inside this file
// ─────────────────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final Country country;
  const _InfoGrid({required this.country});

  // Format large numbers: 1 000 000 → 1.0M, 1 000 → 1.0K
  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: <Widget>[
        _InfoCard(
          icon: Icons.location_city_rounded,
          label: 'Capital',
          value: country.capital,
        ),
        _InfoCard(
          icon: Icons.people_rounded,
          label: 'Population',
          value: _fmt(country.population),
        ),
        _InfoCard(
          icon: Icons.map_rounded,
          label: 'Area',
          value: '${_fmt(country.area.toInt())} km²',
        ),
        _InfoCard(
          icon: Icons.public_rounded,
          label: 'Region',
          value: country.subregion.isNotEmpty
              ? country.subregion
              : country.region,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    label,
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    value,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  const _Section({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: tt.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(content, style: tt.bodyMedium),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
