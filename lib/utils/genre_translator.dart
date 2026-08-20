import '../l10n/app_localizations.dart';

class GenreTranslator {
  static String translate(AppLocalizations l10n, String genre) {
    final cleanGenre = genre.trim().toLowerCase();
    
    return switch (cleanGenre) {
      'rock' => l10n.genreRock,
      'pop' => l10n.genrePop,
      'jazz' => l10n.genreJazz,
      'classical' => l10n.genreClassical,
      'soundtrack' => l10n.genreSoundtrack,
      'electronic' => l10n.genreElectronic,
      'hip hop' || 'hip-hop' => l10n.genreHipHop,
      'blues' => l10n.genreBlues,
      'metal' => l10n.genreMetal,
      'country' => l10n.genreCountry,
      'reggae' => l10n.genreReggae,
      'folk' => l10n.genreFolk,
      'latin' => l10n.genreLatin,
      'christian' => l10n.genreChristian,
      'r&b' => l10n.genreRnB,
      'soul' => l10n.genreSoul,
      'disco' => l10n.genreDisco,
      'punk' => l10n.genrePunk,
      'ambient' => l10n.genreAmbient,
      'new age' => l10n.genreNewAge,
      'ska' => l10n.genreSka,
      'gospel' => l10n.genreGospel,
      'techno' => l10n.genreTechno,
      'trance' => l10n.genreTrance,
      'house' => l10n.genreHouse,
      'rap' => l10n.genreRap,
      _ => genre, // Return original if no translation found
    };
  }
}
