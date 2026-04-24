import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/widgets/app_themes.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/translation_service.dart';
import '../weather/provider/weather_provider.dart';

class HomeHeader extends StatelessWidget {
  final bool isDark;
  const HomeHeader({super.key, required this.isDark});

  Stream<Map<String, String>> _userStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value({'name': 'User'});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((d) => {
              'name': d.exists ? ((d.data() as Map)['fullName'] ?? 'User') : 'User',
            });
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Column(
      children: [
        // ── Top bar: weather left, settings right ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              // Weather inline
              Expanded(child: Consumer<WeatherProvider>(
                builder: (_, provider, __) {
                  if (provider.hasData) {
                    final w = provider.currentWeather!;
                    final icon = _weatherEmoji(w.conditionText, w.isDay == 1);
                    return Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${w.temperature.toStringAsFixed(0)}°C  ${w.conditionText}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(CupertinoIcons.location_fill,
                                    size: 10, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  w.cityName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  if (provider.isLoading) {
                    return Row(children: [
                      const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Text(t.isUrdu ? 'موسم لوڈ ہو رہا ہے…' : 'Loading weather…',
                          style: TextStyle(fontSize: 12, color: captionColor)),
                    ]);
                  }
                  return Row(children: [
                    Icon(CupertinoIcons.cloud, size: 18, color: captionColor),
                    const SizedBox(width: 6),
                    Text(t.isUrdu ? 'موسم دستیاب نہیں' : 'Weather unavailable',
                        style: TextStyle(fontSize: 12, color: captionColor)),
                  ]);
                },
              )),
              // Settings button
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Icon(CupertinoIcons.settings,
                      size: 17,
                      color: isDark ? AppColors.darkCaption : AppColors.lightCaption),
                ),
              ),
              const SizedBox(width: 8),
              // Report Bug button
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.bugReport),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Icon(CupertinoIcons.ant,
                      size: 17,
                      color: isDark ? AppColors.darkCaption : AppColors.lightCaption),
                ),
              ),
            ],
          ),
        ),

        // ── Greeting ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: StreamBuilder<Map<String, String>>(
            stream: _userStream(),
            builder: (context, snap) {
              final firstName = (snap.data?['name'] ?? 'User').split(' ').first;
              final h = DateTime.now().hour;
              final greeting = h < 12 ? t.get('good_morning') : h < 17 ? t.get('good_afternoon') : t.get('good_evening');
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      '$greeting, $firstName 👋',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _weatherEmoji(String condition, bool isDay) {
    final c = condition.toLowerCase();
    if (c.contains('sunny') || c.contains('clear')) return isDay ? '☀️' : '🌙';
    if (c.contains('partly') || c.contains('cloudy')) return isDay ? '⛅' : '🌤️';
    if (c.contains('overcast')) return '☁️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('thunder') || c.contains('storm')) return '⛈️';
    if (c.contains('snow') || c.contains('sleet')) return '❄️';
    if (c.contains('fog') || c.contains('mist')) return '🌫️';
    return isDay ? '🌤️' : '🌙';
  }
}
