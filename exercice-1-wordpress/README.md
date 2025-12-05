# ✅ Exercice 1 : WordPress + MySQL + PhpMyAdmin

## 🎯 Objectif

Débugger et corriger une stack WordPress complète avec MySQL 8.0 et PhpMyAdmin présentant plusieurs erreurs de configuration courantes.

## 📦 Stack Technique

- **WordPress** : Latest (CMS)
- **MySQL** : 8.0 (Base de données)
- **PhpMyAdmin** : Latest (Interface d'administration DB)

## 🐛 Problèmes du fichier buggy

Consultez le fichier **[analyse.md](./analyse.md)** pour une analyse détaillée de tous les bugs identifiés.

### Résumé des 10 bugs corrigés

1. ❌ **MYSQL_ROOT_PASSWORD manquant** → MySQL ne démarre pas
2. ❌ **depends_on simple** → WordPress ne peut pas se connecter
3. ❌ **Credentials en clair** → Faille de sécurité
4. ❌ **Pas de réseau isolé** → Manque d'isolation
5. ❌ **Port MySQL exposé** → Risque de sécurité
6. ❌ **Pas de health check WordPress** → État incertain
7. ❌ **PhpMyAdmin démarre trop tôt** → Connexion échoue
8. ❌ **Pas de restart policy** → Pas de résilience
9. ❌ **Volumes non typés** → Manque de clarté
10. ❌ **Noms auto-générés** → Difficulté de lecture

## 📁 Structure des fichiers

```
exercice-1-wordpress/
├── docker-compose-buggy.yml    # ❌ Version avec tous les bugs
├── docker-compose.yml          # ✅ Version corrigée
├── .env                        # Variables d'environnement (à créer)
├── .env.example               # Template de configuration
├── .gitignore                 # Git ignore (.env)
├── analyse.md                 # 📊 Analyse détaillée des bugs
└── README.md                  # Ce fichier
```

## 🚀 Déploiement

### Prérequis

- Docker >= 20.10
- Docker Compose >= 2.0
- 2GB RAM minimum

### Installation

1. **Copier le fichier de configuration**
```bash
cp .env.example .env
```

2. **Modifier les variables d'environnement** (optionnel)
```bash
nano .env
```

3. **Démarrer la stack**
```bash
docker-compose up -d
```

4. **Vérifier l'état des services**
```bash
docker-compose ps
```

Vous devriez voir :
```
NAME                    STATUS
wordpress-mysql         Up (healthy)
wordpress-app           Up (healthy)
wordpress-phpmyadmin    Up
```

5. **Accéder aux applications**
- **WordPress** : http://localhost:8080
- **PhpMyAdmin** : http://localhost:8081

## 🔐 Credentials par défaut

**MySQL** :
- Root Password : `rootpass_secure_123` (défini dans `.env`)
- Database : `wordpress`
- User : `wordpress`
- Password : `wordpress_secure_123`

**PhpMyAdmin** :
- Server : `mysql`
- Username : `wordpress`
- Password : `wordpress_secure_123`

⚠️ **Important** : Changez ces mots de passe en production !

## ✅ Tests de validation

### 1. Test de démarrage
```bash
docker-compose logs mysql
# ✅ Devrait afficher : "ready for connections"

docker-compose logs wordpress
# ✅ Pas d'erreur "Connection refused"
```

### 2. Test d'accès WordPress
```bash
curl -I http://localhost:8080
# ✅ HTTP/1.1 302 Found
```

### 3. Test d'accès PhpMyAdmin
```bash
curl -I http://localhost:8081
# ✅ HTTP/1.1 200 OK
```

### 4. Test de sécurité MySQL
```bash
mysql -h 127.0.0.1 -P 3306 -u wordpress -p
# ✅ Devrait échouer (port non exposé)
```

### 5. Test de health check
```bash
docker inspect wordpress-mysql --format='{{.State.Health.Status}}'
# ✅ healthy

docker inspect wordpress-app --format='{{.State.Health.Status}}'
# ✅ healthy
```

### 6. Test de persistance
```bash
# Créer du contenu dans WordPress
# Puis arrêter les conteneurs
docker-compose down

# Redémarrer
docker-compose up -d

# ✅ Les données doivent être conservées
```

## 🛠️ Commandes utiles

### Voir les logs en temps réel
```bash
docker-compose logs -f
docker-compose logs -f wordpress  # Logs d'un service spécifique
```

### Accéder au shell d'un conteneur
```bash
docker-compose exec mysql bash
docker-compose exec wordpress bash
```

### Redémarrer un service
```bash
docker-compose restart wordpress
```

### Voir les volumes
```bash
docker volume ls | grep wordpress
```

### Arrêter les services
```bash
docker-compose down
```

### Arrêter et supprimer les volumes (⚠️ perte de données)
```bash
docker-compose down -v
```

## 📊 Architecture réseau

```
┌────────────────────────────────────────┐
│     wordpress-network (bridge)         │
│                                        │
│  ┌──────────┐   ┌───────────┐          │
│  │  MySQL   │   │ WordPress │ :8080    │
│  │  :3306   │◄──│           │───────── ┼─→ Internet
│  └──────────┘   └───────────┘          │
│       ▲                                │
│       │                                │
│  ┌────┴──────┐                         │
│  │PhpMyAdmin │ :8081                   │
│  │           │──────────────────────── ┼─→ Internet
│  └───────────┘                         │
└────────────────────────────────────────┘
```

**Points clés** :
- ✅ MySQL accessible uniquement en interne
- ✅ WordPress et PhpMyAdmin exposés via ports
- ✅ Communication inter-services via noms DNS

## 🎓 Bonnes pratiques appliquées

### 1. Sécurité
- ✅ Variables d'environnement (pas de credentials en dur)
- ✅ `.env` dans `.gitignore`
- ✅ MySQL non exposé publiquement
- ✅ Réseau Docker isolé

### 2. Fiabilité
- ✅ Health checks sur MySQL et WordPress
- ✅ `depends_on` avec `condition: service_healthy`
- ✅ Restart policy `unless-stopped`
- ✅ `start_period` pour laisser le temps aux services

### 3. Maintenabilité
- ✅ Container names explicites
- ✅ Volumes nommés et typés
- ✅ Documentation complète
- ✅ Séparation buggy/corrigé

### 4. DevOps
- ✅ Infrastructure as Code
- ✅ Reproductibilité garantie
- ✅ Configuration externalisée
- ✅ Logging sur stdout/stderr

## 🔍 Debugging

### Problème : MySQL ne démarre pas

**Symptôme** :
```bash
docker-compose logs mysql
# ERROR: MYSQL_ROOT_PASSWORD must be specified
```

**Solution** :
Vérifier que le fichier `.env` existe et contient `MYSQL_ROOT_PASSWORD`.

### Problème : WordPress affiche "Error establishing database connection"

**Symptôme** :
Page blanche ou erreur de connexion DB.

**Solution** :
1. Vérifier que MySQL est healthy : `docker-compose ps`
2. Vérifier les logs MySQL : `docker-compose logs mysql`
3. Vérifier les credentials dans `.env`

### Problème : "Container name already in use"

**Solution** :
```bash
docker-compose down
docker rm -f wordpress-mysql wordpress-app wordpress-phpmyadmin
docker-compose up -d
```

## 📚 Ressources

- [Documentation MySQL Docker Hub](https://hub.docker.com/_/mysql)
- [Documentation WordPress Docker Hub](https://hub.docker.com/_/wordpress)
- [Documentation PhpMyAdmin Docker Hub](https://hub.docker.com/r/phpmyadmin/phpmyadmin/)
- [Docker Compose Healthcheck](https://docs.docker.com/compose/compose-file/05-services/#healthcheck)

## 🤝 Contribution

Pour améliorer cet exercice :
1. Fork le repository
2. Créer une branche (`git checkout -b improvement/amazing-fix`)
3. Commit les changements (`git commit -m 'Add amazing fix'`)
4. Push (`git push origin improvement/amazing-fix`)
5. Créer une Pull Request

## 📄 Licence

MIT License - Libre d'utilisation pour l'apprentissage.
