import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';

class DayDetailScreen extends StatelessWidget {
  final ForecastDay forecastDay;
  final Color weatherColor;

  const DayDetailScreen({
    super.key,
    required this.forecastDay,
    required this.weatherColor,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(forecastDay.date);
    final dayName = DateFormat('EEEE, MMMM d').format(date);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [weatherColor, weatherColor.withValues(alpha: 0.8)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x4D000000), Color(0x33000000)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x59FFFFFF), width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                title: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x4D000000), Color(0x33000000)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x59FFFFFF), width: 2),
                  ),
                  child: Text(
                    dayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMainWeatherCard(),
                    const SizedBox(height: 20),
                    _buildAstroCard(),
                    const SizedBox(height: 20),
                    _buildDetailedInfoGrid(),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _premiumDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getWeatherIcon(forecastDay.conditionText),
              size: 80,
              color: const Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            forecastDay.conditionText,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTempColumn('High', forecastDay.maxTemp, Icons.arrow_upward, const Color(0xFFFF6B6B)),
              Container(
                width: 2,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x80FFFFFF), Colors.transparent],
                  ),
                ),
              ),
              _buildTempColumn('Low', forecastDay.minTemp, Icons.arrow_downward, const Color(0xFF4ECDC4)),
              Container(
                width: 2,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x80FFFFFF), Colors.transparent],
                  ),
                ),
              ),
              _buildTempColumn('Avg', forecastDay.avgTemp, Icons.thermostat, const Color(0xFFFFA726)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempColumn(String label, double temp, IconData icon, Color accentColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor.withValues(alpha: 0.4), accentColor.withValues(alpha: 0.3)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x59FFFFFF), width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          '${temp.toStringAsFixed(0)}°',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xE6FFFFFF),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAstroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _premiumDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x4DFFFFFF), Color(0x33FFFFFF)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const Icon(Icons.wb_twilight_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sun & Moon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildAstroItem(Icons.wb_sunny_rounded, 'Sunrise', forecastDay.sunrise, const Color(0xFFFFA726))),
              const SizedBox(width: 12),
              Expanded(child: _buildAstroItem(Icons.wb_twilight, 'Sunset', forecastDay.sunset, const Color(0xFFFF7043))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildAstroItem(Icons.nightlight_round, 'Moonrise', forecastDay.moonrise, const Color(0xFF7E57C2))),
              const SizedBox(width: 12),
              Expanded(child: _buildAstroItem(Icons.brightness_3, 'Moonset', forecastDay.moonset, const Color(0xFF5C6BC0))),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x40FFFFFF), Color(0x26FFFFFF)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x59FFFFFF), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    forecastDay.moonPhase,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${forecastDay.moonIllumination}% Illuminated',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xE6FFFFFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAstroItem(IconData icon, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33FFFFFF), Color(0x1AFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x4DFFFFFF), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accentColor, accentColor]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xE6FFFFFF),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfoGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _premiumDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x4DFFFFFF), Color(0x33FFFFFF)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detailed Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.air_rounded, 'Max Wind', '${forecastDay.maxWind.toStringAsFixed(1)} km/h'),
          _buildDivider(),
          _buildInfoRow(Icons.water_drop, 'Precipitation', '${forecastDay.totalPrecip.toStringAsFixed(1)} mm'),
          _buildDivider(),
          _buildInfoRow(Icons.ac_unit, 'Snow', '${forecastDay.totalSnow.toStringAsFixed(1)} cm'),
          _buildDivider(),
          _buildInfoRow(Icons.visibility, 'Avg Visibility', '${forecastDay.avgVisibility.toStringAsFixed(1)} km'),
          _buildDivider(),
          _buildInfoRow(Icons.water_drop_outlined, 'Avg Humidity', '${forecastDay.avgHumidity}%'),
          _buildDivider(),
          _buildInfoRow(Icons.wb_sunny_rounded, 'UV Index', forecastDay.uvIndex.toStringAsFixed(1)),
          _buildDivider(),
          _buildInfoRow(Icons.umbrella, 'Chance of Rain', '${forecastDay.dailyChanceOfRain}%'),
          _buildDivider(),
          _buildInfoRow(Icons.ac_unit_rounded, 'Chance of Snow', '${forecastDay.dailyChanceOfSnow}%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x40FFFFFF), Color(0x26FFFFFF)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xF2FFFFFF),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x4DFFFFFF), Color(0x33FFFFFF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x59FFFFFF), width: 2),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0x40FFFFFF), height: 1, thickness: 1.5);
  }

  BoxDecoration _premiumDecoration() => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x4D000000), Color(0x33000000)],
    ),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: const Color(0x59FFFFFF), width: 2),
  );

  IconData _getWeatherIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('sunny') || c.contains('clear')) return Icons.wb_sunny_rounded;
    if (c.contains('cloudy') || c.contains('overcast')) return Icons.cloud_rounded;
    if (c.contains('rain') || c.contains('drizzle')) return Icons.water_drop_rounded;
    if (c.contains('storm') || c.contains('thunder')) return Icons.thunderstorm_rounded;
    if (c.contains('snow') || c.contains('sleet')) return Icons.ac_unit_rounded;
    if (c.contains('fog') || c.contains('mist')) return Icons.foggy;
    return Icons.wb_cloudy_rounded;
  }
}