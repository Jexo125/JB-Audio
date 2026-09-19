# Ajout d'une option pour activer/désactiver la Gamification

Ce plan détaille l'ajout d'une préférence utilisateur permettant d'activer ou de désactiver les fonctionnalités de gamification (XP, niveaux, titres, quêtes) dans JB Audio, tout en préservant les données existantes.

## User Review Required

> [!IMPORTANT]
> La gamification sera **activée par défaut** pour tous les utilisateurs afin de garantir la continuité de l'expérience JB Audio 2.1.6.

## Proposed Changes

### Storage & Service Layer

#### [MODIFY] [storage_service.dart](file:///C:/Users/jeremie/AndroidStudioProjects/Musly-master/lib/services/storage_service.dart)
- Ajouter la clé `_gamificationEnabledKey = 'gamification_enabled'`.
- Implémenter `saveGamificationEnabled(bool enabled)` et `getGamificationEnabled()`.
- La valeur par défaut dans `getGamificationEnabled()` sera `true`.

#### [MODIFY] [xp_service.dart](file:///C:/Users/jeremie/AndroidStudioProjects/Musly-master/lib/services/xp_service.dart)
- Ajouter un champ `bool _isEnabled = true` et un getter `bool get isEnabled => _isEnabled`.
- Charger la valeur depuis `StorageService` dans `initialize()`.
- Ajouter `setEnabled(bool value)` qui persiste le choix et notifie les écouteurs.
- Ajouter des gardes dans `_handlePlaybackEvent`, `_handleQuestEvent`, `checkTitles` et `_processTimeAdded` pour ignorer les calculs si `isEnabled` est `false`.

#### [MODIFY] [music_quest_service.dart](file:///C:/Users/jeremie/AndroidStudioProjects/Musly-master/lib/services/music_quest_service.dart)
- Ajouter des gardes dans `_handlePlaybackEvent` et `_refreshInstances` pour suspendre les mises à jour si la gamification est désactivée (en injectant l'état depuis `XpService` ou en lisant `StorageService`).

---

### UI Layer

#### [MODIFY] [home_screen.dart](file:///C:/Users/jeremie/AndroidStudioProjects/Musly-master/lib/screens/home_screen.dart)
- Masquer `XpSummaryCard` si la gamification est désactivée.
- Masquer le bouton Quêtes (`CupertinoIcons.flag_fill`) dans la `SliverAppBar`.
- Empêcher l'appel à `GamificationIntroOverlay.showIfNeeded(context)` si désactivée.

#### [MODIFY] [library_screen.dart](file:///C:/Users/jeremie/AndroidStudioProjects/Musly-master/lib/screens/library_screen.dart)
- Masquer les entrées vers `MusicQuestsScreen` et `ProgressionScreen` si la gamification est désactivée.

#### [MODIFY] [progression_listener.dart](file:///C:/Users/jeremie/AndroidStudioProjects/Musly-master/lib/widgets/progression_listener.dart)
- Ajouter un garde dans `_onProgressionChanged` pour bloquer les célébrations de niveau et les notifications de titres si la gamification est désactivée.

#### [MODIFY] [settings_playback_tab.dart](file:///C:/Users/jeremie/AndroidStudioProjects/Musly-master/lib/screens/settings_playback_tab.dart)
- Ajouter une nouvelle `SettingsSectionCard` intitulée "Gamification".
- Inclure un interrupteur (`CupertinoSwitch`) pour activer/désactiver la fonctionnalité avec la description localisée.

---

### Localization

#### [MODIFY] [app_en.arb](file:///C:/Users/jeremie/AndroidStudioProjects/Musly-master/lib/l10n/app_en.arb) & [app_fr.arb](file:///C:/Users/jeremie/AndroidStudioProjects/Musly-master/lib/l10n/app_fr.arb)
- Ajouter les clés pour le titre de la section, le nom de l'option et la description explicative.

## Verification Plan

### Automated Tests
- Exécuter `flutter test` pour vérifier les non-régressions.
- Créer un test unitaire pour `StorageService` vérifiant la valeur par défaut `true`.

### Manual Verification
1. **Désactivation** : Vérifier que les cartes XP disparaissent de l'accueil, que le bouton quête disparaît, et qu'aucune montée de niveau n'est notifiée.
2. **Réactivation** : Vérifier que le niveau et l'XP précédents sont restaurés intacts.
3. **Persistance** : Vérifier que le réglage survit au redémarrage de l'application.
4. **Localisation** : Vérifier l'affichage correct des textes en FR et EN.
