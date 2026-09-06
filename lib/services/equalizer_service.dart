import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerService extends ChangeNotifier {
  static const String _keyEnabled = 'equalizer_enabled';
  static const String _keyPreset = 'equalizer_preset';
  static const String _keyCustomGains = 'equalizer_custom_gains';
  static const String _keyPreamp = 'equalizer_preamp';

  final AndroidEqualizer? _equalizer;

  bool _enabled = false;
  String _currentPreset = 'Flat';
  List<double> _customGains = [];
  double _manualPreamp = 0.0;
  
  bool get enabled => _enabled;
  String get currentPreset => _currentPreset;
  List<double> get customGains => _customGains;
  double get manualPreamp => _manualPreamp;

  AndroidEqualizer? get equalizer => _equalizer;

  EqualizerService(this._equalizer) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_keyEnabled) ?? false;
      _currentPreset = prefs.getString(_keyPreset) ?? 'Flat';
      _manualPreamp = prefs.getDouble(_keyPreamp) ?? 0.0;
      
      final customGainsJson = prefs.getString(_keyCustomGains);
      
      if (_equalizer != null) {
        // We need to wait for parameters to be available to know the number of bands
        final params = await _equalizer!.parameters;
        
        if (customGainsJson != null) {
          final decoded = jsonDecode(customGainsJson);
          if (decoded is List) {
            _customGains = List<double>.from(decoded.map((e) => (e as num).toDouble()));
          }
        }
        
        if (_customGains.length != params.bands.length) {
          _customGains = List.filled(params.bands.length, 0.0);
        }
      }

      // Initial apply
      await applySettings();
      notifyListeners();
    } catch (e) {
      debugPrint('[Equalizer] Error loading settings: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    
    await applySettings();
    notifyListeners();
  }

  Future<void> setPreset(String presetName) async {
    _currentPreset = presetName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreset, presetName);
    
    await applySettings();
    notifyListeners();
  }

  Future<void> setBandGain(int index, double gain) async {
    if (_equalizer == null) return;
    
    final params = await _equalizer!.parameters;
    if (_customGains.length != params.bands.length) {
      _customGains = List.filled(params.bands.length, 0.0);
    }
    
    if (index >= 0 && index < _customGains.length) {
      // Snap to 0.5 dB precision
      final snappedGain = (gain * 2).round() / 2.0;
      _customGains[index] = snappedGain;
      _currentPreset = 'Custom';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPreset, _currentPreset);
      await prefs.setString(_keyCustomGains, jsonEncode(_customGains));
      
      await applySettings();
      notifyListeners();
    }
  }

  Future<void> setPreamp(double value) async {
    // Snap to 0.5 dB precision
    _manualPreamp = (value * 2).round() / 2.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPreamp, _manualPreamp);
    
    await applySettings();
    notifyListeners();
  }

  Future<void> reset() async {
    _currentPreset = 'Flat';
    _manualPreamp = 0.0;
    if (_equalizer != null) {
      final params = await _equalizer!.parameters;
      _customGains = List.filled(params.bands.length, 0.0);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
    await prefs.setString(_keyPreset, _currentPreset);
    await prefs.setDouble(_keyPreamp, 0.0);
    await prefs.remove(_keyCustomGains);
    
    _enabled = false;
    await applySettings();
    notifyListeners();
  }

  Future<void> applySettings() async {
    if (_equalizer == null) return;

    final params = await _equalizer!.parameters;
    
    // Determine user target gains
    List<double> userGains;
    if (_currentPreset == 'Custom') {
      userGains = _customGains;
    } else {
      userGains = _getPresetGains(_currentPreset, params.bands.length);
    }

    // Bypass logic: disable effect if service is disabled OR if settings are strictly neutral
    // A setting is neutral if Preamp is 0 AND all bands are 0.
    bool isAllZero = _manualPreamp == 0.0 && userGains.every((g) => g == 0.0);
    bool shouldBeEnabled = _enabled && !isAllZero;
    
    if (!shouldBeEnabled) {
      // Neutralize bands before disabling to be safe
      for (var band in params.bands) {
        await band.setGain(0.0);
      }
      await _equalizer!.setEnabled(false);
      return;
    }

    // Enable the effect before applying gains
    await _equalizer!.setEnabled(true);

    // Apply final gains: (User Band Gain + Manual Preamp) / 10.0
    // The /10.0 factor corrects just_audio 0.9.46's internal *1000 multiplier
    // to match Android's 100mB = 1dB standard.
    for (int i = 0; i < params.bands.length; i++) {
      if (i < userGains.length) {
        double userRequestedGain = userGains[i] + _manualPreamp;
        
        // Final value sent to just_audio
        double dartValue = userRequestedGain / 10.0;
        
        // Clamp to physical limits of the device (reported by just_audio in its own units)
        double finalGain = dartValue.clamp(params.minDecibels, params.maxDecibels);
        
        await params.bands[i].setGain(finalGain);
      }
    }
  }

  List<double> _getPresetGains(String name, int bandCount) {
    // Standardized curves for 5 bands
    final Map<String, List<double>> basePresets = {
      'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
      'Rock': [4.5, 2.0, -1.0, 2.5, 4.5],
      'Pop': [-1.5, 1.5, 3.0, 1.5, -1.0],
      'Jazz': [3.5, 1.5, 0.0, 1.5, 3.5],
      'Classical': [4.0, 2.5, 0.0, 2.5, 4.0],
      'Dance': [5.5, 3.5, 0.0, 2.5, 1.0],
      'Hip-Hop': [5.0, 2.5, 0.0, 2.0, 4.0],
      'Bass Boost': [6.0, 3.5, 0.0, 0.0, 0.0],
      'Vocal': [-2.0, 0.0, 3.5, 2.5, -1.5],
      'Acoustic': [3.5, 2.0, 0.5, 2.5, 3.5],
    };

    final base = basePresets[name] ?? basePresets['Flat']!;
    
    if (bandCount == base.length) return base;
    
    // Linear interpolation for different band counts (e.g. 10 bands)
    List<double> result = [];
    for (int i = 0; i < bandCount; i++) {
      if (bandCount > 1) {
        double relativeIndex = i * (base.length - 1) / (bandCount - 1);
        int lower = relativeIndex.floor();
        int upper = relativeIndex.ceil();
        double fraction = relativeIndex - lower;
        
        double gain = base[lower] * (1 - fraction) + base[upper] * fraction;
        result.add(gain);
      } else {
        result.add(base[base.length ~/ 2]);
      }
    }
    return result;
  }
}
