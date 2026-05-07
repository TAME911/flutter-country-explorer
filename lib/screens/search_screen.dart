// lib/screens/search_screen.dart
//
// Search Screen — fetches countries by name via GET /v3.1/name/{name}.
//
// Requirements met:
//   ✅ FutureBuilder with all 4 states: waiting, error, no-data, data
//   ✅ No async calls inside build()
//   ✅ mounted check inside Timer callback
//   ✅ Error handled with ErrorView + Retry
//
// Bonus:
//   ✅ 400 ms debounce — API called only after user stops typing
//   ✅ Spinner shown during the debounce window

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../services/country_api_service.dart';
import '../widgets/country_tile.dart';
import '../widgets/error_view.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final CountryApiService apiService;

  const SearchScreen({super.key, required this.apiService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  // Debounce timer — cancelled and reset on each keystroke
  Timer? _debounceTimer;

  // Drives the FutureBuilder
  Future<List<Country>>? _searchFuture;

  // True while inside the 400 ms debounce window
  bool _isDebouncing = false;

  // Last query sent to the API (used by Retry)
  String _lastQuery = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Called on every keystroke — resets the 400 ms timer.
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    final String trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchFuture = null;
        _isDebouncing = false;
        _lastQuery = '';
      });
      return;
    }

    // Show spinner for the debounce window
    setState(() => _isDebouncing = true);

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      // Always check mounted before calling setState after async gap
      if (!mounted) return;
      setState(() {
        _isDebouncing = false;
        _lastQuery = trimmed;
        _searchFuture = widget.apiService.searchByName(trimmed);
      });
    });
  }

  // Retry the last search after an error.
  void _retry() {
    if (_lastQuery.isNotEmpty) {
      setState(() {
        _searchFuture = widget.apiService.searchByName(_lastQuery);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search countries…',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ),
          onChanged: _onSearchChanged,
        ),
        actions: <Widget>[
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── No query typed yet ───────────────────────────────────────────────────
    if (_controller.text.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.travel_explore_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Type a country name to search',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ── Inside debounce window ───────────────────────────────────────────────
    if (_isDebouncing) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── No future yet (edge case) ────────────────────────────────────────────
    if (_searchFuture == null) return const SizedBox.shrink();

    // ── FutureBuilder ────────────────────────────────────────────────────────
    return FutureBuilder<List<Country>>(
      future: _searchFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<Country>> snapshot,
      ) {
        // State 1: Waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // State 2: Error
        if (snapshot.hasError) {
          return ErrorView(error: snapshot.error!, onRetry: _retry);
        }

        // State 3: No data / empty
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.search_off_rounded,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No countries found for "$_lastQuery"',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // State 4: Data
        final List<Country> countries = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: countries.length,
          itemBuilder: (BuildContext context, int index) {
            final Country country = countries[index];
            return CountryTile(
              country: country,
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DetailScreen(
                      alpha3Code: country.alpha3Code,
                      apiService: widget.apiService,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
