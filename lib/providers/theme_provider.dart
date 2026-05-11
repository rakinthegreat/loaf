import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';

enum DustyTheme {
  midnight,
  ocean,
}

class ThemeProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  DustyTheme _currentTheme = DustyTheme.midnight;

  DustyTheme get currentTheme => _currentTheme;

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    final savedTheme = await _storage.getTheme();
    if (savedTheme != null) {
      _currentTheme = savedTheme == 'ocean' ? DustyTheme.ocean : DustyTheme.midnight;
      notifyListeners();
    }
  }

  void toggleTheme() {
    _currentTheme = _currentTheme == DustyTheme.midnight ? DustyTheme.ocean : DustyTheme.midnight;
    _storage.saveTheme(_currentTheme == DustyTheme.ocean ? 'ocean' : 'midnight');
    notifyListeners();
  }

  ThemeData get themeData {
    final isMidnight = _currentTheme == DustyTheme.midnight;
    
    // Dichromatic colors focus: Blue and Yellow for feline eyes
    final primaryColor = isMidnight ? const Color(0xFF3F51B5) : const Color(0xFF009688); // Indigo / Teal
    final accentColor = const Color(0xFFFFD600); // Feline visible Yellow

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: isMidnight ? const Color(0xFF0D1117) : const Color(0xFF1E293B),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: isMidnight ? const Color(0xFF161B22) : const Color(0xFF334155),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    );
  }
}
