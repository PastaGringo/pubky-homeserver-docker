# Pubky-Core Docker Stack

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![DigitalOcean](https://img.shields.io/badge/Deploy%20to-DigitalOcean-0080FF?logo=digitalocean)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/PastaGringo/pubky-homeserver-docker/tree/main)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Pubky Core](https://img.shields.io/badge/Pubky%20Core-v0.5.4-orange)](https://github.com/pubky/pubky-core)

## 🚀 Déploiement en un clic

### DigitalOcean

[![Deploy to DigitalOcean](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/PastaGringo/pubky-homeserver-docker/tree/main)

**Ou via script automatisé :**

```bash
# Déploiement automatique sur VPS DigitalOcean
curl -sSL https://raw.githubusercontent.com/PastaGringo/pubky-homeserver-docker/main/deploy-one-click.sh | bash
```

### Autres plateformes

- **VPS/Serveur dédié** : Utilisez le script `deploy-one-click.sh`
- **Docker local** : Suivez les instructions ci-dessous

---

Ce projet fournit une configuration Docker pour exécuter facilement un homeserver [pubky-core](https://github.com/pubky/pubky-core) en utilisant les binaires pré-compilés.

## Qu'est-ce que Pubky-Core ?

Pubky-core est un protocole ouvert pour des backends basés sur des clés publiques, destiné aux applications web résistantes à la censure. Il combine une alternative résistante à la censure au DNS basée sur des clés publiques avec des technologies web conventionnelles et éprouvées.

## Fonctionnalités

- **Binaires pré-compilés** : Télécharge directement les binaires officiels depuis GitHub Releases
- **Support multi-plateforme** : Compatible Linux, macOS et Windows (x86_64 et ARM64)
- **Configuration sécurisée** : Utilise un utilisateur non-root et des volumes persistants
- **Volumes persistants** : Sauvegarde automatique des données et configuration
- **Health checks** : Surveillance automatique de l'état du service
- **Limites de ressources** : Protection contre l'utilisation excessive de CPU/mémoire
- **Build rapide** : Pas de compilation, téléchargement direct des binaires

## Prérequis

- Docker
- Docker Compose

## 🚀 Démarrage rapide

1. **Cloner ou télécharger ce repository**

2. **Configurer les variables (optionnel)** :
   ```bash
   # Éditer le fichier .env pour personnaliser la configuration
   cp .env .env.local
   # Modifier .env.local selon vos besoins
   ```

3. **Démarrer le homeserver** :
   ```bash
   docker-compose up -d
   ```

4. **Vérifier le statut** :
   ```bash
   docker-compose ps
   docker-compose logs pubky-homeserver
   ```

5. **Accéder au homeserver** :
   - URL : `http://localhost:6287`
   - Health check : `http://localhost:6287/health`

## ⚙️ Configuration

### Variables d'environnement

Le stack peut être configuré via le fichier `.env` :

```bash
# Version de pubky-core à utiliser
PUBKY_VERSION=v0.5.4

# Plateforme cible - Options disponibles :
# - linux-amd64   (Linux x86_64)
# - linux-arm64   (Linux ARM64)  
# - osx-amd64     (macOS Intel)
# - osx-arm64     (macOS Apple Silicon)
# - windows-amd64 (Windows x86_64)
PLATFORM=linux-amd64
```

### Configuration par défaut

Le homeserver utilise une configuration par défaut qui :
- Écoute sur `0.0.0.0:6287`
- Stocke les données dans `/app/data`
- Utilise le fichier de config `/app/config/config.toml`

### Configuration personnalisée

Pour personnaliser la configuration :

1. **Créer un répertoire de configuration** :
   ```bash
   mkdir config
   ```

2. **Créer votre fichier de configuration** `config/config.toml` :
   ```toml
   [homeserver]
   host = "0.0.0.0"
   port = 6287
   data_dir = "/app/data"
   
   # Ajoutez vos paramètres personnalisés ici
   ```

3. **Redémarrer le service** :
   ```bash
   docker-compose restart
   ```

### Variables d'environnement

Vous pouvez modifier les variables d'environnement dans le `docker-compose.yml` :

```yaml
environment:
  - RUST_LOG=debug  # Niveau de log (error, warn, info, debug, trace)
  - PUBKY_HOST=0.0.0.0
  - PUBKY_PORT=6287
```

## Commandes utiles

### Gestion du service

```bash
# Démarrer
docker-compose up -d

# Arrêter
docker-compose down

# Redémarrer
docker-compose restart

# Voir les logs
docker-compose logs -f pubky-homeserver

# Voir le statut
docker-compose ps
```

### Maintenance

```bash
# Mettre à jour vers une nouvelle version
docker-compose pull
docker-compose up -d

# Sauvegarder les données
docker run --rm -v pubky-stack_pubky_data:/data -v $(pwd):/backup alpine tar czf /backup/pubky-backup.tar.gz -C /data .

# Restaurer les données
docker run --rm -v pubky-stack_pubky_data:/data -v $(pwd):/backup alpine tar xzf /backup/pubky-backup.tar.gz -C /data
```

### Debugging

```bash
# Accéder au conteneur
docker-compose exec pubky-homeserver sh

# Voir les métriques de ressources
docker stats pubky-homeserver

# Inspecter le volume de données
docker volume inspect pubky-stack_pubky_data
```

## Architecture

```
┌─────────────────────┐
│   Docker Host       │
│                     │
│  ┌───────────────┐  │
│  │ pubky-homeserver│  │
│  │               │  │
│  │ Port: 6287    │  │
│  │ User: pubky   │  │
│  │               │  │
│  └───────┬───────┘  │
│          │          │
│  ┌───────▼───────┐  │
│  │ Volume:       │  │
│  │ pubky_data    │  │
│  └───────────────┘  │
└─────────────────────┘
```

## 🌐 Options de déploiement

### 1. DigitalOcean App Platform (Recommandé)

Le moyen le plus simple pour déployer en production :

1. **Cliquez sur le bouton "Deploy to DigitalOcean"** en haut de ce README
2. **Connectez votre repository GitHub** à DigitalOcean
3. **Configurez les variables** si nécessaire
4. **Déployez** - DigitalOcean s'occupe du reste !

**Avantages :**
- ✅ Déploiement automatique
- ✅ HTTPS automatique
- ✅ Scaling automatique
- ✅ Monitoring intégré
- ✅ Pas de gestion de serveur

### 2. VPS DigitalOcean (Script automatisé)

Pour plus de contrôle, utilisez notre script de déploiement automatisé :

```bash
# Sur votre VPS DigitalOcean (Ubuntu 20.04/22.04)
curl -sSL https://raw.githubusercontent.com/PastaGringo/pubky-homeserver-docker/main/deploy-one-click.sh | bash
```

**Ce script :**
- 🔧 Installe Docker automatiquement
- 🌐 Détecte votre IP publique
- 🔥 Configure le firewall (UFW)
- 🚀 Lance Pubky Homeserver
- 📊 Configure le monitoring

### 3. Déploiement manuel

Pour les utilisateurs avancés :

1. **Clonez le repository** sur votre serveur
2. **Utilisez les scripts** dans le dossier :
   - `setup-vps.sh` : Configuration initiale du VPS
   - `deploy-digitalocean.sh` : Déploiement avec Docker Compose
3. **Consultez** `DEPLOY-DIGITALOCEAN.md` pour les détails

### 4. Docker local

Pour le développement et les tests :

```bash
git clone https://github.com/PastaGringo/pubky-homeserver-docker.git
cd pubky-stack
docker-compose up -d
```

## 🔧 Configuration avancée

### Variables d'environnement

Créez un fichier `.env.local` pour personnaliser :

```bash
# Version de Pubky Core
PUBKY_VERSION=v0.5.4

# Plateforme (linux-amd64, darwin-amd64, etc.)
PLATFORM=linux-amd64

# IP publique (auto-détectée si vide)
PUBLIC_IP=

# Limites de ressources
MEMORY_LIMIT=512m
CPU_LIMIT=0.5
```

### Ports utilisés

- **6287/tcp** : Pubky TLS (accès externe)
- **6286/tcp** : HTTP API (local uniquement)
- **6288/tcp** : Admin interface (local uniquement)
- **6881/udp** : DHT (accès externe)

## Sécurité

- ✅ Le conteneur s'exécute avec un utilisateur non-root (`pubky:1000`)
- ✅ Les volumes sont montés avec les permissions appropriées
- ✅ Le port est exposé uniquement sur l'interface nécessaire
- ✅ Health checks pour surveiller l'état du service
- ✅ Firewall automatiquement configuré (scripts de déploiement)
- ✅ HTTPS automatique (DigitalOcean App Platform)

## Dépannage

### Le service ne démarre pas

1. Vérifiez les logs :
   ```bash
   docker-compose logs pubky-homeserver
   ```

2. Vérifiez que le port 6287 n'est pas déjà utilisé :
   ```bash
   netstat -tlnp | grep 6287
   ```

### Problèmes de permissions

Si vous rencontrez des problèmes de permissions :

```bash
# Réinitialiser les permissions du volume
docker-compose down
docker volume rm pubky-stack_pubky_data
docker-compose up -d
```

### Performance

Pour ajuster les limites de ressources, modifiez la section `deploy.resources` dans `docker-compose.yml`.

## Versions supportées

- **Pubky-Core** : v0.5.4 (configurable via `PUBKY_VERSION`)
- **Architectures** : x86_64, aarch64
- **OS** : Linux (Alpine 3.20)

## Liens utiles

- [Repository pubky-core](https://github.com/pubky/pubky-core)
- [Documentation officielle](https://pubky.github.io/pubky-core/)
- [Releases GitHub](https://github.com/pubky/pubky-core/releases)

## Licence

Ce projet suit la même licence que pubky-core. Consultez le [repository original](https://github.com/pubky/pubky-core) pour plus de détails.