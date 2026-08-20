import 'package:flutter/material.dart';

class LocaleService extends ChangeNotifier {
  // On force la langue sur le français directement
  final Locale _currentLocale = const Locale('fr');

  Locale get currentLocale => _currentLocale;

  static const Map<String, String> supportedLanguages = {
    'fr': 'Français',
  };

  Future<void> loadSavedLocale() async {
    // Plus besoin de charger SharedPreferences, la langue est fixée sur 'fr'
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    // Ne fait rien pour empêcher le changement de langue
    notifyListeners();
  }

  String getLanguageName(String languageCode) {
    return 'Français';
  }
}