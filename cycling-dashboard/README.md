# 🚴 Dashboard Vélo — Étape du Tour 2026

Dashboard local en Ruby/Sinatra connecté à Strava.  
Calcule CTL / ATL / TSB et envoie un rapport email hebdomadaire.

## Installation

```bash
cd cycling-dashboard
bundle install
cp .env.example .env
```

## Configuration (15 min, une seule fois)

### 1. Créer l'application Strava

1. Aller sur https://www.strava.com/settings/api
2. Créer une application (nom libre, catégorie "Other")
3. Dans **"Authorization Callback Domain"** mettre : `localhost`
4. Copier le **Client ID** et **Client Secret** dans `.env`

### 2. Configurer Gmail (pour le rapport email)

1. Aller sur https://myaccount.google.com/apppasswords
2. Créer un App Password (nom "Dashboard Vélo")
3. Copier le mot de passe 16 caractères dans `.env` → `GMAIL_APP_PASSWORD`

### 3. Remplir le `.env`

```env
STRAVA_CLIENT_ID=12345
STRAVA_CLIENT_SECRET=abc123...
GMAIL_USER=ton.email@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
REPORT_EMAIL=ton.email@gmail.com
FTP=250  # optionnel, en watts
```

## Lancer l'app

```bash
bundle exec ruby app.rb
```

Ouvrir http://localhost:4567 → cliquer "Connecter Strava" → autoriser.

## Fonctionnalités

| Feature | Description |
|---|---|
| **CTL** | Forme chronique (moyenne 42 jours) |
| **ATL** | Fatigue aiguë (moyenne 7 jours) |
| **TSB** | Fraîcheur = CTL − ATL. Objectif J-jour : +10 à +20 |
| **Graphique 60j** | Évolution CTL/ATL/TSB |
| **Résumé semaines** | 4 dernières semaines km/D+/heures |
| **Rapport email** | Bouton dans le dashboard |
| **Cache auto** | Données Strava rafraîchies toutes les 6h |

## TSS — comment c'est calculé ?

Par ordre de précision :
1. **Capteur de puissance + FTP configuré** → TSS précis (NP × IF)
2. **Suffer Score Strava** (si fréquence cardiaque enregistrée) → TSS approximé
3. **Fallback** → estimation durée × dénivelé

## Hébergement (optionnel, ~2-5€/mois)

Compatible **Render.com**, **Railway**, **Fly.io**.  
Ajouter les variables d'env dans le dashboard de l'hébergeur.  
Changer `STRAVA_REDIRECT_URI` vers l'URL de production.
