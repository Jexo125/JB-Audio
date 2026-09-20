# Changelog — JB Audio

All notable changes to JB Audio will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.8] - 2026-09-14

### 🏆 Easter Egg & Badge
* Trophée/badge « Curieux » affiché à côté du nom sur l'accueil après déblocage.
* Nouvelle présentation visuelle de l'Easter Egg avec une animation plein écran immersive.
* Persistance du badge débloqué indépendamment de la Gamification.
* Présentation du badge accessible en cliquant sur le trophée de l'accueil.
* Mise à jour de la Developer Card (« JB Audio » / « Créé avec ❤️ »).

### ✨ Interface
* XpSummaryCard compactée d'environ 20 % pour un gain d'espace sur l'accueil.
* Toutes les informations de progression (XP, niveaux) sont conservées et lisibles.
* Localisation française et anglaise mise à jour.

## [2.1.7] - 2026-09-14

### 🎮 Gamification configurable
* Nouvelle option permettant d'activer ou désactiver complètement la Gamification.
* Gamification activée par défaut pour conserver le comportement des utilisateurs existants.
* Possibilité d'utiliser JB Audio comme lecteur musical classique sans XP, niveaux, titres, quêtes ou éléments RPG.
* Désactivation de la couche Gamification sans désactiver l'historique d'écoute, les statistiques générales ou les recommandations.
* Progression Gamification entièrement conservée lorsque la fonctionnalité est désactivée.
* Réactivation permettant de retrouver la progression existante.
* Préférence persistante entre les sessions.
* Interface Gamification automatiquement masquée lorsqu'elle est désactivée.
* Localisation française et anglaise.

## [2.1.6] - 2026-09-14

### 🎛️ Audio
* Audio Ducking configurable : diminution automatique du volume lors des notifications système (activable/désactivable dans les paramètres).

### ✨ Gamification UX
* Résumé XP sur l'accueil : affichage direct du niveau et de la progression sous le message de bienvenue.
* Barre de progression animée sur l'accueil pour un suivi visuel fluide de l'XP.
* Accès direct aux Quêtes depuis la barre supérieure de l'accueil.
* Célébration RPG : nouvelle animation immersive lors des montées de niveau.
* Présentation RPG : introduction pédagogique du système de gamification pour les nouveaux utilisateurs et lors des mises à jour majeures.
* Persistance versionnée de l'introduction pour garantir que chaque utilisateur reçoive les informations importantes une seule fois.

## [2.1.5] - 2026-09-13

### ✨ Gamification
* Introduction du système de progression (XP et Niveaux).
* Ajout des titres et milestones débloquables ("Mélomane", "Explorateur", etc.).
* Intégration du Dashboard "Ma Progression" dans la bibliothèque.
* Notifications en temps réel pour les montées de niveau et déblocages de titres.
* Persistance atomique des données de progression via SQLite V6.

## [2.1.4] - 2026-09-12

### 🎛️ Audio
* Correction de l’activation explicite de la session audio Android.
* Amélioration de la compatibilité audio avec certains appareils Android.

## [2.1.3] - 2026-09-12

### 🎛️ Audio
* Correction de l'égaliseur personnalisé sur Android avec DynamicsProcessing.
* Initialisation paresseuse (lazy) de DynamicsProcessing uniquement lorsque l'égaliseur est activé.
* Libération de l'effet audio lorsque l'égaliseur est désactivé pour éviter les conflits matériels.
* Conservation et restauration des réglages de l'égaliseur lors des changements de session audio.
* Fallback sécurisé permettant de poursuivre la lecture sans égaliseur si DynamicsProcessing ne peut pas être initialisé.

## [2.1.2] - 2026-09-12

### 🎛️ Audio
* Correction de l'accès à l'égaliseur sur les appareils Android utilisant le moteur DynamicsProcessing (Android API 28+).
* L'interface de l'égaliseur reconnaît désormais correctement le nouveau moteur et affiche fidèlement ses 5 bandes de fréquences.

## [2.1.1] - 2026-09-12

### 🎛️ Audio
* Optimisation de l'architecture audio pour garantir l'exclusion mutuelle entre les moteurs d'égalisation.
* Sur Android 9+ (API 28+), seul le moteur DynamicsProcessing est désormais utilisé pour une stabilité maximale.
* Maintien du moteur AndroidEqualizer comme solution de secours (fallback) sur les versions antérieures d'Android.

## [2.1.0] - 2026-09-07

### 🎛️ Audio
* Migration de l'égaliseur Android vers une architecture native basée sur DynamicsProcessing pour les appareils Android compatibles.
* Ajout d'un préampli global indépendant avec réglage de -12 dB à +12 dB.
* Amélioration du contrôle des bandes de fréquences avec un réglage précis par pas de 0,5 dB.
* Ajout d'une gestion native du traitement audio avec limitation de niveau et bypass réel de l'égaliseur.
* Conservation d'un fallback AndroidEqualizer pour les versions d'Android ne prenant pas en charge DynamicsProcessing.

## [2.0.10] - 2026-09-07

### 🎛️ Audio
* Correction de l’affichage des valeurs de l’égaliseur Android pour garantir l’affichage fidèle des gains réels des presets et des réglages personnalisés.
* Amélioration de la précision et de la cohérence des réglages de l’égaliseur.

## [2.0.9] - 2026-09-06

### 🎛️ Audio
* Correction définitive de l’égaliseur Android : architecture additive, suppression de la baisse de volume automatique et réglage haute précision.
* Nouveau préampli global bidirectionnel (-12.0 dB à +12.0 dB).

## [2.0.8] - 2026-09-06

### 🎨 Interface
* Amélioration visuelle de la carte développeur avec un liseré Rainbow animé.

## [2.0.7] - 2026-09-06

### 🎚️ Égaliseur
* Ajout d'un égaliseur audio natif Android.
* Ajout de plusieurs presets audio.
* Ajout du réglage manuel des bandes.
* Conservation des réglages de l'égaliseur.

### 🎵 Lecture
* Correction du blocage qui pouvait survenir quelques secondes avant la fin d'un morceau.
* Stabilisation du buffering audio.

### 🧠 Recommandations
* Correction du suivi des écoutes.
* Prise en compte de plusieurs morceaux écoutés.
* Prise en compte de la fin réelle d'un morceau.
* Mise à jour des recommandations en temps réel.

### 📡 Transcodage
* Amélioration de la gestion du transcodage bas débit.
* Transmission correcte de `maxBitRate` et `format` au serveur.

### 🔄 Mises à jour
* Amélioration de l'affichage des Release Notes dans la fenêtre de mise à jour.
* Les nouveautés de la version sont désormais récupérées automatiquement depuis la GitHub Release.

### 🎨 Interface
* Amélioration visuelle de la carte développeur avec un liseré Rainbow animé.

## [2.0.6] - 2026-08-25

### 🚀 Correctifs
- **Lecture Audio** : Correction du blocage systématique à quelques secondes de la fin des morceaux.
- **Buffering** : Rétablissement d'une marge de sécurité plus stable (30s min / 60s max) pour garantir la complétion des flux transcodés.
- **Transcodage** : Correction de la limitation de débit. Les paramètres `maxBitRate` et `format` sont désormais transmis correctement.
- **Recommandations** : Correction du moteur de tracking. Les écoutes successives sont désormais comptabilisées correctement.
- **Scoring** : Amélioration du suivi de complétion des morceaux.
- **Interface** : Actualisation en temps réel des statistiques d'écoute et du carrousel de recommandations.

## [2.0.5] - 2026-08-25

### 🧠 Recommandations
- **Système de Recommandations Personnalisées** : Rétablissement complet du moteur apprenant de vos habitudes.
- **Scoring Avancé** : Prise en compte des favoris et des morceaux passés.

### 🎨 Interface
- **Refonte de l'Accueil** : Priorisation des sections "Lus récemment" et "Recommandé pour vous".
- **Carrousels Horizontaux** : Défilement fluide et homogène.

### 📚 Bibliothèque
- **Interface Épurée** : Suppression de la liste "Favoris + Récents" pour plus de clarté.
- **Harmonisation UX** : Design moderne avec Gradients + Icônes.

## [2.0.4] - 2026-08-25

### 🚀 Nouvelles fonctionnalités
- **Recommandations** : Système de recommandations personnalisées sur l'accueil via un nouveau carrousel d'albums.
- **Intelligence** : Recommandations basées sur l'historique d'écoute, les artistes et genres appréciés, avec diversification automatique.
- **Multi-utilisateur** : Isolation complète des données de recommandations par utilisateur et par serveur.
- **Avance/Recul rapide** : Support de l'avance et du recul rapide dans le lecteur principal (appui long) et le mini-lecteur (configurable).
- **Interface** : Design responsive et localisation intégrale FR/EN.

### 📈 Améliorations
- **Découverte** : Amélioration globale de l'expérience de découverte musicale locale.
- **Stabilité** : Conservation des optimisations de buffering (30s/60s/3MiB) et de transcodage (`estimateContentLength`).

## [2.0.3] - 2026-08-25 — Version corrective

### 🚀 Correctifs
- **Buffering** : Correction du buffering des flux transcodés.
- **ExoPlayer** : Amélioration de la gestion du préchargement et réduction du téléchargement excessif des morceaux transcodés sur les connexions mobiles.

## [2.0.2] - 2026-08-21 — Version corrective

### 🚀 Correctifs
- **File de lecture** : Correction définitive de l'affichage des pochettes grises dans la liste "À suivre".
- **Bibliothèque** : Correction du chargement lent ou bloqué des pochettes dans l'écran principal de la bibliothèque.
- **Stabilité du Cache** : Stabilisation des URLs d'images via `AlbumArtwork` pour éviter les annulations de téléchargement lors des rafraîchissements de l'interface.

## [2.0.1] - 2026-08-21 — Version corrective (Intermédiaire)
- Travaux préparatoires pour la stabilisation des images.

## [2.0.0] - 2026-08-21 — Première version majeure

### 🚀 Lecture et transcodage
- **Négociation OpenSubsonic** : Implémentation complète de `getTranscodeDecision` pour une gestion optimale des flux.
- **Transcode Params** : Support des paramètres de transcodage natifs Navidrome.
- **Changement de qualité à chaud** : Modification du débit (64kbps, 128kbps, etc.) pendant la lecture avec reprise à la position actuelle.
- **Seeking sur flux transcodés** : Correction de la navigation temporelle via `estimateContentLength=true`.
- **Buffering optimisé** : Passage à une stratégie de "Range-buffering" (30s min / 60s max) pour stabiliser la lecture sur les réseaux mobiles instables.

### 🎵 Navidrome — Now Playing
- **Intégration de Session** : Signalement correct des morceaux en lecture pour une visibilité immédiate dans l'interface serveur.
- **Scrobble.view** : Utilisation de l'endpoint avec `submission=false` pour le Now Playing.
- **User-Agent** : Identification unique de l'application en tant que `JB Audio/2.0.0`.

### ⚡ Synchronisation de bibliothèque
- **Suppression du problème N+1** : Remplacement du chargement itératif par une récupération globale massive.
- **Bulk Loading** : Utilisation de `search3.view` avec requête vide pour le téléchargement des métadonnées.
- **Pagination** : Récupération par blocs de 500 morceaux pour un équilibre optimal performance/mémoire.
- **Transactions SQLite** : Écritures groupées pour accélérer le peuplement de la base locale.

**Évolution visuelle :**
- **AVANT** : Album → morceaux album par album (Lent)
- **APRÈS** : Bibliothèque → récupération globale → pagination → SQLite par lots (Instanté)

### 📊 Progression de synchronisation
- **Nouvel écran de progression** : Interface dédiée s'affichant immédiatement lors de la première synchronisation.
- **Données réelles** : Affichage des compteurs réels d'artistes, d'albums et de morceaux en direct.
- **Confort visuel** : Durée minimale d'affichage de 4 secondes pour une transition fluide vers la bibliothèque.

### 🔎 Recherche
- **Indépendance** : Conservation de la logique de recherche utilisateur (formatage, normalisation), isolée du nouveau mécanisme de synchronisation.

### 🛠️ Architecture et stabilité
- **Nouveaux modèles** : `SyncProgress`, `BulkSyncResult`.
- **Auth sécurisée** : Authentification par Token + Salt par défaut.
- **Général** : Amélioration de la résilience aux erreurs réseau lors des phases de synchronisation.

---

## [1.0.13] - 2026-05-10

### Added

- **Now Playing Custom Themes** — Complete theme system for personalizing the Now Playing screen
  - Theme manager screen with create, edit, duplicate, export/import, and delete
  - 5 editor tabs: Background, Artwork, Text, Controls, Animations
  - Background types: Solid color, Gradient, Blur, Mesh gradient, Custom Flutter code (with safe mode)
  - Artwork shapes: Circle, Rounded Rectangle (fixed Musly default 12 px radius), Square (configurable corner radius 0–50 px)
  - Shadow intensity, rotation, and size factor controls
  - Cover rotation animation with configurable speed (3–60 seconds per full turn)
  - Pulse effect animation for artwork
  - Text styling for title, artist, album, and duration (font family, color, size, weight)
  - Control styling (color, size, spacing) and progress bar styling (color, height, shape)
  - Real-time animated preview in theme cards
  - All themes persisted to disk and survive app restarts

- **Gapless Playback** — Seamless track-to-track transitions via `ConcatenatingAudioSource`
  - Toggle in Playback settings to enable/disable
  - Preloads next track for instant switching

- **LRCLIB Lyrics Fallback** — Automatic lyrics lookup from LRCLIB when the Subsonic server has no lyrics
  - Toggle in Playback settings
  - Searches by song title and artist name

### Fixed

- **Playback Resume After App Restart** — Correctly restores playback position and prepares the audio source after cold start ([#171](https://github.com/dddevid/Musly/issues/171))
- **Seek with Transcoding** — Fixed broken seeking when using transcoding via `LockCachingAudioSource` ([#170](https://github.com/dddevid/Musly/issues/170))
- **Jukebox Mode UI** — Jukebox controls now properly integrated into the main playback controls ([#173](https://github.com/dddevid/Musly/issues/173))
- **Cache Memory Optimization** — Replaced JSON bulk cache with SQLite to prevent OOM crashes on libraries with 100 000+ items
- **iOS Deployment Target** — Lowered minimum iOS version from 16.1 back to 15.0 (removes Live Activities dependency on iOS)
- **Theme Editor Overflow** — Fixed all `RenderFlex` overflow errors in `ThemePreviewCard` and `ThemeEditorScreen`
- **Theme Editor Layout** — Removed unwanted leading whitespace from `TabBar` in `ThemeEditorScreen`
- **Duplicate Theme Dialog** — Fixed `_dependents.isEmpty` assertion crash when cancelling or swiping away the duplicate dialog
- **Export Theme on Mobile** — `FilePicker.saveFile` now correctly passes `bytes` on Android & iOS, resolving "invalid argument(s): Bytes are required"
- **Rotation Animation State** — Cover rotation animation now pauses when playback stops and resumes when it starts

### Changed

- **Library Cache Backend** — JSON bulk cache replaced by SQLite for significantly lower memory usage on large libraries
- **Theme Strings** — All hardcoded UI strings in the theme editor and preview card moved to ARB localization keys
- **PlayerProvider Lifecycle** — Debounce timer for queue persistence is now cancelled in `dispose()` to avoid timer leaks in tests

## [1.0.12] - 2026-05-09

### Added
- **Persistent Queue Across Restarts** ([#156](https://github.com/dddevid/Musly/issues/156))
  - Queue state (songs, current index, current song ID) saved to SharedPreferences
  - Automatically restores queue on app launch without auto-playing
  - Validates local file paths exist before restoring
  - Debounced save (200ms) to avoid excessive writes
  - Clears persisted data on explicit queue clear
- **Shuffle Persistence** — Shuffled queue order is now persisted alongside the queue, so reopening the app restores the correct shuffled sequence when shuffle mode is enabled
- **Artist Play Enhancement** ([#151](https://github.com/dddevid/Musly/pull/151))
  - "Play" button on artist screens now appends rest of artist's songs to their top songs
  - Provides fuller artist experience when pressing play
- **Collapsible Playlist Cover Art** — `PlaylistScreen` now uses a `SliverAppBar` with `FlexibleSpaceBar`, matching the collapsible behavior of `AlbumScreen`
- **All Songs Entry Restored** — "All Songs" tile added back to Library → Faves tab for quick access to the full song list
- **Comprehensive Test Suite** — Unit, widget, integration, security, and memory-leak tests with configurable Navidrome server support via `test_server_config.json`
- **Android Audio Session Configuration** — Explicit `AudioSession` setup for music playback on Android, ensuring proper audio focus and routing on car head units
- **Lyrics Wake Lock** — Screen stays on while lyrics view is visible to prevent display timeout during active listening
- **Spotify-Style Desktop UX Redesign** — Complete overhaul of desktop interface emulating Spotify's design system
  - **3-Column Layout**: Fixed left sidebar (280px), expandable center content area, optional right sidebar (320px) for queue
  - **Spotify-like Dark Mode**: Deep black backgrounds (#000000, #121212, #181818) with consistent color palette
  - **Right Sidebar Queue**: Dedicated sidebar showing current playback queue with song artwork and metadata
  - **Enhanced Player Bar**: Improved 90px fixed bottom bar with Spotify color scheme (#181818) and border (#282828)
  - **Micro-Interactions**: Smooth hover effects on all cards (1.04x scale, 16px elevation shadow, 200ms animations)
  - **Green Play Button**: Spotify-signature green (#1DB954) circular play button appears on hover for albums and artists
  - **Quick Access Grid**: Spotify-style quick access tiles with hover states and background transitions
  - **Gradient Header Widget**: Dynamic gradient headers that extract dominant colors from album artwork
  - **Updated Navigation Sidebar**: 280px width (expanded) with improved Spotify-like colors and hover states
  - **New Widgets**: `SpotifyLikeCard`, `RightSidebar`, `QuickAccessGrid`, `GradientHeader` for reusable Spotify-style components

### Fixed
- **History Screen Loading** - Improved history loading and listener management
- **Library Refresh** ([#152](https://github.com/dddevid/Musly/issues/152))
  - Refresh button now forces full re-sync by bypassing 6-hour cooldown
  - Fixes stale library content after user clicks refresh
- **Accent Color Consistency** ([#158](https://github.com/dddevid/Musly/issues/158))
  - Play/Shuffle buttons now use theme accent color instead of hardcoded red
  - Applied to album, artist, and playlist screens
- **Emby/Jellyfin Library Sync** ([#160](https://github.com/dddevid/Musly/issues/160))
  - Added `getAllSongs()` to JellyfinService for O(1) API call
  - SubsonicService proxy for Jellyfin compatibility
  - Fixed albumId and artistId fallbacks in item parsing
  - Fixed pagination loop early-break issue
- **Play/Shuffle Button Design** ([#157](https://github.com/dddevid/Musly/issues/157))
  - Consistent pill-shaped design across artist, album, and playlist screens
  - Play/Shuffle row added below artist header
- **Now Playing Screen**
  - Replaced AnimatedMeshGradient with reliable radial gradient blobs
  - Fixed lyrics scroll-to-current when ListView items are unbuilt
  - Added lyrics slide-up/fade transition
  - Fixed ReorderableListView null crash with drag handle
  - Fixed syntax error causing build failure in `_buildRadioPlayer`
  - Status-bar icons now forced to white on dark background so they remain visible
- **Apple Music-Style Sliders** — Progress and volume bars redesigned with Apple Music aesthetics
  - Invisible thumb on mobile that grows to 28px with smooth animation when dragged
  - Track height animates from 3px to 5px during interaction with white glow effect
  - Desktop: thinner 3px tracks, smaller 5px thumbs, darker inactive track (#3A3A3A)
  - All transitions use 150ms easeOut curves for fluid micro-interactions
- **Android Audio Focus** — Playback now requests audio focus before starting, resolving no-sound issues on Android car head units and during remote playback
- **Android Playback Fix** — Resolved conflict between custom `AndroidSystemPlugin` and `audio_session` plugin that caused songs to start then immediately pause on Android devices
- **Windows Progress Bar** — Added fallback position polling timer for Windows desktop where `just_audio_windows` position stream does not emit reliably; progress bar and SMTC now update correctly during playback
- **Queue Layout** — Prevented queue list from sliding under the navigation bar on devices with gesture navigation
- **All Songs Screen** — Deferred `_loadCachedData` to post-frame callback, eliminating `setState during build` exception
- **Native Service Resilience** — `AuthProvider.logout()`, `PlayerProvider.dispose()`, `DiscordRpcService`, `WindowsSystemService`, and Android system services now gracefully handle missing native plugins in test environments
- **Local Files UX**
  - Folder cover art fallback
  - Smart sorting with genre/year filters
  - Added Radio Stations to mobile Library screen
- **Localization** - Updated l10n keys for empty states and scan actions

### Changed
- **Android Build** - Bumped version to 1.0.12+1 for update support ([#148](https://github.com/dddevid/Musly/issues/148))
- **MusicService** - Cleaned up comments and streamlined code
- **Artwork Loading** - Optimized loading and metadata updates in MusicService
- **Recommendation Service** - Enhanced with improved data handling and caching
