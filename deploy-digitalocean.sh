#!/bin/bash

# Script de déploiement Pubky Homeserver sur DigitalOcean
# ======================================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des prérequis
check_requirements() {
    log_info "Vérification des prérequis..."
    
    # Vérifier si Docker est installé
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé. Installation en cours..."
        install_docker
    else
        log_success "Docker est installé"
    fi
    
    # Vérifier si Docker Compose est installé
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose n'est pas installé. Installation en cours..."
        install_docker_compose
    else
        log_success "Docker Compose est installé"
    fi
    
    # Vérifier si curl est installé
    if ! command -v curl &> /dev/null; then
        log_error "curl n'est pas installé"
        sudo apt-get update && sudo apt-get install -y curl
    else
        log_success "curl est installé"
    fi
}

# Installation de Docker
install_docker() {
    log_info "Installation de Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    log_success "Docker installé avec succès"
}

# Installation de Docker Compose
install_docker_compose() {
    log_info "Installation de Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    log_success "Docker Compose installé avec succès"
}

# Récupération de l'IP publique
get_public_ip() {
    log_info "Récupération de l'IP publique du serveur..."
    
    # Essayer plusieurs services pour récupérer l'IP publique
    PUBLIC_IP=""
    
    # Service 1: ipify
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP=$(curl -s --connect-timeout 5 https://api.ipify.org 2>/dev/null || echo "")
    fi
    
    # Service 2: icanhazip
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP=$(curl -s --connect-timeout 5 https://icanhazip.com 2>/dev/null | tr -d '\n' || echo "")
    fi
    
    # Service 3: ifconfig.me
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP=$(curl -s --connect-timeout 5 https://ifconfig.me 2>/dev/null || echo "")
    fi
    
    # Service 4: DigitalOcean metadata (si on est sur DO)
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address 2>/dev/null || echo "")
    fi
    
    if [ -z "$PUBLIC_IP" ]; then
        log_error "Impossible de récupérer l'IP publique automatiquement"
        read -p "Veuillez entrer votre IP publique manuellement: " PUBLIC_IP
    fi
    
    # Validation de l'IP
    if [[ $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        log_success "IP publique détectée: $PUBLIC_IP"
    else
        log_error "IP publique invalide: $PUBLIC_IP"
        exit 1
    fi
}

# Configuration de l'environnement de production
setup_production_env() {
    log_info "Configuration de l'environnement de production..."
    
    # Créer le fichier .env.production
    cat > .env.production << EOF
# Configuration pubky-core Docker Stack - PRODUCTION
# =================================================

# Version de pubky-core à compiler (tag GitHub)
PUBKY_VERSION=v0.5.4

# Plateforme cible pour DigitalOcean (généralement linux-amd64)
PLATFORM=linux-amd64

# Configuration du homeserver
PUBKY_HOST=0.0.0.0
PUBKY_PORT=6287
PUBKY_DATA_DIR=/app/data

# IP publique pour l'exposition externe
PUBLIC_IP=$PUBLIC_IP

# Limites de ressources (ajustées pour la production)
MEMORY_LIMIT=1g
MEMORY_RESERVATION=512m
CPU_LIMIT=1.0
CPU_RESERVATION=0.5

# Configuration de sécurité
RUST_LOG=info
EOF
    
    log_success "Fichier .env.production créé avec l'IP publique: $PUBLIC_IP"
}

# Configuration du firewall
setup_firewall() {
    log_info "Configuration du firewall..."
    
    # Installer ufw si nécessaire
    if ! command -v ufw &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y ufw
    fi
    
    # Configuration du firewall
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Autoriser SSH
    sudo ufw allow ssh
    
    # Autoriser le port Pubky TLS
    sudo ufw allow 6287/tcp comment 'Pubky Homeserver TLS'
    
    # Autoriser le port DHT
    sudo ufw allow 6881/udp comment 'Pubky DHT'
    
    # Activer le firewall
    sudo ufw --force enable
    
    log_success "Firewall configuré"
}

# Déploiement de l'application
deploy_application() {
    log_info "Déploiement de l'application..."
    
    # Utiliser le fichier .env.production
    export $(cat .env.production | grep -v '^#' | xargs)
    
    # Arrêter les containers existants
    docker-compose down 2>/dev/null || true
    
    # Nettoyer les images inutilisées
    docker system prune -f
    
    # Construire et démarrer les containers
    docker-compose --env-file .env.production build --no-cache
    docker-compose --env-file .env.production up -d
    
    log_success "Application déployée"
}

# Vérification du déploiement
verify_deployment() {
    log_info "Vérification du déploiement..."
    
    # Attendre que le container démarre
    sleep 10
    
    # Vérifier le statut du container
    if docker-compose --env-file .env.production ps | grep -q "Up"; then
        log_success "Container démarré avec succès"
    else
        log_error "Problème avec le démarrage du container"
        docker-compose --env-file .env.production logs
        exit 1
    fi
    
    # Afficher les logs récents
    log_info "Logs récents:"
    docker-compose --env-file .env.production logs --tail=10
    
    # Afficher les informations de connexion
    echo ""
    log_success "=== DÉPLOIEMENT TERMINÉ ==="
    echo -e "${GREEN}Pubky Homeserver est accessible sur:${NC}"
    echo -e "${BLUE}  - Pubky TLS: https://$PUBLIC_IP:6287${NC}"
    echo -e "${BLUE}  - Admin (local): http://localhost:6288${NC}"
    echo ""
    echo -e "${YELLOW}Pour voir les logs:${NC} docker-compose --env-file .env.production logs -f"
    echo -e "${YELLOW}Pour arrêter:${NC} docker-compose --env-file .env.production down"
    echo -e "${YELLOW}Pour redémarrer:${NC} docker-compose --env-file .env.production restart"
}

# Fonction principale
main() {
    echo -e "${GREEN}"
    echo "========================================"
    echo "  Déploiement Pubky Homeserver"
    echo "  DigitalOcean VPS"
    echo "========================================"
    echo -e "${NC}"
    
    check_requirements
    get_public_ip
    setup_production_env
    setup_firewall
    deploy_application
    verify_deployment
}

# Gestion des arguments
case "${1:-}" in
    --skip-firewall)
        log_warning "Firewall ignoré (--skip-firewall)"
        SKIP_FIREWALL=true
        ;;
    --help|-h)
        echo "Usage: $0 [--skip-firewall] [--help]"
        echo ""
        echo "Options:"
        echo "  --skip-firewall  Ignorer la configuration du firewall"
        echo "  --help, -h       Afficher cette aide"
        exit 0
        ;;
esac

# Exécution du script principal
main