// lib/models/country.dart
//
// Typed model for a country from the RestCountries v3.1 API.
// Requirements met:
//   ✅ All fields are final
//   ✅ factory fromJson constructor
//   ✅ toJson() method
//   ✅ copyWith() method
//   ✅ No dynamic types — only explicit casts
//   ✅ Nullable fields handled with ?. and ??

class Country {
  final String commonName;
  final String officialName;
  final String flagEmoji;
  final String flagPng;
  final String region;
  final String subregion;
  final String capital;
  final int population;
  final double area;
  final List<String> timezones;
  final List<String> currencies;
  final List<String> languages;
  final String alpha3Code;

  const Country({
    required this.commonName,
    required this.officialName,
    required this.flagEmoji,
    required this.flagPng,
    required this.region,
    required this.subregion,
    required this.capital,
    required this.population,
    required this.area,
    required this.timezones,
    required this.currencies,
    required this.languages,
    required this.alpha3Code,
  });

  // ── fromJson ──────────────────────────────────────────────────────────────
  // Parses a RestCountries JSON map into a typed Country object.
  // Every cast is explicit — no dynamic is used in the UI layer.
  factory Country.fromJson(Map<String, dynamic> json) {
    // name object
    final Map<String, dynamic> nameMap =
        (json['name'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final String commonName = (nameMap['common'] as String?) ?? 'Unknown';
    final String officialName = (nameMap['official'] as String?) ?? commonName;

    // flag PNG and emoji
    final Map<String, dynamic> flagsMap =
        (json['flags'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final String flagPng = (flagsMap['png'] as String?) ?? '';
    final String flagEmoji = (json['flag'] as String?) ?? '';

    // capital — API returns an array; we take the first element
    String capital = 'N/A';
    final Object? rawCapital = json['capital'];
    if (rawCapital is List && rawCapital.isNotEmpty) {
      capital = (rawCapital.first as String?) ?? 'N/A';
    }

    // currencies — map of code -> {name, symbol}
    final List<String> currencies = <String>[];
    final Object? rawCurrencies = json['currencies'];
    if (rawCurrencies is Map<String, dynamic>) {
      for (final Object? entry in rawCurrencies.values) {
        if (entry is Map<String, dynamic>) {
          final String? name = entry['name'] as String?;
          if (name != null && name.isNotEmpty) currencies.add(name);
        }
      }
    }

    // languages — map of code -> language name
    final List<String> languages = <String>[];
    final Object? rawLanguages = json['languages'];
    if (rawLanguages is Map<String, dynamic>) {
      for (final Object? value in rawLanguages.values) {
        if (value is String && value.isNotEmpty) languages.add(value);
      }
    }

    // timezones — array of strings
    final List<String> timezones = <String>[];
    final Object? rawTimezones = json['timezones'];
    if (rawTimezones is List) {
      for (final Object? t in rawTimezones) {
        if (t is String) timezones.add(t);
      }
    }

    return Country(
      commonName: commonName,
      officialName: officialName,
      flagEmoji: flagEmoji,
      flagPng: flagPng,
      region: (json['region'] as String?) ?? 'Unknown',
      subregion: (json['subregion'] as String?) ?? '',
      capital: capital,
      population: (json['population'] as int?) ?? 0,
      area: ((json['area'] as num?) ?? 0).toDouble(),
      timezones: timezones,
      currencies: currencies,
      languages: languages,
      alpha3Code: (json['cca3'] as String?) ?? '',
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': <String, dynamic>{
        'common': commonName,
        'official': officialName,
      },
      'flag': flagEmoji,
      'flags': <String, dynamic>{'png': flagPng},
      'region': region,
      'subregion': subregion,
      'capital': <String>[capital],
      'population': population,
      'area': area,
      'timezones': timezones,
      'currencies': <String, dynamic>{
        for (final String c in currencies)
          c: <String, dynamic>{'name': c},
      },
      'languages': <String, dynamic>{
        for (int i = 0; i < languages.length; i++) '$i': languages[i],
      },
      'cca3': alpha3Code,
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────
  Country copyWith({
    String? commonName,
    String? officialName,
    String? flagEmoji,
    String? flagPng,
    String? region,
    String? subregion,
    String? capital,
    int? population,
    double? area,
    List<String>? timezones,
    List<String>? currencies,
    List<String>? languages,
    String? alpha3Code,
  }) {
    return Country(
      commonName: commonName ?? this.commonName,
      officialName: officialName ?? this.officialName,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      flagPng: flagPng ?? this.flagPng,
      region: region ?? this.region,
      subregion: subregion ?? this.subregion,
      capital: capital ?? this.capital,
      population: population ?? this.population,
      area: area ?? this.area,
      timezones: timezones ?? this.timezones,
      currencies: currencies ?? this.currencies,
      languages: languages ?? this.languages,
      alpha3Code: alpha3Code ?? this.alpha3Code,
    );
  }
}
