# Analyse Détaillée - Exercice 3 : Mattermost + PostgreSQL

## Vue d'Ensemble

**Objectif** : Déboguer une stack Mattermost (plateforme de messagerie collaborative) avec PostgreSQL.

**Complexité** : Niveau Intermédiaire

**Services** : 
- Mattermost Team Edition (latest)
- PostgreSQL 13
- 5 volumes persistants

**Bugs Identifiés** : 10 problèmes critiques et de sécurité

---

## 🐛 Bug #1 : Version Docker Compose Obsolète

### Symptômes
```yaml
version: '3.8'
```
- Warning lors de `docker compose up`
- Syntaxe obsolète depuis Docker Compose v2

### Diagnostic
La directive `version` est dépréciée depuis Docker Compose v2.0+ et génère des avertissements inutiles.

### Solution
**SUPPRIMER** complètement la ligne `version: '3.8'`

### Références
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- Version directive removed in Compose v2

---

## 🐛 Bug #2 : Absence de Réseau Dédié

### Symptômes
```yaml
services:
  mattermost:
    # Pas de configuration réseau
  postgres:
    # Pas de configuration réseau
```
- Services sur le réseau bridge par défaut
- Pas d'isolation réseau
- Mauvaise pratique de sécurité

### Diagnostic
Sans réseau personnalisé, tous les conteneurs du même hôte Docker peuvent communiquer entre eux, créant un risque de sécurité.

### Solution
```yaml
networks:
  mattermost-network:
    driver: bridge

services:
  postgres:
    networks:
      - mattermost-network
  mattermost:
    networks:
      - mattermost-network
```

### Impact
- ✅ Isolation réseau
- ✅ Communication sécurisée
- ✅ Meilleure gestion des services

---

## 🐛 Bug #3 : Pas de Health Check PostgreSQL

### Symptômes
```yaml
postgres:
  image: postgres:13
  # Pas de healthcheck
```
- Mattermost démarre avant que PostgreSQL soit prêt
- Erreurs de connexion au démarrage
- `connection refused` dans les logs

### Diagnostic
PostgreSQL met du temps à initialiser la base de données. Sans health check, Mattermost tente de se connecter trop tôt.

### Solution
```yaml
postgres:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 30s
```

### Explication
- `pg_isready` : Commande PostgreSQL pour vérifier l'état
- `interval: 10s` : Vérification toutes les 10 secondes
- `start_period: 30s` : Temps d'initialisation avant les checks
- `retries: 5` : 5 tentatives avant échec

---

## 🐛 Bug #4 : Pas de Health Check Mattermost

### Symptômes
```yaml
mattermost:
  image: mattermost/mattermost-team-edition:latest
  # Pas de healthcheck
```
- Impossible de vérifier si Mattermost est opérationnel
- Service peut être marqué "up" mais non fonctionnel

### Diagnostic
Mattermost met du temps à démarrer (chargement des plugins, connexion DB, migration). Un health check permet de valider que l'API est accessible.

### Solution
```yaml
mattermost:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8065/api/v4/system/ping"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s
```

### Explication
- Endpoint `/api/v4/system/ping` : API health check de Mattermost
- `start_period: 60s` : Temps nécessaire pour l'initialisation complète
- `curl -f` : Fail on HTTP errors (4xx, 5xx)

---

## 🐛 Bug #5 : depends_on Simple Sans Condition

### Symptômes
```yaml
mattermost:
  depends_on:
    - postgres  # Simple dependency
```
- Mattermost démarre dès que le conteneur PostgreSQL est créé
- Ne attend pas que PostgreSQL soit PRÊT
- Erreurs de connexion au démarrage

### Diagnostic
`depends_on` simple démarre les conteneurs dans l'ordre mais n'attend pas que le service soit prêt. Il faut utiliser `condition: service_healthy`.

### Solution
```yaml
mattermost:
  depends_on:
    postgres:
      condition: service_healthy
```

### Impact
- ✅ Mattermost attend que PostgreSQL soit 100% opérationnel
- ✅ Pas d'erreurs de connexion au démarrage
- ✅ Démarrage fiable et reproductible

---

## 🐛 Bug #6 : Credentials Hardcodés dans la Datasource

### Symptômes
```yaml
environment:
  - MM_SQLSETTINGS_DATASOURCE=postgres://mattermost:password@postgres:5432/mattermost
```
- Mot de passe `password` en clair dans le YAML
- Pas de flexibilité de configuration
- **RISQUE DE SÉCURITÉ CRITIQUE**

### Diagnostic
Les credentials sont hardcodés dans le fichier docker-compose, visible dans Git et non modifiable sans éditer le YAML.

### Solution
```yaml
environment:
  - MM_SQLSETTINGS_DATASOURCE=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable&connect_timeout=10
```

Avec fichier `.env` :
```bash
POSTGRES_USER=mattermost
POSTGRES_PASSWORD=mattermost_secure_password_123
POSTGRES_DB=mattermost
```

### Impact
- ✅ Credentials dans .env (protégé par .gitignore)
- ✅ Configuration flexible selon l'environnement
- ✅ Sécurité renforcée

---

## 🐛 Bug #7 : Port Hardcodé

### Symptômes
```yaml
ports:
  - "8065:8065"  # Port hardcodé
```
- Impossible de changer le port sans éditer le YAML
- Conflit potentiel si le port 8065 est déjà utilisé

### Diagnostic
Le port d'exposition devrait être configurable via variable d'environnement pour permettre plusieurs instances ou éviter les conflits.

### Solution
```yaml
ports:
  - "${MATTERMOST_PORT}:8065"
```

Avec `.env` :
```bash
MATTERMOST_PORT=8065
```

### Flexibilité
Permet de lancer plusieurs instances :
```bash
MATTERMOST_PORT=8066 docker compose up
```

---

## 🐛 Bug #8 : Pas de Restart Policy

### Symptômes
```yaml
postgres:
  image: postgres:13
  # Pas de restart
mattermost:
  image: mattermost/mattermost-team-edition:latest
  # Pas de restart
```
- Services ne redémarrent pas après un crash
- Pas de reprise automatique après reboot serveur

### Diagnostic
En production, les conteneurs doivent redémarrer automatiquement en cas de problème (crash, erreur, reboot).

### Solution
```yaml
postgres:
  restart: unless-stopped
mattermost:
  restart: unless-stopped
```

### Options de restart
- `no` : Jamais (défaut)
- `always` : Toujours
- `on-failure` : Uniquement sur erreur
- `unless-stopped` : Sauf si arrêté manuellement (RECOMMANDÉ)

---

## 🐛 Bug #9 : Connection String Simplifiée

### Symptômes
```yaml
MM_SQLSETTINGS_DATASOURCE=postgres://mattermost:password@postgres:5432/mattermost
```
- Pas de paramètres SSL
- Pas de timeout de connexion
- Configuration minimale

### Diagnostic
La connection string devrait inclure des paramètres pour gérer le SSL et les timeouts, notamment pour éviter les blocages au démarrage.

### Solution
```yaml
MM_SQLSETTINGS_DATASOURCE=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable&connect_timeout=10
```

### Paramètres Ajoutés
- `sslmode=disable` : Désactive SSL (OK pour développement local)
- `connect_timeout=10` : Timeout de 10 secondes pour la connexion

### Note
En production, utiliser `sslmode=require` avec certificats.

---

## 🐛 Bug #10 : Volume mattermost_config Manquant

### Symptômes
```yaml
volumes:
  - mattermost_data:/mattermost/data
  - mattermost_logs:/mattermost/logs
  - mattermost_plugins:/mattermost/plugins
  # Pas de volume pour /mattermost/config
```
- Configuration Mattermost non persistante
- Perte de configuration après `docker compose down -v`

### Diagnostic
Le répertoire `/mattermost/config` contient le fichier `config.json` avec toutes les configurations de Mattermost. Sans volume, la configuration est perdue.

### Solution
```yaml
volumes:
  - mattermost_data:/mattermost/data
  - mattermost_logs:/mattermost/logs
  - mattermost_plugins:/mattermost/plugins
  - mattermost_config:/mattermost/config  # ✅ AJOUTÉ
```

Déclarer le volume :
```yaml
volumes:
  mattermost_config:
    driver: local
```

### Impact
- ✅ Configuration persistante
- ✅ Survit aux redémarrages
- ✅ Sauvegarde possible de config.json

---

## 📊 Résumé des Corrections

| Bug | Catégorie | Gravité | Impact |
|-----|-----------|---------|--------|
| #1 - Version obsolète | Syntaxe | ⚠️ Moyenne | Warnings |
| #2 - Pas de réseau | Sécurité | 🔴 Haute | Isolation |
| #3 - Health check PostgreSQL | Fiabilité | 🔴 Haute | Erreurs démarrage |
| #4 - Health check Mattermost | Fiabilité | ⚠️ Moyenne | Monitoring |
| #5 - depends_on simple | Fiabilité | 🔴 Haute | Erreurs connexion |
| #6 - Credentials hardcodés | Sécurité | 🔴 CRITIQUE | Fuite credentials |
| #7 - Port hardcodé | Configuration | ⚠️ Moyenne | Flexibilité |
| #8 - Pas de restart | Production | 🔴 Haute | Disponibilité |
| #9 - Connection string | Configuration | ⚠️ Moyenne | Robustesse |
| #10 - Volume config | Persistance | ⚠️ Moyenne | Perte config |

### Statistiques
- **Total bugs** : 10
- **Critiques** : 1 (credentials)
- **Hautes** : 4 (réseau, health checks, depends_on, restart)
- **Moyennes** : 5 (version, health check Mattermost, port, connection, volume)

### Améliorations Apportées
1. ✅ Suppression directive obsolète
2. ✅ Isolation réseau avec bridge personnalisé
3. ✅ Health checks PostgreSQL et Mattermost
4. ✅ Dépendance conditionnelle (service_healthy)
5. ✅ Variables d'environnement pour credentials
6. ✅ Port configurable via .env
7. ✅ Restart policy `unless-stopped`
8. ✅ Connection string complète avec paramètres
9. ✅ Volume config ajouté
10. ✅ Nommage des conteneurs pour clarté

---

## 🎯 Points Clés

### Pour Mattermost
- **Health check obligatoire** sur `/api/v4/system/ping`
- **Start period de 60s** pour l'initialisation
- **4 volumes** nécessaires (data, logs, plugins, config)
- **Variables MM_*** pour configuration

### Pour PostgreSQL
- **Health check avec pg_isready**
- **Start period de 30s** pour la DB
- **Variables POSTGRES_*** standard

### Bonnes Pratiques
- Toujours utiliser `condition: service_healthy`
- Protéger les credentials avec .env + .gitignore
- Ajouter restart policies en production
- Isoler les services avec networks
- Nommer les conteneurs explicitement

---

## 🚀 Validation

Pour valider les corrections, exécuter le script de test :

```bash
cd exercice-3-mattermost
chmod +x test.sh
./test.sh
```

Le script vérifie :
- ✅ Structure des fichiers
- ✅ Syntaxe YAML
- ✅ Variables d'environnement
- ✅ Configuration des services
- ✅ Security best practices
- ✅ Présence de tous les bugs fixés

---

**Date d'analyse** : 2024-12-05  
**Niveau de difficulté** : Intermédiaire  
**Temps de résolution estimé** : 30-45 minutes
