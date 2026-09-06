import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerService extends ChangeNotifier {
  static const String _keyEnabled = 'equalizer_enabled';
  static const String _keyPreset = 'equalizer_preset';
  static const String _keyCustomGains = 'equalizer_custom_gains';

  final AndroidEqualizer? _equalizer;

  bool _enabled = false;
  String _currentPreset = 'Flat';
  List<double> _customGains = [];
  
  bool get enabled => _enabled;
  String get currentPreset => _currentPreset;
  List<double> get customGains => _customGains;

  AndroidEqualizer? get equalizer => _equalizer;

  EqualizerService(this._equalizer) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_equalizer == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_keyEnabled) ?? false;
      _currentPreset = prefs.getString(_keyPreset) ?? 'Flat';
      final customGainsJson = prefs.getString(_keyCustomGains);
      
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

      // Initial apply
      await applySettings();
      notifyListeners();
    } catch (e) {
      debugPrint('[Equalizer] Error loading settings: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_equalizer == null) return;
    
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    
    await _equalizer!.setEnabled(value);
    
    if (value) {
      await applySettings();
    }
    notifyListeners();
  }

  Future<void> setPreset(String presetName) async {
    _currentPreset = presetName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreset, presetName);
    
    if (_enabled) {
      await applySettings();
    }
    notifyListeners();
  }

  Future<void> setBandGain(int index, double gain) async {
    if (_equalizer == null) return;
    
    final params = await _equalizer!.parameters;
    if (_customGains.length != params.bands.length) {
      _customGains = List.filled(params.bands.length, 0.0);
    }
    
    if (index >= 0 && index < _customGains.length) {
      _customGains[index] = gain;
      _currentPreset = 'Custom';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPreset, _currentPreset);
      await prefs.setString(_keyCustomGains, jsonEncode(_customGains));
      
      if (_enabled) {
        await applySettings();
      }
      notifyListeners();
    }
  }

  Future<void> reset() async {
    _currentPreset = 'Flat';
    if (_equalizer != null) {
      final params = await _equalizer!.parameters;
      _customGains = List.filled(params.bands.length, 0.0);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
    await prefs.setString(_keyPreset, _currentPreset);
    await prefs.remove(_keyCustomGains);
    
    _enabled = false;
    if (_equalizer != null) {
      await _equalizer!.setEnabled(false);
      await applySettings();
    }
    
    notifyListeners();
  }

  Future<void> applySettings() async {
    if (_equalizer == null) return;
    
    // just_audio's setEnabled handles the bypassing logic
    await _equalizer!.setEnabled(_enabled);
    if (!_enabled) return;

    final params = await _equalizer!.parameters;
    
    List<double> targetGains;
    if (_currentPreset == 'Custom') {
      targetGains = _customGains;
    } else {
      targetGains = _getPresetGains(_currentPreset, params.bands.length);
    }

    for (int i = 0; i < params.bands.length; i++) {
      if (i < targetGains.length) {
        // Clamp gain to supported range
        final gain = targetGains[i].clamp(params.minDecibels, params.maxDecibels);
        await params.bands[i].setGain(gain);
      }
    }
  }

  List<double> _getPresetGains(String name, int bandCount) {
    final Map<String, List<double>> basePresets = {
      'Flat': [0, 0, 0, 0, 0],
      'Rock': [4, 2, -1, 2, 4],
      'Pop': [-1, 1, 2, 1, -1],
      'Jazz': [3, 2, 0, 2, 3],
      'Classical': [4, 3, 0, 3, 4],
      'Dance': [5, 3, 0, 2, 1],
      'Hip-Hop': [5, 2, 0, 2, 3],
      'Bass Boost': [6, 3, 0, 0, 0],
      'Vocal': [-2, 0, 3, 2, -1],
      'Acoustic': [3, 2, 0, 2, 3],
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
