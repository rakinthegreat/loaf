import 'package:flutter/material.dart';
import '../models/cat_profile.dart';
import '../services/storage_service.dart';

class ProfileProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  List<CatProfile> _profiles = [];
  CatProfile? _activeProfile;

  List<CatProfile> get profiles => _profiles;
  CatProfile? get activeProfile => _activeProfile;

  ProfileProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _profiles = await _storage.loadProfiles();
    final activeId = await _storage.getActiveProfileId();
    if (activeId != null) {
      _activeProfile = _profiles.firstWhere((p) => p.id == activeId, orElse: () => _profiles.isNotEmpty ? _profiles.first : _profiles.first); // fallback
    } else if (_profiles.isNotEmpty) {
      _activeProfile = _profiles.first;
    }
    notifyListeners();
  }

  Future<void> addProfile(CatProfile profile) async {
    _profiles.add(profile);
    await _storage.saveProfiles(_profiles);
    if (_activeProfile == null) {
      setActiveProfile(profile);
    }
    notifyListeners();
  }

  Future<void> setActiveProfile(CatProfile profile) async {
    _activeProfile = profile;
    await _storage.setActiveProfileId(profile.id);
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _storage.saveProfiles(_profiles);
    if (_activeProfile?.id == id) {
      _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
      if (_activeProfile != null) {
        await _storage.setActiveProfileId(_activeProfile!.id);
      }
    }
    notifyListeners();
  }
}
