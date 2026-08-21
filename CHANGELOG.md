# Changelog — JB Audio

All notable changes to JB Audio will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
