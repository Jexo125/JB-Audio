# 🎵 JB Audio 2.0

### Votre musique, simplement.

**JB Audio 2.0** est une évolution majeure de JB Audio, un client musical moderne développé avec Flutter. Conçu pour offrir une expérience d'écoute fluide et performante, il est compatible avec les serveurs utilisant le protocole **Subsonic** et **OpenSubsonic**, avec une optimisation particulière pour **Navidrome**.

La version 2.0 apporte une refonte profonde des performances réseau, une gestion avancée du transcodage et une expérience utilisateur stabilisée, notamment pour les réseaux mobiles instables.

---

## 🚀 Nouveautés de la Version 2.0

### 🎚️ Transcodage Navidrome / OpenSubsonic
JB Audio 2.0 intègre pleinement la négociation de transcodage pour une gestion optimale de votre bande passante :
- **Négociation Dynamique** : Utilisation de `getTranscodeDecision` pour adapter le flux aux capacités réelles du serveur.
- **Gestion de la Qualité** : Paramétrage indépendant des débits pour le WiFi et les données mobiles (Smart Transcoding).
- **Reprise de Lecture** : Modifiez la qualité pendant l'écoute ; l'application reprendra automatiquement à la position actuelle sur le nouveau flux.
- **Seeking Précis** : Navigation temporelle fiable sur les flux transcodés grâce à l'estimation de la taille du contenu.

### 🎵 Now Playing & Scrobbling
Une intégration parfaite avec votre serveur Navidrome :
- **Signalement en temps réel** : Vos morceaux apparaissent immédiatement dans l'interface "Now Playing" de Navidrome.
- **Scrobbling Natif** : Signalement précis de la lecture via `scrobble.view?submission=false`.
- **Identification** : L'application s'identifie désormais comme `JB Audio/2.0.1` auprès du serveur.

---

## ⚡ Performances Révolutionnées

La synchronisation de la bibliothèque a été intégralement repensée pour supprimer le goulot d'étranglement historique des clients Subsonic.

**Évolution de la stratégie :**
- **AVANT** : Une requête HTTP individuelle par album pour récupérer la liste des morceaux (Problème N+1).
- **APRÈS** : Récupération globale et paginée de toute la collection en quelques requêtes seulement.

**Impact technique :**
- Utilisation intensive de `search3.view` avec requête globale pour le chargement massif.
- Pagination optimisée par blocs de **500 morceaux**.
- Réduction du nombre de requêtes réseau allant jusqu'à 98% sur les grandes bibliothèques.
- Insertions SQLite optimisées par transactions groupées.

---

## 📱 Expérience Utilisateur

### Écran de première synchronisation
Lors du premier lancement ou après un vidage du cache, un nouvel écran dédié vous accompagne :
- **Déclenchement immédiat** après la connexion.
- **Affichage réel** de la progression (Artistes, Albums, Morceaux).
- **Durée de confort** de 4 secondes minimum pour garantir la compréhension des opérations en cours, même sur les serveurs ultra-rapides.

### Stabilité Réseau
- **Buffering Amélioré** : Nouvelle stratégie de "Range-buffering" (30s min / 60s max) pour stabiliser la lecture sur les réseaux mobiles instables et limiter les micro-coupures TCP.

---

## 🔎 Recherche

JB Audio conserve sa fonction de **Recherche Utilisateur** spécifique et améliorée :
- Logique de formatage et de normalisation des requêtes avancée.
- Recherche hybride (locale + serveur) pour des résultats instantanés.
- **Indépendance totale** : Le mécanisme de synchronisation globale ne remplace pas la recherche utilisateur, garantissant la conservation de la pertinence des résultats validés.

---

## ✨ Fonctionnalités Standards

- ❤️ Gestion complète des favoris (Starred)
- 📋 Création et édition de playlists
- 🎼 Affichage des paroles synchronisées (Navidrome + LRCLIB fallback)
- 📻 Stations radio internet via le serveur
- 📥 Téléchargement pour une écoute hors ligne
- 📱 Interface adaptative (Mobile, Tablette, Desktop)
- 🌙 Modes Sombre, Clair et support Material You
- 🚗 Support **Android Auto** et **Apple CarPlay**
- 📺 Support **Chromecast** et **UPnP**

---

## 🔌 Serveurs compatibles

JB Audio est compatible avec tout serveur implémentant l'API Subsonic/OpenSubsonic :
- **Navidrome** (Hautement recommandé)
- **Subsonic**
- **Airsonic / Airsonic-Advanced**
- **Gonic**
- **Jellyfin / Emby** (via leurs proxys Subsonic respectifs)

---

## 🚀 Installation et développement

### Prérequis
- Flutter SDK (dernière version stable)
- Dart SDK
- Android Studio ou VS Code

### Installer les dépendances
```bash
flutter pub get
```

### Compiler la version release
```bash
flutter build apk --release
```
