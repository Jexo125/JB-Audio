# 🎵 JB Audio 2.0

### Votre musique, simplement.

**JB Audio 2.0** est une évolution majeure de JB Audio, un client musical moderne développé avec Flutter. Conçu pour offrir une expérience d'écoute fluide et performante, il est compatible avec les serveurs utilisant le protocole **Subsonic** et **OpenSubsonic**, avec une optimisation particulière pour **Navidrome**.

La version 2.0 apporte une refonte profonde des performances réseau, une gestion avancée du transcodage et une expérience utilisateur stabilisée, notamment pour les réseaux mobiles instables.

---

## 🚀 Nouveautés de la Version 2.1.9
* **Corrections visuelles** : Amélioration de la Developer Card et support du mode sombre pour le dialogue du badge secret.

## 🚀 Nouveautés de la Version 2.1.8
* **Trophée « Curieux »** : Découvrez l'Easter Egg caché pour débloquer un badge spécial sur votre écran d'accueil.
* **Interface optimisée** : Résumé XP plus compact et élégant sur l'accueil.

## 🚀 Nouveautés de la Version 2.1.7

### 🎮 UX Gamification
- **Progression sur l'Accueil** : Visualisez votre niveau et XP dès l'ouverture de l'application.
- **Célébration RPG** : Vivez une expérience immersive lors de chaque montée de niveau.
- **Accès Rapide aux Quêtes** : Nouveau bouton dédié sur l'écran principal.
- **Introduction RPG** : Découvrez le système de progression via une nouvelle présentation interactive.

### 🎛️ Audio
- **Audio Ducking** : Contrôlez si la musique doit baisser lors des notifications.

---

## 🚀 Nouveautés de la Version 2.1.3

### 🎚️ Égaliseur Audio & Stabilité
- **Égaliseur Personnalisé** : Correction du réglage manuel des bandes en mode DynamicsProcessing.
- **Gestion Énergétique** : Initialisation et libération dynamiques de l'effet pour une meilleure stabilité système.
- **Restauration d'État** : Vos réglages sont désormais fidèlement conservés lors du changement de morceau ou de session.
- **Sécurité Audio** : Système de secours garantissant la continuité de la lecture en cas d'erreur du moteur natif.

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
- **Identification** : L'application s'identifie désormais comme `JB Audio` auprès du serveur.

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
- **Buffering Amélioré** : Nouvelle stratégie de "Range-buffering" (15s min / 30s max) pour stabiliser la lecture sur les réseaux mobiles instables et limiter les micro-coupures TCP tout en économisant les données.

---

## 🚀 Nouveautés de la Version 2.0.6 (Corrective)

### 🛠️ Corrections et Stabilité
- **Lecture Audio** : Correction du blocage systématique à quelques secondes de la fin des morceaux.
- **Buffering** : Rétablissement d'une marge de sécurité plus stable (30s min / 60s max) pour garantir la complétion des flux transcodés.
- **Transcodage** : Correction de la limitation de débit. Les paramètres `maxBitRate` et `format` sont désormais transmis correctement, garantissant le respect de la qualité choisie sur les serveurs Subsonic/Navidrome.
- **Recommandations** : Correction du moteur de tracking. Les écoutes successives sont désormais comptabilisées correctement sans nécessiter de redémarrage.
- **Scoring** : Amélioration du suivi de complétion des morceaux (bonus de fin) sans risque de double comptage des écoutes.
- **Interface** : Actualisation en temps réel des statistiques d'écoute dans les paramètres et du carrousel de recommandations sur l'Accueil.

---

## 🚀 Nouveautés de la Version 2.0.5

### 🧠 Système de Recommandations Personnalisées
Rétablissement complet du moteur de recommandations :
- **Intelligence Contextuelle** : Le système apprend de vos habitudes selon la règle "30 secondes ou 50%" d'écoute validée.
- **Scoring Avancé** : Prise en compte immédiate des favoris (+20% d'affinité) et des morceaux passés (skips).
- **Isolation Totale** : Vos données d'écoute sont isolées par utilisateur et par serveur (stockage local sécurisé).
- **Mise à jour en temps réel** : Les recommandations s'adaptent instantanément pendant votre session d'écoute.

### 🎨 Refonte de l'interface d'Accueil
- **Nouvelle hiérarchie** : "Lus récemment" et "Recommandé pour vous" sont désormais prioritaires en haut de l'écran.
- **Carrousels Horizontaux** : Toutes les sections utilisent désormais un défilement horizontal fluide et homogène.
- **Clarté Visuelle** : Suppression des sections redondantes ("Pour vous") et nettoyage des indications de recommandation imprécises.

### 📚 Bibliothèque & Navigation
- **Interface Épurée** : Suppression de la liste automatique "Favoris + Récents" pour une navigation plus claire.
- **Harmonisation UX** : Les boutons de navigation de la Bibliothèque utilisent désormais le même design moderne (Gradients + Icônes) et la même grille responsive que l'écran de Recherche.
- **Cohérence Design** : Composants partagés pour une expérience fluide entre la navigation et la découverte.

## 🔎 Recherche

JB Audio conserve sa fonction de **Recherche Utilisateur** spécifique et améliorée :
- Logique de formatage et de normalisation des requêtes avancée.
- Recherche hybride (locale + serveur) pour des résultats instantanés.
- **Indépendance totale** : Le mécanisme de synchronisation globale ne remplace pas la recherche utilisateur, garantissant la conservation de la pertinence des résultats validés.

---

## ✨ Fonctionnalités Standards

- ❤️ Gestion complète des favoris
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
