# 🚴 Cycling Dashboard — Étape du Tour 2026

Application web Ruby on Rails pour suivre sa préparation cycliste à partir des données Strava.  
Calcule et historise la **charge d'entraînement (CTL / ATL / TSB)** et envoie un **rapport hebdomadaire par email**.

![Ruby](https://img.shields.io/badge/Ruby-3.3-red) ![Rails](https://img.shields.io/badge/Rails-8.1-red) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)

---

## Fonctionnalités

- **Connexion Strava via OAuth2** — lecture seule, aucune modification sur Strava
- **Synchronisation des activités** — 180 jours d'historique importés et stockés en base PostgreSQL
- **Calcul CTL / ATL / TSB** — persisté en base, recalculé à chaque synchronisation
- **Dashboard** — compte à rebours, métriques de forme, graphique 60 jours, résumé par semaine
- **Page activités** — tableau paginé de toutes tes sorties avec TSS par ride
- **Rapport email hebdomadaire** — envoyé via Gmail SMTP en un clic

---

## Prérequis

Assure-toi d'avoir installé sur ta machine :

| Outil | Version minimum | Vérification |
|---|---|---|
| Ruby | 3.3+ | `ruby --version` |
| Bundler | 2.x | `bundler --version` |
| PostgreSQL | 14+ | `psql --version` |
| Git | — | `git --version` |

> **macOS** : le plus simple est d'installer [Homebrew](https://brew.sh) puis `brew install ruby postgresql@16`.  
> **rbenv** (recommandé pour Ruby) : `brew install rbenv` puis `rbenv install 3.3.6`.

---

## 1. Cloner le projet

```bash
git clone https://github.com/raphtml/cycling-dashboard.git
cd cycling-dashboard
```

---

## 2. Créer l'application Strava

> Durée estimée : **5 minutes**

1. Aller sur [strava.com/settings/api](https://www.strava.com/settings/api)
2. Remplir le formulaire :
   - **Application Name** : `Cycling Dashboard` (ou ce que tu veux)
   - **Category** : `Other`
   - **Club** : laisser vide
   - **Website** : `http://localhost:3000`
   - **Authorization Callback Domain** : `localhost`
3. Valider — Strava affiche ton **Client ID** et **Client Secret**
4. Garder cette page ouverte, tu en auras besoin à l'étape 4

---

## 3. Créer un App Password Gmail (pour le rapport email)

> Durée estimée : **3 minutes**  
> Nécessite d'avoir la **validation en 2 étapes** activée sur ton compte Google.

1. Aller sur [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
2. Dans "Nom de l'application" saisir : `Cycling Dashboard`
3. Cliquer **Créer**
4. Google génère un mot de passe de **16 caractères** — le copier immédiatement

---

## 4. Configurer les variables d'environnement

Copier le fichier d'exemple et le remplir :

```bash
cp .env.example .env
```

Ouvrir `.env` et compléter :

```env
# ── Strava (récupéré à l'étape 2) ────────────────────────────────────────────
STRAVA_CLIENT_ID=12345
STRAVA_CLIENT_SECRET=abc123def456...

# ── Base de données ───────────────────────────────────────────────────────────
# Laisser vide si PostgreSQL tourne en local avec l'utilisateur système (macOS par défaut)
DB_HOST=localhost
DB_USER=
DB_PASSWORD=

# ── Gmail (récupéré à l'étape 3) ─────────────────────────────────────────────
GMAIL_USER=ton.email@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
REPORT_EMAIL=ton.email@gmail.com

# ── Entraînement ──────────────────────────────────────────────────────────────
# FTP en watts — optionnel, mais améliore la précision du TSS si tu as un capteur de puissance
FTP=250

# ── Rails ─────────────────────────────────────────────────────────────────────
SECRET_KEY_BASE=
```

Générer une `SECRET_KEY_BASE` :

```bash
bin/rails secret
# Copier la valeur dans .env → SECRET_KEY_BASE=...
```

---

## 5. Installer les dépendances

```bash
bundle install
```

---

## 6. Créer et migrer la base de données

```bash
bin/rails db:create
bin/rails db:migrate
```

> Si PostgreSQL refuse la connexion, vérifier qu'il tourne bien :
> ```bash
> # macOS
> brew services start postgresql@16
> # Linux
> sudo systemctl start postgresql
> ```

---

## 7. Lancer l'application

```bash
bin/dev
```

Ouvrir [http://localhost:3000](http://localhost:3000) dans le navigateur.

---

## 8. Première utilisation

1. Cliquer **"Connecter avec Strava"**
2. Autoriser l'accès sur la page Strava (lecture seule)
3. La synchronisation démarre automatiquement — **les 180 derniers jours** d'activités sont importés
4. Le dashboard s'affiche avec CTL / ATL / TSB calculés

> La première sync peut prendre **10 à 30 secondes** selon le volume d'activités.

---

## Utilisation quotidienne

| Action | Comment |
|---|---|
| Rafraîchir les données | Bouton **↻ Sync Strava** sur le dashboard |
| Envoyer le rapport email | Bouton **📧 Rapport email** sur le dashboard |
| Voir toutes les sorties | Menu **Activités** |
| Se déconnecter | Menu en haut à droite |

---

## Comprendre CTL / ATL / TSB

| Métrique | Nom complet | Fenêtre | Interprétation |
|---|---|---|---|
| **CTL** | Chronic Training Load | 42 jours | Ta condition physique actuelle. Plus c'est haut, mieux tu es entraîné. |
| **ATL** | Acute Training Load | 7 jours | Ta fatigue récente. Baisse après une semaine de récupération. |
| **TSB** | Training Stress Balance | CTL − ATL | Ta fraîcheur du moment. |

**Objectif le jour de l'Étape du Tour : TSB entre +10 et +20.**

| TSB | Signification |
|---|---|
| > +25 | Très frais — trop peu d'entraînement récent |
| +5 à +25 | ✅ Forme optimale |
| -10 à +5 | Charge normale d'entraînement |
| -25 à -10 | Fatigué — penser à récupérer |
| < -25 | Surcharge — repos obligatoire |

### Comment le TSS est calculé

Par ordre de précision décroissante :

1. **Capteur de puissance + FTP configuré** → formule TSS officielle (NP × IF × durée)
2. **Suffer Score Strava** (si fréquence cardiaque enregistrée) → approximation HR-based
3. **Fallback** → estimation sur la durée et le dénivelé de la sortie

---

## Architecture

```
app/
├── controllers/
│   ├── sessions_controller.rb      # OAuth Strava (login / callback / logout)
│   ├── dashboard_controller.rb     # Dashboard principal + sync
│   ├── activities_controller.rb    # Liste paginée des activités
│   └── reports_controller.rb       # Envoi email
│
├── models/
│   ├── athlete.rb                  # Profil + tokens OAuth
│   ├── activity.rb                 # Sorties Strava (données brutes)
│   └── daily_load.rb               # CTL / ATL / TSB par jour (calculé)
│
├── services/
│   ├── strava_api.rb               # Client API Strava + gestion token refresh
│   ├── activity_sync_service.rb    # Import et upsert des activités depuis Strava
│   ├── training_load_service.rb    # Calcul CTL/ATL/TSB et persistance en base
│   └── tss_calculator.rb           # Calcul du TSS par activité
│
└── mailers/
    └── weekly_report_mailer.rb     # Rapport hebdomadaire Gmail

db/migrate/
├── create_athletes                 # Profil + tokens
├── create_activities               # Toutes les données Strava par sortie
└── create_daily_loads              # Historique CTL/ATL/TSB
```

---

## Variables d'environnement — référence complète

| Variable | Obligatoire | Description |
|---|---|---|
| `STRAVA_CLIENT_ID` | ✅ | ID de ton application Strava |
| `STRAVA_CLIENT_SECRET` | ✅ | Secret de ton application Strava |
| `SECRET_KEY_BASE` | ✅ | Clé de chiffrement des sessions Rails (`bin/rails secret`) |
| `DB_HOST` | ✅ | Hôte PostgreSQL (défaut : `localhost`) |
| `DB_USER` | — | Utilisateur PostgreSQL (vide = user système) |
| `DB_PASSWORD` | — | Mot de passe PostgreSQL |
| `GMAIL_USER` | — | Adresse Gmail pour l'envoi des rapports |
| `GMAIL_APP_PASSWORD` | — | App Password Google (16 caractères) |
| `REPORT_EMAIL` | — | Adresse destinataire du rapport hebdomadaire |
| `FTP` | — | FTP en watts pour le calcul précis du TSS |

---

## Hébergement (optionnel)

L'application est compatible avec les hébergeurs suivants pour quelques euros par mois :

- **[Render.com](https://render.com)** — plan Starter ~7$/mois, PostgreSQL inclus
- **[Railway.app](https://railway.app)** — facturation à l'usage, ~5$/mois
- **[Fly.io](https://fly.io)** — plan gratuit limité disponible

Dans tous les cas, penser à :
- Ajouter toutes les variables d'environnement dans le dashboard de l'hébergeur
- Changer `STRAVA_REDIRECT_URI` vers l'URL de production dans l'app Strava

---

## Dépendances principales

| Gem | Rôle |
|---|---|
| `rails 8.1` | Framework web |
| `pg` | Adaptateur PostgreSQL |
| `faraday` | Client HTTP pour l'API Strava |
| `chartkick` | Graphiques CTL/ATL/TSB |
| `kaminari` | Pagination des activités |
| `tailwindcss-rails` | CSS |
| `dotenv-rails` | Variables d'environnement |
| `hotwire` (turbo + stimulus) | Navigation sans rechargement |
