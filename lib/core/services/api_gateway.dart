import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Single place that decides how the app talks to Groq, Plant.id and
/// WeatherAPI.
///
/// * **Proxy mode** (recommended for release): set `API_PROXY_URL` in `.env`
///   to the Cloud Functions base URL (see `functions/README.md`). The app then
///   sends only the signed-in user's Firebase ID token; the real API keys live
///   on the server and never ship inside the APK.
/// * **Direct mode** (development fallback): no proxy URL, keys come from
///   `.env` as before.
class ApiGateway {
  ApiGateway._();

  static String get _proxy =>
      (dotenv.env['API_PROXY_URL'] ?? '').trim().replaceAll(RegExp(r'/+$'), '');

  static bool get useProxy => _proxy.isNotEmpty;

  static String? _env(String key) {
    final v = dotenv.env[key]?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<String> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please sign in to use online AI features.');
    }
    final token = await user.getIdToken();
    if (token == null) throw Exception('Could not get a sign-in token.');
    return token;
  }

  // ── Groq ────────────────────────────────────────────────────────────────
  /// True when Groq can be used (proxy configured, or a local key present).
  static bool get groqAvailable => useProxy || _env('GROQ_API_KEY') != null;

  static String get groqUrl => useProxy
      ? '$_proxy/groq'
      : 'https://api.groq.com/openai/v1/chat/completions';

  /// Value for the `Authorization` header.
  static Future<String> groqAuth() async {
    if (useProxy) return 'Bearer ${await _idToken()}';
    final key = _env('GROQ_API_KEY');
    if (key == null) {
      throw Exception('Missing GROQ_API_KEY. Add it to your .env file.');
    }
    return 'Bearer $key';
  }

  // ── Plant.id ────────────────────────────────────────────────────────────
  static bool get plantIdAvailable => useProxy || _env('PLANTID_API_KEY') != null;

  static String get plantIdBaseUrl =>
      useProxy ? '$_proxy/plantid' : 'https://api.plant.id/v3';

  static Future<Map<String, String>> plantIdHeaders() async {
    if (useProxy) return {'Authorization': 'Bearer ${await _idToken()}'};
    final key = _env('PLANTID_API_KEY');
    if (key == null) {
      throw Exception('Missing PLANTID_API_KEY. Add it to your .env file.');
    }
    return {'Api-Key': key};
  }

  // ── WeatherAPI ──────────────────────────────────────────────────────────
  static String get weatherBaseUrl =>
      useProxy ? '$_proxy/weather' : 'https://api.weatherapi.com/v1';

  /// Extra query parameters for weather requests (the key, in direct mode).
  static Map<String, String> get weatherQuery {
    if (useProxy) return const {};
    final key = _env('WEATHER_API_KEY');
    return key == null ? const {} : {'key': key};
  }

  static Future<Map<String, String>> weatherHeaders() async =>
      useProxy ? {'Authorization': 'Bearer ${await _idToken()}'} : const {};
}
