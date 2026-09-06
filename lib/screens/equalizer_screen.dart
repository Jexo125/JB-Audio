import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/equalizer_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final equalizerService = context.watch<EqualizerService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(l10n.equalizer),
        centerTitle: false,
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Switch(
            value: equalizerService.enabled,
            onChanged: (value) => equalizerService.setEnabled(value),
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: equalizerService.equalizer == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n.equalizerNotSupported,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPresetSelector(context, equalizerService, l10n),
                  const SizedBox(height: 32),
                  _buildEqualizerBands(context, equalizerService),
                  const SizedBox(height: 32),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => equalizerService.reset(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.reset),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPresetSelector(BuildContext context, EqualizerService service, AppLocalizations l10n) {
    final presets = [
      'Flat', 'Rock', 'Pop', 'Jazz', 'Classical', 'Dance', 'Hip-Hop', 'Bass Boost', 'Vocal', 'Acoustic', 'Custom'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.preset,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            final isSelected = service.currentPreset == preset;
            return ChoiceChip(
              label: Text(_getPresetName(preset, l10n)),
              selected: isSelected,
              onSelected: preset == 'Custom' ? null : (selected) {
                if (selected) service.setPreset(preset);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getPresetName(String preset, AppLocalizations l10n) {
    switch (preset) {
      case 'Flat': return l10n.presetFlat;
      case 'Rock': return l10n.presetRock;
      case 'Pop': return l10n.presetPop;
      case 'Jazz': return l10n.presetJazz;
      case 'Classical': return l10n.presetClassical;
      case 'Dance': return l10n.presetDance;
      case 'Hip-Hop': return l10n.presetHipHop;
      case 'Bass Boost': return l10n.presetBassBoost;
      case 'Vocal': return l10n.presetVocal;
      case 'Acoustic': return l10n.presetAcoustic;
      case 'Custom': return l10n.presetCustom;
      default: return preset;
    }
  }

  Widget _buildEqualizerBands(BuildContext context, EqualizerService service) {
    return FutureBuilder(
      future: service.equalizer?.parameters,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final params = snapshot.data!;
        final bands = params.bands;
        
        return Container(
          height: 300,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(bands.length, (index) {
              final band = bands[index];
              return _BandSlider(
                index: index,
                freq: band.centerFrequency,
                min: params.minDecibels,
                max: params.maxDecibels,
                value: service.currentPreset == 'Custom' && index < service.customGains.length
                    ? service.customGains[index]
                    : band.gain,
                onChanged: (val) => service.setBandGain(index, val),
                enabled: service.enabled,
              );
            }),
          ),
        );
      },
    );
  }
}

class _BandSlider extends StatelessWidget {
  final int index;
  final double freq;
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const _BandSlider({
    required this.index,
    required this.freq,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  String _formatFreq(double hz) {
    if (hz >= 1000) {
      final khz = hz / 1000;
      if (khz >= 10) {
        return '${khz.toInt()}k';
      }
      return '${khz.toStringAsFixed(khz % 1 == 0 ? 0 : 1)}k';
    }
    return '${hz.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${value > 0 ? "+" : ""}${value.toInt()}',
            style: TextStyle(
              fontSize: 10,
              color: enabled ? null : Colors.grey,
            ),
          ),
          const Text(
            'dB',
            style: TextStyle(fontSize: 8, color: Colors.grey),
          ),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  thumbColor: Theme.of(context).colorScheme.primary,
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: enabled ? onChanged : (val) {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatFreq(freq),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: enabled ? null : Colors.grey,
            ),
          ),
          const Text(
            'Hz',
            style: TextStyle(fontSize: 8, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
