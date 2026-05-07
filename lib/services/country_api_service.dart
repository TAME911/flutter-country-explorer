// lib/services/country_api_service.dart
//
// ALL HTTP communication with the RestCountries v3.1 API lives here.
// No HTTP imports exist in any screen or widget file.
//
// Requirements met (Section 4.3):
//   ✅ Located in lib/services/
//   ✅ Private _baseUrl, _timeout, _headers fields
//   ✅ _checkResponse() method throws ApiException for non-200
//   ✅ One method per endpoint: fetchAllCountries, searchByName, fetchByCode
//   ✅ All return typed Futures — no Future<dynamic>
//   ✅ Uri.https() used — no string concatenation
//   ✅ 10-second timeout on every request
//   ✅ Content-Type and Accept headers set
//
// Bonus: 5-minute in-memory cache with TTL check (Section 7)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/country.dart';
import 'api_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal cache helper
// ─────────────────────────────────────────────────────────────────────────────
class _CacheEntry<T> {
  final T data;
  final DateTime storedAt;

  _CacheEntry({required this.data, required this.storedAt});

  bool isValid(Duration ttl) =>
      DateTime.now().difference(storedAt) < ttl;
}

// ─────────────────────────────────────────────────────────────────────────────
// CountryApiService
// ─────────────────────────────────────────────────────────────────────────────
class CountryApiService {
  // Configuration ─────────────────────────────────────────────────────────────
  final String _baseUrl = 'restcountries.com';
  final Duration _timeout = const Duration(seconds: 10);
  final Duration _cacheTtl = const Duration(minutes: 5);

  final Map<String, String> _headers = const <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Cache ─────────────────────────────────────────────────────────────────────
  _CacheEntry<List<Country>>? _allCountriesCache;
  final Map<String, _CacheEntry<Country>> _detailCache =
      <String, _CacheEntry<Country>>{};

  // ── Public getter used by HomeScreen to show the "Cached" badge ────────────
  bool get allCountriesFromCache =>
      _allCountriesCache != null && _allCountriesCache!.isValid(_cacheTtl);

  // ── Private: validate HTTP response ────────────────────────────────────────
  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Server returned status ${response.statusCode}. '
            'Please try again later.',
      );
    }
  }

  // ── fetchAllCountries — GET /v3.1/all ──────────────────────────────────────
  // Returns a name-sorted list of all countries.
  // Cached for 5 minutes (Bonus requirement).
  Future<List<Country>> fetchAllCountries() async {
    // Serve from cache if still valid
    if (_allCountriesCache != null && _allCountriesCache!.isValid(_cacheTtl)) {
      return _allCountriesCache!.data;
    }

    final Uri uri = Uri.https(
      _baseUrl,
      '/v3.1/all',
      <String, String>{
        'fields':
            'name,flags,flag,region,subregion,capital,population,area,cca3',
      },
    );

    try {
      final http.Response response =
          await http.get(uri, headers: _headers).timeout(_timeout);

      _checkResponse(response);

      final List<dynamic> jsonList =
          jsonDecode(response.body) as List<dynamic>;

      final List<Country> countries = jsonList
          .map((dynamic item) =>
              Country.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort(
            (Country a, Country b) => a.commonName.compareTo(b.commonName));

      _allCountriesCache =
          _CacheEntry<List<Country>>(data: countries, storedAt: DateTime.now());

      return countries;
    } on SocketException {
      rethrow; // → "No internet connection"
    } on TimeoutException {
      rethrow; // → "Request timed out"
    } on ApiException {
      rethrow; // → HTTP status error
    } on FormatException {
      rethrow; // → Malformed JSON
    } catch (e) {
      rethrow; // → Generic catch-all
    }
  }

  // ── searchByName — GET /v3.1/name/{name} ───────────────────────────────────
  // Returns matching countries. Returns empty list on 404 (no matches found).
  Future<List<Country>> searchByName(String name) async {
    final Uri uri = Uri.https(_baseUrl, '/v3.1/name/$name');

    try {
      final http.Response response =
          await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 404) return <Country>[];

      _checkResponse(response);

      final List<dynamic> jsonList =
          jsonDecode(response.body) as List<dynamic>;

      return jsonList
          .map((dynamic item) =>
              Country.fromJson(item as Map<String, dynamic>))
          .toList();
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on ApiException {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // ── fetchByCode — GET /v3.1/alpha/{code} ───────────────────────────────────
  // Returns full details for one country by ISO alpha-3 code.
  // Each result is individually cached.
  Future<Country> fetchByCode(String code) async {
    final _CacheEntry<Country>? cached = _detailCache[code];
    if (cached != null && cached.isValid(_cacheTtl)) {
      return cached.data;
    }

    final Uri uri = Uri.https(_baseUrl, '/v3.1/alpha/$code');

    try {
      final http.Response response =
          await http.get(uri, headers: _headers).timeout(_timeout);

      _checkResponse(response);

      final List<dynamic> jsonList =
          jsonDecode(response.body) as List<dynamic>;

      if (jsonList.isEmpty) {
        throw ApiException(
          statusCode: 404,
          message: 'Country with code "$code" not found.',
        );
      }

      final Country country =
          Country.fromJson(jsonList.first as Map<String, dynamic>);

      _detailCache[code] =
          _CacheEntry<Country>(data: country, storedAt: DateTime.now());

      return country;
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on ApiException {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
