# Corrections Flutter — Zém & Taxi

## Fichiers à REMPLACER dans votre projet

| Fichier corrigé | Problème résolu |
|---|---|
| `lib/screens/conducteur/suivi_course_conducteur_screen.dart` | ❌ Import circulaire supprimé · `terminerCourse` remplacé par logique correcte |
| `lib/screens/passager/suivi_course_screen.dart` | ❌ Était une copie du screen CONDUCTEUR · Utilise maintenant `getCourseActive()` (passager) · Retourne vers `PassagerHomeScreen` |
| `lib/screens/passager/passager_home_screen.dart` | ✅ Notifications badge + navigation profil branchés |
| `lib/screens/conducteur_home_screen.dart` | ✅ Notifications badge + navigation profil branchés |
| `lib/screens/passager_home_screen.dart` | Wrapper mis à jour |
| `lib/services/profile_service.dart` | ✅ Signature `mettreAJourProfil(nom, prenom)` corrigée · endpoints sur `/profil/me` |
| `lib/services/notification_service.dart` | ✅ Méthodes d'instance (compatible profile_screen) |
| `pubspec.yaml` | ✅ `intl: ^0.19.0` ajouté |

## Fichiers NOUVEAUX à ajouter

| Fichier | Description |
|---|---|
| `lib/screens/notifications/notifications_screen.dart` | Écran liste des notifications |
| `lib/screens/profile/profile_screen.dart` | Écran profil avec photo Cloudinary |

## Flux corrigé

```
PASSAGER                          CONDUCTEUR
────────                          ──────────
Commande course                   EN LIGNE → polling
↓                                 ↓
EN_ATTENTE (banner accueil)       Voit la course → ACCEPTER
↓                                 ↓
Polling getCourseActive()  →  suivi_course_screen (PASSAGER)
       (ACCEPTEE)                 suivi_course_conducteur_screen
                                  → DÉMARRER (EN_COURS)
                                  → SIGNALER ARRIVÉE (ARRIVEE)
↓ poll détecte ARRIVEE
PaiementScreen → noter → PassagerHomeScreen
                                  ↓ poll détecte plus de course active
                                  ConducteurHomeScreen
```

## Note backend (rappel)
Si les endpoints profil sont sur `/api/v1/auth/me` et non `/api/v1/profil/me`,
changer les URLs dans `profile_service.dart` ou appliquer **Option A** du backend
(changer @RequestMapping vers `/api/v1/profil`).
