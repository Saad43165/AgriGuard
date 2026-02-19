import 'package:flutter/material.dart';
import '../../provider/weather_provider.dart';
import 'city_search_dialog.dart';

class WeatherCardDialogs {
  static void showSearchDialog(
      BuildContext context,
      WeatherProvider provider,
      Color weatherColor,
      ) {
    CitySearchDialog.show(context, provider, weatherColor);
  }
}