class SearchUtility {
  /// Normalise une chaîne pour la recherche : minuscules, sans accents, sans ponctuation.
  static String normalize(String text) {
    String normalized = text.toLowerCase();

    // Remplacement des accents courants
    normalized = normalized.replaceAll(RegExp(r'[àáâãäå]'), 'a');
    normalized = normalized.replaceAll(RegExp(r'[èéêë]'), 'e');
    normalized = normalized.replaceAll(RegExp(r'[ìíîï]'), 'i');
    normalized = normalized.replaceAll(RegExp(r'[òóôõö]'), 'o');
    normalized = normalized.replaceAll(RegExp(r'[ùúûü]'), 'u');
    normalized = normalized.replaceAll(RegExp(r'[ýÿ]'), 'y');
    normalized = normalized.replaceAll(RegExp(r'ç'), 'c');
    normalized = normalized.replaceAll(RegExp(r'ñ'), 'n');
    normalized = normalized.replaceAll('œ', 'oe');
    normalized = normalized.replaceAll('æ', 'ae');

    // Remplacer la ponctuation et caractères spéciaux par des espaces
    // On garde les lettres et les chiffres
    normalized = normalized.replaceAll(RegExp(r"[^\w\s]"), ' ');

    // Supprimer les espaces multiples et trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    return normalized.trim();
  }

  /// Calcule un score de pertinence entre une requête et une cible.
  /// 1.0 = Match parfait (normalisé)
  /// 0.0 = Aucun match
  static double calculateScore(String query, String target) {
    if (query.isEmpty) return 0.0;
    if (target.isEmpty) return 0.0;

    final nQuery = normalize(query);
    final nTarget = normalize(target);

    if (nQuery == nTarget) return 1.0;
    
    // Si la cible contient exactement la requête (ex: "booba" dans "booba lunatic")
    if (nTarget.contains(nQuery)) {
      if (nTarget.startsWith(nQuery)) return 0.9;
      return 0.8;
    }

    // Recherche par mots (tokens)
    final qTokens = nQuery.split(' ').where((t) => t.isNotEmpty).toList();
    if (qTokens.isEmpty) return 0.0;

    int matchedTokens = 0;
    for (final token in qTokens) {
      if (nTarget.contains(token)) {
        matchedTokens++;
      }
    }

    if (matchedTokens == qTokens.length) {
      return 0.7; // Tous les mots sont présents dans le désordre
    }

    if (matchedTokens > 0) {
      return 0.3 * (matchedTokens / qTokens.length); // Certains mots sont présents
    }

    // On pourrait ajouter une distance de Levenshtein ici pour les fautes de frappe
    // mais on va d'abord valider cette approche token-based.

    return 0.0;
  }
}
