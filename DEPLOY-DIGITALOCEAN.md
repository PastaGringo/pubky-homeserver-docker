# Déploiement Pubky Homeserver sur DigitalOcean

Ce guide vous explique comment déployer facilement Pubky Homeserver sur un VPS DigitalOcean avec récupération automatique de l'IP publique.

## 📋 Prérequis

- Un VPS DigitalOcean (minimum 1GB RAM, 1 vCPU)
- Ubuntu 20.04 ou 22.04 LTS
- Accès SSH au serveur
- Git installé

## 🚀 Déploiement rapide

### 1. Configuration initiale du VPS

Connectez-vous à votre VPS et exécutez le script de configuration :

```bash
# Cloner le projet
git clone <votre-repo> ~/pubky-homeserver
cd ~/pubky-homeserver

# Rendre les scripts exécutables
chmod +x setup-vps.sh deploy-digitalocean.sh

# Configurer le VPS (Docker, firewall, optimisations)
./setup-vps.sh
```

**Important :** Après l'exécution du script, redémarrez votre session SSH pour appliquer les groupes Docker :

```bash
exit
# Reconnectez-vous via SSH
```

### 2. Déploiement de l'application

```bash
cd ~/pubky-homeserver
./deploy-digitalocean.sh
```

Le script va automatiquement :
- ✅ Détecter l'IP publique de votre VPS
- ✅ Configurer l'environnement de production
- ✅ Configurer le firewall
- ✅ Construire et démarrer les containers
- ✅ Vérifier le déploiement

## 🔧 Configuration avancée

### Variables d'environnement

Le fichier `.env.production` est automatiquement généré avec :

```bash
# Version et plateforme
PUBKY_VERSION=v0.5.4
PLATFORM=linux-amd64

# Configuration réseau
PUBKY_HOST=0.0.0.0
PUBKY_PORT=6287
PUBLIC_IP=<détectée automatiquement>

# Ressources (ajustez selon votre VPS)
MEMORY_LIMIT=1g
MEMORY_RESERVATION=512m
CPU_LIMIT=1.0
CPU_RESERVATION=0.5

# Données
PUBKY_DATA_DIR=/opt/pubky/data
```

### Tailles de VPS recommandées

| Taille VPS | RAM | CPU | Recommandation |
|------------|-----|-----|----------------|
| Basic | 1GB | 1 vCPU | Développement/Test |
| Standard | 2GB | 1 vCPU | Production légère |
| Performance | 4GB | 2 vCPU | Production standard |

### Ajustement des ressources

Pour modifier les limites selon votre VPS :

```bash
# Éditer le fichier de configuration
nano .env.production

# Redémarrer avec la nouvelle configuration
docker-compose --env-file .env.production restart
```

## 🔒 Sécurité

### Firewall configuré automatiquement

Le script configure UFW avec :
- ✅ SSH (port 22) - autorisé
- ✅ Pubky TLS (port 6287) - autorisé
- ✅ DHT (port 6881/UDP) - autorisé
- ❌ Tous les autres ports - bloqués

### Ports exposés

| Port | Service | Accès |
|------|---------|-------|
| 6287 | Pubky TLS | Public (votre IP) |
| 6286 | HTTP | Local uniquement |
| 6288 | Admin | Local uniquement |
| 6881 | DHT | Public (UDP) |

## 📊 Monitoring et maintenance

### Vérifier le statut

```bash
# Statut des containers
docker-compose --env-file .env.production ps

# Logs en temps réel
docker-compose --env-file .env.production logs -f

# Logs récents
docker-compose --env-file .env.production logs --tail=50
```

### Commandes utiles

```bash
# Redémarrer le service
docker-compose --env-file .env.production restart

# Arrêter le service
docker-compose --env-file .env.production down

# Mettre à jour et redéployer
git pull
./deploy-digitalocean.sh

# Nettoyer les images inutilisées
docker system prune -f
```

### Monitoring système

```bash
# Utilisation des ressources
htop

# Utilisation disque
df -h
ncdu /opt/pubky

# Trafic réseau
nethogs

# Logs système
journalctl -u docker -f
```

## 🌐 Accès à votre Homeserver

Après un déploiement réussi, votre Pubky Homeserver sera accessible :

- **Pubky TLS :** `https://VOTRE_IP:6287`
- **Admin (local) :** `http://localhost:6288` (via SSH tunnel)

### Tunnel SSH pour l'admin

Pour accéder à l'interface admin depuis votre machine locale :

```bash
ssh -L 6288:localhost:6288 user@VOTRE_IP
```

Puis ouvrez `http://localhost:6288` dans votre navigateur.

## 🔧 Dépannage

### Container ne démarre pas

```bash
# Vérifier les logs
docker-compose --env-file .env.production logs

# Vérifier l'espace disque
df -h

# Vérifier la mémoire
free -h
```

### Problèmes de réseau

```bash
# Vérifier les ports ouverts
sudo netstat -tlnp | grep :6287

# Vérifier le firewall
sudo ufw status

# Tester la connectivité
curl -k https://localhost:6287
```

### Réinstallation complète

```bash
# Arrêter et supprimer tout
docker-compose --env-file .env.production down -v
docker system prune -af

# Redéployer
./deploy-digitalocean.sh
```

## 📝 Options du script de déploiement

```bash
# Déploiement standard
./deploy-digitalocean.sh

# Ignorer la configuration du firewall
./deploy-digitalocean.sh --skip-firewall

# Aide
./deploy-digitalocean.sh --help
```

## 🔄 Mise à jour

Pour mettre à jour vers une nouvelle version :

1. Modifier `PUBKY_VERSION` dans `.env.production`
2. Redéployer : `./deploy-digitalocean.sh`

## 📞 Support

En cas de problème :

1. Vérifiez les logs : `docker-compose --env-file .env.production logs`
2. Vérifiez l'état du système : `htop`, `df -h`
3. Consultez la documentation Pubky
4. Ouvrez une issue sur le repository

---

**Note :** Ce guide suppose une installation sur Ubuntu. Pour d'autres distributions, adaptez les commandes d'installation des paquets.