import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat_profile.dart';

class StorageService {
  static const String _profilesKey = 'cat_profiles';
  static const String _activeProfileIdKey = 'active_profile_id';
  static const String _themeKey = 'dusty_theme';

  Future<void> saveProfiles(List<CatProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_profilesKey, encoded);
  }

  Future<List<CatProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_profilesKey);
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((item) => CatProfile.fromJson(item)).toList();
  }

  Future<void> setActiveProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProfileIdKey, id);
  }

  Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProfileIdKey);
  }

  Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }

  Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }
}
