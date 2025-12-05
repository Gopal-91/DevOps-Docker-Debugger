# 💬 Exercice 3 : Mattermost + PostgreSQL

## 🐛 Problèmes identifiés dans le fichier buggy

### 1. **Chaîne de connexion PostgreSQL incorrecte**
- ❌ Format simplifié : `postgres://mattermost:password@postgres:5432/mattermost`
- ✅ Format complet requis : `postgres://user:pass@host:port/db?sslmode=disable&connect_timeout=10`
- **Raison** : Mattermost nécessite des paramètres supplémentaires pour la connexion

### 2. **Mots de passe en clair**
- ❌ Credentials hardcodés dans docker-compose
- ✅ Variables d'environnement via `.env`

### 3. **Absence de health checks**
- ❌ Pas de vérification de l'état des services
- ✅ Health checks pour PostgreSQL et Mattermost (endpoint `/api/v4/system/ping`)

### 4. **Ordre de démarrage non garanti**
- ❌ `depends_on` simple ne garantit pas que PostgreSQL est prêt
- ✅ Utilisation de `condition: service_healthy`

### 5. **Absence de réseau isolé**
- ❌ Utilisation du réseau par défaut
- ✅ Création d'un réseau bridge dédié

### 6. **Ports PostgreSQL exposés inutilement**
- ❌ Port 5432 accessible depuis l'extérieur
- ✅ Communication interne uniquement

### 7. **Volume config manquant**
- ❌ Pas de volume pour `/mattermost/config`
- ✅ Ajout du volume pour persister la configuration

## 🚀 Déploiement

```bash
# Démarrer les services
docker-compose up -d

# Vérifier les logs
docker-compose logs -f mattermost

# Vérifier l'état des services
docker-compose ps

# Accéder à Mattermost
http://localhost:8065
```

## 🔐 Configuration initiale

1. Accéder à http://localhost:8065
2. Créer le premier compte administrateur
3. Configurer l'équipe et les canaux

## ✅ Tests de validation

1. **Accès à Mattermost** : http://localhost:8065
2. **Création d'un compte utilisateur**
3. **Création d'une équipe**
4. **Envoi d'un message de test**
5. **Vérification de la persistance** (redémarrage des conteneurs)

## 🛠️ Bonnes pratiques appliquées

- ✅ Réseau Docker isolé
- ✅ Health checks sur PostgreSQL et Mattermost
- ✅ Variables d'environnement externalisées
- ✅ Chaîne de connexion complète avec paramètres
- ✅ Restart policy configurée
- ✅ Volumes nommés pour la persistance
- ✅ Pas d'exposition inutile de ports

## 🔍 Commandes utiles

```bash
# Voir les logs de Mattermost
docker-compose logs -f mattermost

# Voir les logs de PostgreSQL
docker-compose logs -f postgres

# Vérifier la connexion à la base
docker-compose exec postgres psql -U mattermost -d mattermost -c "\dt"

# Redémarrer Mattermost
docker-compose restart mattermost
```
