#!/bin/bash

# Script de configuration initiale pour VPS DigitalOcean
# =====================================================

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Mise à jour du système
update_system() {
    log_info "Mise à jour du système..."
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y curl wget git unzip htop
    log_success "Système mis à jour"
}

# Installation de Docker
install_docker() {
    log_info "Installation de Docker..."
    
    # Supprimer les anciennes versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Installer les dépendances
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Ajouter la clé GPG officielle de Docker
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Ajouter le repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Installer Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Ajouter l'utilisateur au groupe docker
    sudo usermod -aG docker $USER
    
    # Démarrer et activer Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    log_success "Docker installé avec succès"
}

# Installation de Docker Compose standalone
install_docker_compose() {
    log_info "Installation de Docker Compose..."
    
    # Télécharger la dernière version
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Créer un lien symbolique
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose installé: $DOCKER_COMPOSE_VERSION"
}

# Configuration du firewall
setup_firewall() {
    log_info "Configuration du firewall UFW..."
    
    # Installer UFW
    sudo apt-get install -y ufw
    
    # Réinitialiser les règles
    sudo ufw --force reset
    
    # Politique par défaut
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Autoriser SSH (important !)
    sudo ufw allow ssh
    sudo ufw allow 22/tcp
    
    # Autoriser les ports Pubky
    sudo ufw allow 6287/tcp comment 'Pubky Homeserver TLS'
    sudo ufw allow 6881/udp comment 'Pubky DHT'
    
    # Activer le firewall
    sudo ufw --force enable
    
    log_success "Firewall configuré"
}

# Optimisation du système
optimize_system() {
    log_info "Optimisation du système..."
    
    # Augmenter les limites de fichiers ouverts
    echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
    echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
    
    # Optimisations réseau
    cat << EOF | sudo tee -a /etc/sysctl.conf
# Optimisations réseau pour Pubky
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
EOF
    
    # Appliquer les changements
    sudo sysctl -p
    
    log_success "Système optimisé"
}

# Création des répertoires
create_directories() {
    log_info "Création des répertoires..."
    
    # Créer le répertoire de données
    sudo mkdir -p /opt/pubky/data
    sudo chown -R $USER:$USER /opt/pubky
    
    # Créer le répertoire de travail
    mkdir -p ~/pubky-homeserver
    
    log_success "Répertoires créés"
}

# Configuration de la swap (pour les petits VPS)
setup_swap() {
    log_info "Configuration de la swap..."
    
    # Vérifier si swap existe déjà
    if swapon --show | grep -q "/swapfile"; then
        log_warning "Swap déjà configurée"
        return
    fi
    
    # Créer un fichier de swap de 1GB
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    # Rendre permanent
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    
    # Optimiser l'utilisation de la swap
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    
    log_success "Swap configurée (1GB)"
}

# Configuration de la timezone
setup_timezone() {
    log_info "Configuration de la timezone..."
    sudo timedatectl set-timezone Europe/Paris
    log_success "Timezone configurée: Europe/Paris"
}

# Installation des outils de monitoring
install_monitoring() {
    log_info "Installation des outils de monitoring..."
    
    sudo apt-get install -y htop iotop nethogs ncdu
    
    log_success "Outils de monitoring installés"
}

# Fonction principale
main() {
    echo -e "${GREEN}"
    echo "========================================"
    echo "  Configuration VPS DigitalOcean"
    echo "  pour Pubky Homeserver"
    echo "========================================"
    echo -e "${NC}"
    
    update_system
    install_docker
    install_docker_compose
    setup_firewall
    optimize_system
    create_directories
    setup_swap
    setup_timezone
    install_monitoring
    
    echo ""
    log_success "=== CONFIGURATION TERMINÉE ==="
    echo -e "${GREEN}Le VPS est maintenant prêt pour le déploiement de Pubky Homeserver${NC}"
    echo ""
    echo -e "${YELLOW}Prochaines étapes:${NC}"
    echo -e "${BLUE}1.${NC} Redémarrer la session pour appliquer les groupes Docker:"
    echo -e "   ${YELLOW}exit${NC} puis reconnectez-vous"
    echo -e "${BLUE}2.${NC} Cloner votre projet:"
    echo -e "   ${YELLOW}git clone <votre-repo> ~/pubky-homeserver${NC}"
    echo -e "${BLUE}3.${NC} Lancer le déploiement:"
    echo -e "   ${YELLOW}cd ~/pubky-homeserver && ./deploy-digitalocean.sh${NC}"
}

# Exécution
main