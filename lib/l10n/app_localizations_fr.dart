// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'JB Audio';

  @override
  String get emulatorDetected => 'Émulateur détecté';

  @override
  String get emulatorNotAllowed =>
      'Cette application ne peut pas s\'exécuter sur un émulateur.\\nVeuillez utiliser un appareil physique.';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bonjour';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get forYou => 'Pour vous';

  @override
  String get quickPicks => 'Sélection rapide';

  @override
  String get discoverMix => 'Mix Découverte';

  @override
  String get recentlyPlayed => 'Lus récemment';

  @override
  String get yourPlaylists => 'Vos playlists';

  @override
  String get favoritePlaylists => 'Playlists favorites';

  @override
  String get sectionAlbums => 'Albums';

  @override
  String get sectionEPs => 'EPs';

  @override
  String get sectionSingles => 'Singles';

  @override
  String get madeForYou => 'Fait pour vous';

  @override
  String get topRated => 'Les mieux notés';

  @override
  String get noContentAvailable => 'Aucun contenu disponible';

  @override
  String get tryRefreshing =>
      'Actualisez ou vérifiez votre connexion au serveur';

  @override
  String get refresh => 'Actualiser';

  @override
  String get errorLoadingSongs => 'Erreur lors du chargement des titres';

  @override
  String get noSongsInGenre => 'Pas de titre de ce genre';

  @override
  String get errorLoadingAlbums => 'Erreur lors du chargement des albums';

  @override
  String get noTopRatedAlbums => 'Aucun album le mieux noté';

  @override
  String get login => 'Connexion';

  @override
  String get serverUrl => 'Adresse du serveur';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get selectCertificate => 'Sélectionnez le certificat TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'Impossible de sélectionner le certificat : $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'L\'adresse du serveur doit commencer par http:// ou https://';

  @override
  String get failedToConnect => 'Échec de la connexion';

  @override
  String get library => 'Bibliothèque';

  @override
  String get search => 'Rechercher';

  @override
  String get settings => 'Paramètres';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artistes';

  @override
  String get songs => 'Titres';

  @override
  String get playlists => 'Playlists';

  @override
  String get genres => 'Genres';

  @override
  String get years => 'Années';

  @override
  String get favorites => 'Favoris';

  @override
  String get nowPlaying => 'En cours de lecture';

  @override
  String get queue => 'File d\'attente';

  @override
  String get lyrics => 'Paroles';

  @override
  String get play => 'Lecture';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get shuffle => 'Aléatoire';

  @override
  String get repeat => 'Répéter tout';

  @override
  String get repeatOne => 'Répéter un titre';

  @override
  String get repeatOff => 'Répétition désactivée';

  @override
  String get addToPlaylist => 'Ajouter à la playlist';

  @override
  String get removeFromPlaylist => 'Retirer de la playlist';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get download => 'Télécharger';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'Ok';

  @override
  String get save => 'Enregistrer';

  @override
  String get close => 'Fermer';

  @override
  String get general => 'Général';

  @override
  String get appearance => 'Apparence';

  @override
  String get playback => 'Lecture';

  @override
  String get storage => 'Stockage';

  @override
  String get about => 'À propos';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get language => 'Langue';

  @override
  String get version => 'Version';

  @override
  String get madeBy => 'Développé par JB Audio';

  @override
  String get githubRepository => 'Dépôt GitHub';

  @override
  String get reportIssue => 'Signaler un problème';

  @override
  String get joinDiscord => 'Rejoindre la communauté Discord';

  @override
  String get unknownArtist => 'Artiste inconnu';

  @override
  String get unknownAlbum => 'Album inconnu';

  @override
  String get playAll => 'Tout lire';

  @override
  String get shuffleAll => 'Tout mélanger';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortByName => 'Nom';

  @override
  String get sortByArtist => 'Artiste';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Date';

  @override
  String get sortByDuration => 'Durée';

  @override
  String get ascending => 'Croissant';

  @override
  String get descending => 'Décroissant';

  @override
  String get noLyricsAvailable => 'Paroles non disponibles';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get searchHint => 'Rechercher titres, albums, artistes...';

  @override
  String get allSongs => 'Tous les titres';

  @override
  String get allAlbums => 'Tous les albums';

  @override
  String get allArtists => 'Tous les artistes';

  @override
  String trackNumber(int number) {
    return 'Piste n°$number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
      zero: 'Aucun titre',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
      zero: 'Aucun album',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Déconnexion';

  @override
  String get confirmLogout => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get offlineMode => 'Mode hors-connexion';

  @override
  String get radio => 'Radio';

  @override
  String get changelog => 'Journal des changements';

  @override
  String get platform => 'Plateforme';

  @override
  String get server => 'Serveur';

  @override
  String get display => 'Affichage';

  @override
  String get playerInterface => 'Interface du lecteur';

  @override
  String get smartRecommendations => 'Recommandations personnalisées';

  @override
  String get showVolumeSlider => 'Afficher le curseur du volume';

  @override
  String get showVolumeSliderSubtitle =>
      'Afficher le contrôle du volume dans l\'écran de lecture';

  @override
  String get showStarRatings => 'Afficher les notes';

  @override
  String get showStarRatingsSubtitle => 'Noter les titres et voir les notes';

  @override
  String get showMiniPlayerHeart => 'Afficher le bouton favoris';

  @override
  String get showMiniPlayerHeartSubtitle =>
      'Ajouter aux favoris depuis le mini-lecteur';

  @override
  String get showMiniPlayerRepeat => 'Afficher le bouton répéter';

  @override
  String get showMiniPlayerRepeatSubtitle =>
      'Changer le mode de répétition depuis le mini-lecteur';

  @override
  String get showMiniPlayerShuffle => 'Afficher le bouton aléatoire';

  @override
  String get showMiniPlayerShuffleSubtitle =>
      'Activer l\'aléatoire depuis le mini-lecteur';

  @override
  String get enableRecommendations => 'Activer les recommandations';

  @override
  String get enableRecommendationsSubtitle =>
      'Obtenez des suggestions musicales personnalisées';

  @override
  String get listeningData => 'Données d\'écoute';

  @override
  String totalPlays(int count) {
    return '$count lectures au total';
  }

  @override
  String get clearListeningHistory => 'Effacer l\'historique d\'écoute';

  @override
  String get confirmClearHistory =>
      'Cela réinitialisera toutes vos données d\'écoute et recommandations. Confirmer ?';

  @override
  String get historyCleared => 'Historique d\'écoute effacé';

  @override
  String get discordStatus => 'Statut Discord';

  @override
  String get discordStatusSubtitle =>
      'Afficher la musique en cours sur votre profil Discord';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get systemDefault => 'Système par défaut';

  @override
  String get communityTranslations => 'Traductions par la communauté';

  @override
  String get communityTranslationsSubtitle =>
      'Aidez-nous à traduire Musly sur Crowdin';

  @override
  String get yourLibrary => 'Ma Bibliothèque';

  @override
  String get filterAll => 'Tout';

  @override
  String get faves => 'Favoris';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get filterAlbums => 'Albums';

  @override
  String get filterArtists => 'Artistes';

  @override
  String get likedSongs => 'Titres aimés';

  @override
  String get likedAlbums => 'Albums aimés';

  @override
  String get noLikedAlbums => 'Aucun album aimé';

  @override
  String get localMusicLibrary => 'Musique locale';

  @override
  String get mergeLocalLibrary => 'Fusionner avec la bibliothèque serveur';

  @override
  String get mergeLocalLibrarySubtitle =>
      'Afficher la musique locale avec votre bibliothèque serveur';

  @override
  String get localMusicStats => 'Fichiers de musique locaux';

  @override
  String get addMusicFolder => 'Ajouter un dossier';

  @override
  String get rescanLocalMusic => 'Scanner à nouveau';

  @override
  String get localLibraryEmpty => 'Votre bibliothèque est vide';

  @override
  String get localLibraryEmptySubtitle =>
      'Aucun fichier musical local n\'a été trouvé.';

  @override
  String get libraryEmpty => 'Votre bibliothèque est vide';

  @override
  String get libraryEmptySubtitle => 'Ajoutez des titres pour commencer.';

  @override
  String get scanForMusic => 'Scanner la musique';

  @override
  String get radioStations => 'Stations radio';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Radio Internet';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String get playlistName => 'Nom de la playlist';

  @override
  String get create => 'Créer';

  @override
  String get deletePlaylist => 'Supprimer la playlist';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Voulez-vous supprimer la playlist \"$name\" ?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Playlist \"$name\" supprimée';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Erreur lors de la création de la playlist : $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Erreur lors de la suppression de la playlist : $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Playlist \"$name\" créée';
  }

  @override
  String get searchTitle => 'Rechercher';

  @override
  String get searchPlaceholder => 'Artistes, Titres, Albums';

  @override
  String get tryDifferentSearch => 'Essayez une autre recherche';

  @override
  String get noSuggestions => 'Aucune suggestion';

  @override
  String get browseCategories => 'Parcourir les catégories';

  @override
  String get liveSearchSection => 'Recherche';

  @override
  String get liveSearch => 'Recherche en direct';

  @override
  String get liveSearchSubtitle =>
      'Mise à jour des résultats lors de la saisie';

  @override
  String get categoryMadeForYou => 'Fait pour vous';

  @override
  String get categoryNewReleases => 'Nouvelles sorties';

  @override
  String get categoryTopRated => 'Mieux notés';

  @override
  String get categoryGenres => 'Genres';

  @override
  String get categoryFavorites => 'Favoris';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get tabPlayback => 'Lecture';

  @override
  String get tabStorage => 'Stockage';

  @override
  String get tabServer => 'Serveur';

  @override
  String get tabDisplay => 'Affichage';

  @override
  String get tabSupport => 'Soutien';

  @override
  String get tabAbout => 'À propos';

  @override
  String get sectionAutoDj => 'AUTO DJ';

  @override
  String get autoDjMode => 'Mode Auto DJ';

  @override
  String songsToAdd(int count) {
    return 'Titres à ajouter : $count';
  }

  @override
  String get sectionReplayGain => 'NORMALISATION DU VOLUME (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Mode';

  @override
  String preamp(String value) {
    return 'Pré-ampli : $value dB';
  }

  @override
  String get preventClipping => 'Empêcher l\'écrêtage';

  @override
  String fallbackGain(String value) {
    return 'Gain par défaut : $value dB';
  }

  @override
  String get sectionStreamingQuality => 'QUALITÉ STREAMING';

  @override
  String get enableTranscoding => 'Activer le transcodage';

  @override
  String get qualityWifi => 'Qualité Wi-Fi';

  @override
  String get qualityMobile => 'Qualité Mobile';

  @override
  String get format => 'Format';

  @override
  String get transcodingSubtitle => 'Réduire la consommation de données';

  @override
  String get modeOff => 'Off';

  @override
  String get modeTrack => 'Titre';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'CONNEXION SERVEUR';

  @override
  String get serverType => 'Type de serveur';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get unknown => 'Inconnu';

  @override
  String get sectionMusicFolders => 'DOSSIERS MUSIQUE';

  @override
  String get musicFolders => 'Dossiers musique';

  @override
  String get noMusicFolders => 'Aucun dossier trouvé';

  @override
  String get sectionSavedProfiles => 'PROFILS ENREGISTRÉS';

  @override
  String get switchProfile => 'Changer de profil';

  @override
  String get switchServer => 'Changer de serveur';

  @override
  String get addProfile => 'Ajouter un profil';

  @override
  String switchProfileConfirmation(String profile) {
    return 'Se connecter à \"$profile\" ?';
  }

  @override
  String get sectionAccount => 'COMPTE';

  @override
  String get logoutConfirmation =>
      'Voulez-vous vous déconnecter ? Cela effacera les données en cache.';

  @override
  String get sectionCacheSettings => 'RÉGLAGES DU CACHE';

  @override
  String get imageCache => 'Cache d\'images';

  @override
  String get musicCache => 'Cache de musique';

  @override
  String get bpmCache => 'Cache BPM';

  @override
  String get saveAlbumCovers => 'Mettre en cache les pochettes';

  @override
  String get saveSongMetadata => 'Mettre en cache les métadonnées';

  @override
  String get saveBpmAnalysis => 'Mettre en cache l\'analyse BPM';

  @override
  String get sectionCacheCleanup => 'NETTOYAGE DU CACHE';

  @override
  String get clearAllCache => 'Vider tout le cache';

  @override
  String get allCacheCleared => 'Tout le cache a été vidé';

  @override
  String get sectionOfflineDownloads => 'TÉLÉCHARGEMENTS';

  @override
  String get downloadedSongs => 'Titres téléchargés';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Téléchargement de la bibliothèque... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Tout télécharger';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Ceci va télécharger $count titres. Cela peut prendre du temps et de l\'espace.\n\nContinuer ?';
  }

  @override
  String get keepScreenOnDuringDownload => 'Garder l\'écran allumé';

  @override
  String get keepScreenOnDuringDownloadSubtitle =>
      'Empêche l\'arrêt du téléchargement lors du verrouillage';

  @override
  String get parallelDownloads => 'Téléchargements parallèles';

  @override
  String get parallelDownloadsSubtitle =>
      'Nombre de fichiers à télécharger simultanément';

  @override
  String get downloadSingular => 'téléchargement';

  @override
  String get downloadPlural => 'téléchargements';

  @override
  String get slowerButStable => 'Lent mais stable';

  @override
  String get fasterButMoreData => 'Rapide mais gourmand';

  @override
  String get libraryDownloadStarted => 'Téléchargement démarré';

  @override
  String get deleteDownloads => 'Supprimer les téléchargements';

  @override
  String get downloadsDeleted => 'Téléchargements supprimés';

  @override
  String get noSongsAvailable =>
      'Aucun titre disponible. Chargez votre bibliothèque.';

  @override
  String get sectionBpmAnalysis => 'ANALYSE BPM';

  @override
  String get cachedBpms => 'BPM mis en cache';

  @override
  String get cacheAllBpms => 'Analyser tout en cache';

  @override
  String get clearBpmCache => 'Vider le cache BPM';

  @override
  String get bpmCacheCleared => 'Cache BPM vidé';

  @override
  String downloadedStats(int count, String size) {
    return '$count titres • $size';
  }

  @override
  String get sectionInformation => 'INFORMATIONS';

  @override
  String get sectionDeveloper => 'DÉVELOPPEUR';

  @override
  String get sectionLinks => 'LIENS';

  @override
  String get githubRepo => 'Dépôt GitHub';

  @override
  String get playingFrom => 'LECTURE DEPUIS';

  @override
  String get live => 'DIRECT';

  @override
  String get streamingLive => 'Streaming en direct';

  @override
  String get stopRadio => 'Arrêter la radio';

  @override
  String get removeFromLiked => 'Ne plus aimer';

  @override
  String get addToLiked => 'Ajouter aux coups de cœur';

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get addToQueue => 'Ajouter à la file';

  @override
  String get goToAlbum => 'Aller à l\'album';

  @override
  String get goToArtist => 'Aller à l\'artiste';

  @override
  String get rateSong => 'Noter le titre';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Noter ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Note retirée';

  @override
  String rated(int rating, String stars) {
    return 'Noté $rating $stars';
  }

  @override
  String get removeRating => 'Retirer la note';

  @override
  String get downloaded => 'Téléchargé';

  @override
  String downloading(int percent) {
    return 'Téléchargement... $percent%';
  }

  @override
  String get removeDownload => 'Supprimer le téléchargement';

  @override
  String get removeDownloadConfirm =>
      'Retirer ce titre du stockage hors-ligne ?';

  @override
  String get downloadRemoved => 'Téléchargement supprimé';

  @override
  String downloadedTitle(String title) {
    return 'Téléchargé \"$title\"';
  }

  @override
  String get downloadFailed => 'Échec du téléchargement';

  @override
  String downloadError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Ajouté \"$title\" à $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Erreur d\'ajout : $error';
  }

  @override
  String get noPlaylists => 'Aucune playlist';

  @override
  String get createNewPlaylist => 'Créer une playlist';

  @override
  String artistNotFound(String name) {
    return 'Artiste \"$name\" introuvable';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Erreur de recherche : $error';
  }

  @override
  String get selectArtist => 'Choisir un artiste';

  @override
  String get removedFromFavorites => 'Retiré des favoris';

  @override
  String get addedToFavorites => 'Ajouté aux favoris';

  @override
  String get star => 'étoile';

  @override
  String get stars => 'étoiles';

  @override
  String get albumNotFound => 'Album introuvable';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get topSongs => 'Titres populaires';

  @override
  String get connected => 'Connecté';

  @override
  String get noSongPlaying => 'Aucune musique en cours';

  @override
  String get internetRadioUppercase => 'RADIO INTERNET';

  @override
  String get playingNext => 'À suivre';

  @override
  String get createPlaylistTitle => 'Créer une playlist';

  @override
  String get playlistNameHint => 'Nom de la playlist';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Playlist \"$name\" créée avec ce titre';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Erreur lors du chargement : $error';
  }

  @override
  String get playlistNotFound => 'Playlist introuvable';

  @override
  String get noSongsInPlaylist => 'Aucun titre dans cette playlist';

  @override
  String get noFavoriteSongsYet => 'Aucun titre favori';

  @override
  String get noFavoriteAlbumsYet => 'Aucun album favori';

  @override
  String get listeningHistory => 'Historique d\'écoute';

  @override
  String get noListeningHistory => 'Aucun historique d\'écoute';

  @override
  String get songsWillAppearHere =>
      'Les titres que vous écoutez apparaîtront ici';

  @override
  String get sortByTitleAZ => 'Titre (A-Z)';

  @override
  String get sortByTitleZA => 'Titre (Z-A)';

  @override
  String get sortByArtistAZ => 'Artiste (A-Z)';

  @override
  String get sortByArtistZA => 'Artiste (Z-A)';

  @override
  String get sortByAlbumAZ => 'Album (A-Z)';

  @override
  String get sortByAlbumZA => 'Album (Z-A)';

  @override
  String get recentlyAdded => 'Ajoutés récemment';

  @override
  String get noSongsFound => 'Aucun morceau trouvé';

  @override
  String get noAlbumsFound => 'Aucun album trouvé';

  @override
  String get noHomepageUrl => 'Pas de page d\'accueil';

  @override
  String get playStation => 'Écouter la station';

  @override
  String get openHomepage => 'Ouvrir le site';

  @override
  String get copyStreamUrl => 'Copier l\'URL du flux';

  @override
  String get failedToLoadRadioStations => 'Échec du chargement des radios';

  @override
  String get noRadioStations => 'Aucune radio';

  @override
  String get noRadioStationsHint =>
      'Ajoutez des stations dans Navidrome pour les voir ici.';

  @override
  String get connectToServerSubtitle =>
      'Connectez-vous à votre serveur Subsonic';

  @override
  String get pleaseEnterServerUrl => 'Veuillez entrer l\'URL du serveur';

  @override
  String get invalidUrlFormat =>
      'L\'URL doit commencer par http:// ou https://';

  @override
  String get pleaseEnterUsername => 'Veuillez entrer un nom d\'utilisateur';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer un mot de passe';

  @override
  String get legacyAuthentication => 'Authentification classique';

  @override
  String get legacyAuthSubtitle => 'Pour les anciens serveurs Subsonic';

  @override
  String get allowSelfSignedCerts => 'Certificats auto-signés';

  @override
  String get allowSelfSignedSubtitle =>
      'Pour les serveurs avec certificats personnalisés';

  @override
  String get advancedOptions => 'Options avancées';

  @override
  String get customTlsCertificate => 'Certificat TLS personnalisé';

  @override
  String get customCertificateSubtitle =>
      'Utiliser un certificat spécifique (CA non-standard)';

  @override
  String get selectCertificateFile => 'Choisir un fichier de certificat';

  @override
  String get clientCertificate => 'Certificat client (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Authentification par certificat (nécessite un serveur mTLS)';

  @override
  String get selectClientCertificate => 'Choisir un certificat client';

  @override
  String get clientCertPassword => 'Mot de passe du certificat (optionnel)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Échec de sélection du certificat : $error';
  }

  @override
  String get connect => 'Se connecter';

  @override
  String get or => 'OU';

  @override
  String get useLocalFiles => 'Utiliser les fichiers locaux';

  @override
  String get startingScan => 'Scan en cours...';

  @override
  String get storagePermissionRequired =>
      'Permission d\'accès au stockage requise';

  @override
  String get noMusicFilesFound => 'Aucun fichier musical trouvé';

  @override
  String get remove => 'Retirer';

  @override
  String failedToSetRating(Object error) {
    return 'Échec de notation : $error';
  }

  @override
  String get home => 'Accueil';

  @override
  String get playlistsSection => 'PLAYLISTS';

  @override
  String get collapse => 'Réduire';

  @override
  String get expand => 'Agrandir';

  @override
  String get createPlaylist => 'Créer une playlist';

  @override
  String get likedSongsSidebar => 'Titres aimés';

  @override
  String playlistSongsCount(int count) {
    return 'Playlist • $count titres';
  }

  @override
  String get failedToLoadLyrics => 'Échec du chargement des paroles';

  @override
  String get lyricsNotFoundSubtitle => 'Aucune parole trouvée pour ce titre';

  @override
  String get backToCurrent => 'Retour au direct';

  @override
  String get exitFullscreen => 'Quitter le plein écran';

  @override
  String get fullscreen => 'Plein écran';

  @override
  String get noLyrics => 'Pas de paroles';

  @override
  String get internetRadioMiniPlayer => 'Radio Internet';

  @override
  String get liveBadge => 'DIRECT';

  @override
  String get localFilesModeBanner => 'Mode Fichiers Locaux';

  @override
  String get offlineModeBanner =>
      'Mode Hors-ligne (Musique téléchargée uniquement)';

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String get updateAvailableSubtitle =>
      'Une nouvelle mise à jour de JB Audio est disponible !';

  @override
  String updateCurrentVersion(String version) {
    return 'Actuelle : v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Dernière : v$version';
  }

  @override
  String get whatsNew => 'Nouveautés';

  @override
  String get downloadUpdate => 'Télécharger';

  @override
  String get remindLater => 'Plus tard';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get artistDataNotFound => 'Artiste introuvable';

  @override
  String get addedArtistToQueue => 'Artiste ajouté à la file';

  @override
  String get addedArtistToQueueError =>
      'Échec d\'ajout de l\'artiste à la file';

  @override
  String get casting => 'Diffusion en cours';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Cast / DLNA (Bêta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get searchingDevices => 'Recherche d\'appareils...';

  @override
  String get castWifiHint =>
      'Vérifiez que l\'appareil est sur le même réseau Wi-Fi';

  @override
  String connectedToDevice(String name) {
    return 'Connecté à $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Échec de connexion à $name';
  }

  @override
  String get removedFromLikedSongs => 'Retiré des titres aimés';

  @override
  String get addedToLikedSongs => 'Ajouté aux titres aimés';

  @override
  String get enableShuffle => 'Activer l\'aléatoire';

  @override
  String get enableRepeat => 'Activer la boucle';

  @override
  String get connecting => 'Connexion...';

  @override
  String get closeLyrics => 'Fermer les paroles';

  @override
  String errorStartingDownload(Object error) {
    return 'Échec de démarrage du téléchargement : $error';
  }

  @override
  String get errorLoadingGenres => 'Échec du chargement des genres';

  @override
  String get noGenresFound => 'Aucun genre trouvé';

  @override
  String get noAlbumsInGenre => 'Aucun album pour ce genre';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount titres • $albumCount albums';
  }

  @override
  String get sectionJukebox => 'MODE JUKEBOX';

  @override
  String get jukeboxMode => 'Mode Jukebox';

  @override
  String get jukeboxModeSubtitle =>
      'Lire l\'audio via le serveur au lieu de cet appareil';

  @override
  String get openJukeboxController => 'Ouvrir le contrôleur Jukebox';

  @override
  String get jukeboxClearQueue => 'Vider la file';

  @override
  String get jukeboxShuffleQueue => 'Mélanger la file';

  @override
  String get jukeboxQueueEmpty => 'La file est vide';

  @override
  String get jukeboxNowPlaying => 'En cours';

  @override
  String get jukeboxQueue => 'File d\'attente';

  @override
  String get jukeboxVolume => 'Volume';

  @override
  String get playOnJukebox => 'Lire sur le Jukebox';

  @override
  String get addToJukeboxQueue => 'Ajouter au Jukebox';

  @override
  String get jukeboxNotSupported =>
      'Le mode Jukebox n\'est pas supporté par ce serveur.';

  @override
  String get musicFoldersDialogTitle => 'Dossiers musicaux';

  @override
  String get musicFoldersHint =>
      'Laissez tout coché pour utiliser tous les dossiers.';

  @override
  String get musicFoldersSaved => 'Sélection des dossiers enregistrée';

  @override
  String get artworkStyleSection => 'Style des illustrations';

  @override
  String get artworkCornerRadius => 'Rayon des coins';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Ajuster l\'arrondi des pochettes d\'album';

  @override
  String get artworkCornerRadiusNone => 'Aucun';

  @override
  String get artworkShape => 'Forme';

  @override
  String get artworkShapeRounded => 'Arrondi';

  @override
  String get artworkShapeCircle => 'Cercle';

  @override
  String get artworkShapeSquare => 'Carré';

  @override
  String get artworkShadow => 'Ombre';

  @override
  String get artworkShadowNone => 'Aucune';

  @override
  String get artworkShadowSoft => 'Douce';

  @override
  String get artworkShadowMedium => 'Moyenne';

  @override
  String get artworkShadowStrong => 'Forte';

  @override
  String get artworkShadowColor => 'Couleur d\'ombre';

  @override
  String get artworkShadowColorBlack => 'Noir';

  @override
  String get artworkShadowColorAccent => 'Accentuation';

  @override
  String get artworkPreview => 'Aperçu';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '$value px';
  }

  @override
  String get noArtwork => 'Pas d\'illustration';

  @override
  String get serverUnreachableTitle => 'Serveur injoignable';

  @override
  String get serverUnreachableSubtitle =>
      'Vérifiez votre connexion ou les réglages du serveur.';

  @override
  String get openOfflineMode => 'Mode hors-ligne';

  @override
  String get appearanceSection => 'Apparence';

  @override
  String get themeLabel => 'Thème';

  @override
  String get accentColorLabel => 'Couleur d\'accent';

  @override
  String get circularDesignLabel => 'Design Circulaire';

  @override
  String get circularDesignSubtitle =>
      'Interface flottante avec panneaux translucides et effet de flou (lecteur et navigation).';

  @override
  String get themeModeSystem => 'Système';

  @override
  String get themeModeLight => 'Clair';

  @override
  String get themeModeDark => 'Sombre';

  @override
  String get liveLabel => 'DIRECT';

  @override
  String get discordStatusText => 'Texte Discord';

  @override
  String get discordStatusTextSubtitle => 'Seconde ligne affichée sur Discord';

  @override
  String get discordRpcStyleArtist => 'Nom de l\'artiste';

  @override
  String get discordRpcStyleSong => 'Titre du morceau';

  @override
  String get discordRpcStyleApp => 'Nom de l\'application';

  @override
  String get sectionVolumeNormalization => 'NORMALISATION (REPLAYGAIN)';

  @override
  String get sectionFadeInOut => 'FONDU ENCHAÎNÉ';

  @override
  String get fadeInOutEnable => 'Activer le fondu';

  @override
  String get fadeInOutSubtitle => 'Fondu progressif lors de la lecture/pause';

  @override
  String fadeDuration(int duration) {
    return 'Durée du fondu : ${duration}ms';
  }

  @override
  String get replayGainModeOff => 'Off';

  @override
  String get replayGainModeTrack => 'Titre';

  @override
  String get replayGainModeAlbum => 'Album';

  @override
  String replayGainPreamp(String value) {
    return 'Pré-ampli : $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Éviter l\'écrêtage';

  @override
  String replayGainFallbackGain(String value) {
    return 'Gain par défaut : $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Titres à ajouter : $count';
  }

  @override
  String get transcodingEnable => 'Activer le transcodage';

  @override
  String get transcodingEnableSubtitle =>
      'Économiser les données (qualité réduite)';

  @override
  String get smartTranscoding => 'Transcodage Intelligent';

  @override
  String get smartTranscodingSubtitle =>
      'Ajuste la qualité selon la connexion (Wi-Fi vs Mobile)';

  @override
  String get smartTranscodingDetectedNetwork => 'Réseau détecté : ';

  @override
  String smartTranscodingActiveBitrate(String bitrate) {
    return 'Débit actif : $bitrate';
  }

  @override
  String get transcodingWifiQuality => 'Qualité Wi-Fi';

  @override
  String get transcodingWifiQualitySubtitleSmart => 'Auto sur Wi-Fi';

  @override
  String get transcodingWifiQualitySubtitle => 'Débit binaire sur Wi-Fi';

  @override
  String get transcodingMobileQuality => 'Qualité Mobile';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Auto sur données mobiles';

  @override
  String get transcodingMobileQualitySubtitle => 'Débit binaire sur mobile';

  @override
  String get transcodingFormat => 'Format';

  @override
  String get transcodingFormatSubtitle =>
      'Codec audio utilisé pour la diffusion';

  @override
  String get transcodingBitrateOriginal => 'Original (Sans transcodage)';

  @override
  String get transcodingFormatOriginal => 'Original';

  @override
  String get imageCacheTitle => 'Cache d\'images';

  @override
  String get imageCacheSubtitle => 'Sauvegarder les pochettes d\'album';

  @override
  String get musicCacheTitle => 'Cache de musique';

  @override
  String get musicCacheSubtitle => 'Sauvegarder les infos des titres';

  @override
  String get bpmCacheTitle => 'Cache BPM';

  @override
  String get bpmCacheSubtitle => 'Conserver les résultats d\'analyse BPM';

  @override
  String get sectionAboutInformation => 'INFORMATIONS';

  @override
  String get sectionAboutDeveloper => 'DÉVELOPPEUR';

  @override
  String get sectionAboutLinks => 'LIENS';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutPlatform => 'Plateforme';

  @override
  String get aboutMadeBy => 'Par JB Audio';

  @override
  String get aboutGitHub => 'github.com/JB Audio';

  @override
  String get aboutLinkGitHub => 'Dépôt GitHub';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get aboutLinkReportIssue => 'Signaler un bug';

  @override
  String get aboutLinkDiscord => 'Rejoindre le Discord';

  @override
  String get sectionAnalyticsPrivacy => 'Analyse & Confidentialité';

  @override
  String get anonymousAnalytics => 'Analyses anonymes';

  @override
  String get anonymousAnalyticsSubtitle =>
      'Aidez à améliorer Musly avec des rapports d\'erreur anonymes';

  @override
  String get deviceId => 'Identifiant de l\'appareil';

  @override
  String deviceIdAnonymous(String id) {
    return 'ID Anonyme : $id';
  }

  @override
  String get deviceIdDisabled =>
      'Activez les analyses pour voir votre ID anonyme';

  @override
  String get aboutDeviceId => 'À propos de l\'ID appareil';

  @override
  String get aboutDeviceIdSubtitle =>
      'Identifiant anonyme utilisé uniquement pour les statistiques et les erreurs.';

  @override
  String get supportGreeting => 'Salut ! 👋';

  @override
  String get supportParagraph1 =>
      'Je suis Devid, le développeur de JB Audio. J\'ai créé cette app car j\'aime la musique et je pense que tout le monde mérite un lecteur beau et gratuit.';

  @override
  String get supportParagraph2 =>
      'Musly est gratuit et open-source. Pas de pubs, pas d\'abonnements. J\'y travaille sur mon temps libre par passion.';

  @override
  String get supportParagraph3 =>
      'Mais les serveurs et les outils de dév ne sont pas gratuits 😅 Si Musly fait partie de votre quotidien, un petit don m\'aiderait énormément.';

  @override
  String get supportParagraph4 =>
      'C\'est sans pression ! Votre plaisir d\'utiliser l\'app est déjà ma meilleure récompense. 💙';

  @override
  String get supportDonationTitle => 'Soutenir avec un don';

  @override
  String get supportDonationSubtitle => 'via Revolut - chaque geste compte !';

  @override
  String get supportDiscordTitle => 'Rejoindre notre Discord';

  @override
  String get supportDiscordSubtitle => 'Aide, suggestions ou simple discussion';

  @override
  String get supportWaysTitle => 'Autres façons de soutenir';

  @override
  String get supportWayRate => 'Laisser une note sur le store';

  @override
  String get supportWayShare => 'Partager l\'app avec vos amis';

  @override
  String get supportWayBugs => 'Signaler des bugs ou suggérer des idées';

  @override
  String get supportWayEnjoy => 'Profitez simplement de la musique ! 🎵';

  @override
  String get supportMadeWithLove => 'Fait avec 💙 en Italie';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get normalSpeed => 'Normale (1×)';

  @override
  String get preservePitch => 'Préserver la tonalité';

  @override
  String get preservePitchSubtitle =>
      'Garder la tonalité originale lors du changement de vitesse';

  @override
  String get pitch => 'Tonalité';

  @override
  String get pitchPreserved => 'tonalité préservée';

  @override
  String speedTooltipWithPitch(String speed, String pitch) {
    return 'Vitesse $speed · tonalité $pitch×';
  }

  @override
  String speedTooltipPitchPreserved(String speed) {
    return 'Vitesse $speed · tonalité préservée';
  }

  @override
  String get sleepTimer => 'Minuteur de veille';

  @override
  String get sleepTimerActive => 'Minuteur de veille actif';

  @override
  String get fadeOut => 'Fondu de fin';

  @override
  String fadeOutSubtitle(int seconds) {
    return 'Baisse progressive du volume les $seconds dernières s';
  }

  @override
  String get finishCurrentSong => 'Finir le titre';

  @override
  String get finishCurrentSongSubtitle =>
      'Arrêter après la fin du morceau en cours';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerSetFor(String duration) {
    return 'Minuteur réglé sur $duration';
  }

  @override
  String get customDuration => 'Durée personnalisée...';

  @override
  String get cancelTimer => 'Annuler le minuteur';

  @override
  String get customSleepTimer => 'Minuteur personnalisé';

  @override
  String get set => 'Régler';

  @override
  String get addToPlaylistTitle => 'Ajouter à la playlist';

  @override
  String get yourPlaylistsLabel => 'Vos playlists';

  @override
  String get enableLrcLibFallback => 'Recherche LRCLIB';

  @override
  String get lrcLibFallbackSubtitle =>
      'Rechercher sur LRCLIB si les paroles manquent sur le serveur';

  @override
  String get themeSaved => 'Thème enregistré';

  @override
  String get themeUnsavedChanges => 'Changements non sauvés';

  @override
  String get themeUnsavedChangesTitle => 'Changements non sauvés';

  @override
  String get themeUnsavedChangesBody =>
      'Vous avez des modifications non enregistrées. Enregistrer ?';

  @override
  String get discard => 'Abandonner';

  @override
  String get done => 'Terminé';

  @override
  String pickColor(String label) {
    return 'Choisir $label';
  }

  @override
  String get titleStyle => 'Style du titre';

  @override
  String get artistStyle => 'Style de l\'artiste';

  @override
  String get themeActive => 'ACTIF';

  @override
  String get themeSafeMode => 'SÉCURISÉ';

  @override
  String get themeCodeMode => 'CODE';

  @override
  String get themeAnimBadge => 'ANIM';

  @override
  String themeAuthor(String author) {
    return 'par $author';
  }

  @override
  String get audioFocusDenied =>
      'Lecture impossible : le focus audio est occupé';

  @override
  String get addToLibrary => 'Ajouter à la bibliothèque';

  @override
  String get alreadyInLibrary => 'Déjà dans la bibliothèque';

  @override
  String get selectPlaylist => 'Sélectionner une playlist';

  @override
  String get endOfSong => 'Fin du morceau';

  @override
  String get autoDjOff => 'Désactivé';

  @override
  String get autoDjShuffleLibrary => 'Bibliothèque aléatoire';

  @override
  String get autoDjSimilarSongs => 'Titres similaires';

  @override
  String get autoDjSameGenre => 'Même genre';

  @override
  String get autoDjSameArtist => 'Même artiste';

  @override
  String get autoDjSmartMix => 'Mix intelligent';

  @override
  String get fetchLyricsDescription =>
      'Récupérer automatiquement les paroles via LRCLIB';

  @override
  String get activeDownloads => 'Téléchargements actifs';

  @override
  String get noDownloadsInProgress => 'Aucun téléchargement en cours';

  @override
  String get playlistDownloads => 'Téléchargements de playlists';

  @override
  String songsDownloaded(Object count) {
    return '$count morceaux téléchargés';
  }

  @override
  String get off => 'Désactivé';

  @override
  String artistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artistes',
      one: '1 artiste',
      zero: 'Aucun artiste',
    );
    return '$_temp0';
  }

  @override
  String get sortAZ => 'A → Z';

  @override
  String get sortZA => 'Z → A';

  @override
  String get sortRecent => 'Ajouté récemment';

  @override
  String get genreRock => 'Rock';

  @override
  String get genrePop => 'Pop';

  @override
  String get genreJazz => 'Jazz';

  @override
  String get genreClassical => 'Classique';

  @override
  String get genreSoundtrack => 'Bande originale';

  @override
  String get genreElectronic => 'Électronique';

  @override
  String get genreHipHop => 'Hip Hop';

  @override
  String get genreBlues => 'Blues';

  @override
  String get genreMetal => 'Metal';

  @override
  String get genreCountry => 'Country';

  @override
  String get genreReggae => 'Reggae';

  @override
  String get genreFolk => 'Folk';

  @override
  String get genreLatin => 'Latino';

  @override
  String get genreChristian => 'Chrétien';

  @override
  String get genreRnB => 'R&B';

  @override
  String get genreSoul => 'Soul';

  @override
  String get genreDisco => 'Disco';

  @override
  String get genrePunk => 'Punk';

  @override
  String get genreAmbient => 'Ambiance';

  @override
  String get genreNewAge => 'New Age';

  @override
  String get genreSka => 'Reggae/Ska';

  @override
  String get genreGospel => 'Gospel';

  @override
  String get genreTechno => 'Techno';

  @override
  String get genreTrance => 'Trance';

  @override
  String get genreHouse => 'House';

  @override
  String get genreRap => 'Rap';

  @override
  String get noNewReleases => 'Aucune nouvelle sortie';

  @override
  String get searching => 'Recherche...';

  @override
  String get searchLibraryHint => 'Rechercher dans la bibliothèque...';

  @override
  String get noPlaylistsFound => 'Aucune playlist trouvée';

  @override
  String get noDownloadedSongs => 'Aucun titre téléchargé';

  @override
  String get noDownloadedAlbums => 'Aucun album téléchargé';

  @override
  String get searchYourLibrary => 'Recherchez dans votre bibliothèque';

  @override
  String get exitApp => 'Quitter l\'app';

  @override
  String get connectionSlow => 'La connexion prend un peu de temps...';

  @override
  String get removeDownloadsTitle => 'Supprimer les téléchargements ?';

  @override
  String removeDownloadsConfirm(int count, String name) {
    return 'Supprimer les $count titres téléchargés de \"$name\" ?';
  }

  @override
  String get removeSongsTitle => 'Supprimer les titres';

  @override
  String removeSongsConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retirer $count titres de cette playlist ?',
      one: 'Retirer 1 titre de cette playlist ?',
    );
    return '$_temp0';
  }

  @override
  String get errorCopied => 'Erreur copiée dans le presse-papiers';

  @override
  String get songRemovedPlaylist => 'Titre retiré de la playlist';

  @override
  String songsRemovedPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres retirés',
      one: '1 titre retiré',
    );
    return '$_temp0 de la playlist';
  }

  @override
  String get loadingLibrary => 'Chargement de la bibliothèque...';

  @override
  String get reorderSongs => 'Réorganiser les titres';

  @override
  String get doneReordering => 'Terminé';

  @override
  String get deselectAll => 'Tout désélectionner';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get removeSelected => 'Supprimer la sélection';

  @override
  String get createPlaylistSubtitle => 'Créez une playlist pour commencer';

  @override
  String get lyricsSection => 'PAROLES';

  @override
  String get wordByWordSync => 'Synchro mot-à-mot';

  @override
  String get wordByWordSyncSubtitle =>
      'Analyse audio via Whisper AI pour un surlignage précis';

  @override
  String get whisperModel => 'Modèle Whisper';

  @override
  String get whisperModelSubtitle =>
      'Télécharger un modèle pour la reco vocale locale';

  @override
  String get whisperModelTiny => 'Tiny (~40 Mo) — Rapide';

  @override
  String get whisperModelBase => 'Base (~140 Mo) — Équilibré';

  @override
  String get whisperModelSmall => 'Small (~470 Mo) — Précis';

  @override
  String get downloadModel => 'Télécharger';

  @override
  String get downloadingModel => 'Téléchargement...';

  @override
  String get modelReady => 'Prêt';

  @override
  String get wordSyncProcessing => 'Synchronisation...';

  @override
  String get wordSyncClearCache => 'Vider le cache synchro';

  @override
  String get wordSyncClearCacheSubtitle =>
      'Supprime les marqueurs temporels stockés';

  @override
  String get wordSyncNotSupported => 'Non supporté sur cette plateforme';

  @override
  String queuedSongsForDownload(int count) {
    return '$count titres mis en file pour téléchargement…';
  }

  @override
  String get downloadedTooltip => 'Téléchargé — tap pour retirer';

  @override
  String get downloadingTooltip => 'Téléchargement — tap pour annuler';

  @override
  String get downloadPlaylist => 'Télécharger la playlist';

  @override
  String removeFromPlaylistConfirm(String title) {
    return 'Retirer \"$title\" de cette playlist ?';
  }
}
