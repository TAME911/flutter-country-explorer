// lib/widgets/country_tile.dart
//
// Reusable list tile — shows flag image, country name, region, and capital.
// Used in both HomeScreen and SearchScreen.

import 'package:flutter/material.dart';

import '../models/country.dart';

class CountryTile extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;

  const CountryTile({
    super.key,
    required this.country,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              // Flag image with error fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: country.flagPng.isNotEmpty
                    ? Image.network(
                        country.flagPng,
                        width: 56,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) =>
                            _flagFallback(),
                      )
                    : _flagFallback(),
              ),
              const SizedBox(width: 14),

              // Country name + region
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      country.commonName,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      country.region,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // Capital + arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    country.capital,
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flagFallback() {
    return Container(
      width: 56,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Text('🏳', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}
