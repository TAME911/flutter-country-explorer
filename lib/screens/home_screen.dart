// lib/screens/home_screen.dart
//
// Home Screen — displays a paginated, scrollable list of ALL countries.
//
// Requirements met:
//   ✅ FutureBuilder with all 4 states: waiting, error, no-data, data
//   ✅ No async calls inside build()
//   ✅ mounted check after every await
//   ✅ Retry button wired to _loadCountries()
//   ✅ Pull-to-refresh with RefreshIndicator
//
// Bonus:
//   ✅ Pagination — 20 countries per page, "Load More" button
//   ✅ "Cached" badge — shown when data is served from the 5-min cache

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../services/country_api_service.dart';
import '../widgets/country_tile.dart';
import '../widgets/error_view.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CountryApiService _apiService = CountryApiService();

  // The future that powers FutureBuilder — never called inside build()
  late Future<List<Country>> _countriesFuture;

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 1;
  List<Country> _allCountries = <Country>[];
  bool _isLoadingMore = false;

  // Cache indicator shown in AppBar
  bool _fromCache = false;

  // Flag: has the post-frame callback already populated _allCountries?
  bool _listPopulated = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  // Start (or restart) a fresh API fetch.
  // Called from initState() and from the Retry button.
  void _loadCountries() {
    setState(() {
      _currentPage = 1;
      _allCountries = <Country>[];
      _fromCache = false;
      _listPopulated = false;
      _countriesFuture = _apiService.fetchAllCountries();
    });
  }

  // The slice of countries currently visible (up to current page).
  List<Country> get _visibleCountries =>
      _allCountries.take(_currentPage * _pageSize).toList();

  // Reveal the next page.
  // RestCountries has no server-side pagination, so we slice the cached list.
  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    // Short artificial delay so the spinner is visible
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _currentPage++;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 Country Explorer'),
        centerTitle: false,
        actions: <Widget>[
          // "Cached" chip — visible when data comes from in-memory cache
          if (_fromCache)
            const Padding(
              padding: EdgeInsets.only(right: 4.0),
              child: Chip(
                label: Text('Cached'),
                avatar: Icon(Icons.cached_rounded, size: 16),
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
              ),
            ),
          // Navigate to Search screen
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search countries',
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SearchScreen(apiService: _apiService),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Country>>(
        future: _countriesFuture,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<Country>> snapshot,
        ) {
          // ── State 1: Loading ─────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── State 2: Error ───────────────────────────────────────────
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: _loadCountries,
            );
          }

          // ── State 3: No data ─────────────────────────────────────────
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No countries found.'));
          }

          // ── State 4: Data ────────────────────────────────────────────
          // Populate _allCountries once via a post-frame callback.
          // We MUST NOT call setState() directly inside build().
          if (!_listPopulated) {
            _listPopulated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _allCountries = snapshot.data!;
                  _fromCache = _apiService.allCountriesFromCache;
                });
              }
            });
          }

          final List<Country> visible = _visibleCountries;
          final bool hasMore = visible.length < _allCountries.length;

          return RefreshIndicator(
            onRefresh: () async => _loadCountries(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: visible.length + (hasMore ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                // Last item = "Load More" button or spinner
                if (index == visible.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: _isLoadingMore
                          ? const CircularProgressIndicator()
                          : FilledButton.tonalIcon(
                              onPressed: _loadMore,
                              icon: const Icon(
                                  Icons.expand_more_rounded),
                              label: Text(
                                'Load More  '
                                '(${_allCountries.length - visible.length} remaining)',
                              ),
                            ),
                    ),
                  );
                }

                final Country country = visible[index];
                return CountryTile(
                  country: country,
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => DetailScreen(
                          alpha3Code: country.alpha3Code,
                          apiService: _apiService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
