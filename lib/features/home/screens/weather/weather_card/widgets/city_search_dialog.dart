import 'package:flutter/material.dart';
import '../../provider/weather_provider.dart';

class CitySearchDialog {
  static void show(
    BuildContext context,
    WeatherProvider provider,
    Color weatherColor,
  ) {
    showDialog(
      context: context,
      builder: (context) => _CitySearchDialogWidget(
        provider: provider,
        weatherColor: weatherColor,
      ),
    );
  }
}

class _CitySearchDialogWidget extends StatefulWidget {
  final WeatherProvider provider;
  final Color weatherColor;

  const _CitySearchDialogWidget({
    required this.provider,
    required this.weatherColor,
  });

  @override
  State<_CitySearchDialogWidget> createState() =>
      _CitySearchDialogWidgetState();
}

class _CitySearchDialogWidgetState extends State<_CitySearchDialogWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search City',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter city name...',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _searchController.text.isEmpty
                      ? null
                      : () {
                          widget.provider
                              .loadWeatherForCity(_searchController.text);
                          Navigator.of(context).pop();
                        },
                  child: const Text('Search'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
