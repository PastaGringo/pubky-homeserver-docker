#!/bin/bash

# Script de déploiement en un clic pour Pubky Homeserver
# =====================================================
# Ce script est optimisé pour être exécuté via des boutons de déploiement web

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration par défaut
PUBKY_VERSION=${PUBKY_VERSION:-"v0.5.4"}
PLATFORM=${PLATFORM:-"linux-amd64"}
INSTALL_DIR=${INSTALL_DIR:-"/opt/pubky"}
DATA_DIR=${DATA_DIR:-"/opt/pubky/data"}

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

# Bannière de démarrage
show_banner() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🚀 PUBKY HOMESERVER                      ║"
    echo "║                   Déploiement en un clic                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Détection de l'environnement
detect_environment() {
    log_info "Détection de l'environnement..."
    
    # Détecter le système d'exploitation
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get &> /dev/null; then
            DISTRO="ubuntu"
        elif command -v yum &> /dev/null; then
            DISTRO="centos"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PLATFORM="darwin-amd64"
    else
        log_error "Système d'exploitation non supporté: $OSTYPE"
        exit 1
    fi
    
    log_success "Environnement détecté: $OS ($DISTRO)"
}

# Installation des dépendances
install_dependencies() {
    log_info "Installation des dépendances..."
    
    case $DISTRO in
        ubuntu)
            sudo apt-get update
            sudo apt-get install -y curl wget unzip
            ;;
        centos)
            sudo yum update -y
            sudo yum install -y curl wget unzip
            ;;
        *)
            log_warning "Distribution non reconnue, vérifiez que curl et wget sont installés"
            ;;
    esac
    
    log_success "Dépendances installées"
}

# Récupération de l'IP publique
get_public_ip() {
    log_info "Récupération de l'IP publique..."
    
    # Essayer plusieurs services
    PUBLIC_IP=""
    
    for service in "https://api.ipify.org" "https://icanhazip.com" "https://ifconfig.me"; do
        if [ -z "$PUBLIC_IP" ]; then
            PUBLIC_IP=$(curl -s --connect-timeout 5 "$service" 2>/dev/null | tr -d '\n' || echo "")
            if [[ $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                break
            else
                PUBLIC_IP=""
            fi
        fi
    done
    
    # Fallback vers DigitalOcean metadata
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address 2>/dev/null || echo "")
    fi
    
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP="0.0.0.0"
        log_warning "Impossible de détecter l'IP publique, utilisation de 0.0.0.0"
    else
        log_success "IP publique détectée: $PUBLIC_IP"
    fi
}

# Téléchargement et installation de Pubky Homeserver
install_pubky() {
    log_info "Téléchargement de Pubky Homeserver $PUBKY_VERSION..."
    
    # Créer les répertoires
    sudo mkdir -p "$INSTALL_DIR" "$DATA_DIR"
    sudo chown -R $USER:$USER "$INSTALL_DIR"
    
    # URL de téléchargement
    DOWNLOAD_URL="https://github.com/pubky/pubky-core/releases/download/${PUBKY_VERSION}/pubky-core-${PUBKY_VERSION}-${PLATFORM}.tar.gz"
    
    # Télécharger et extraire
    cd /tmp
    curl -L "$DOWNLOAD_URL" -o pubky-core.tar.gz
    tar -xzf pubky-core.tar.gz
    
    # Installer le binaire
    sudo cp pubky-homeserver /usr/local/bin/
    sudo chmod +x /usr/local/bin/pubky-homeserver
    
    # Nettoyer
    rm -f pubky-core.tar.gz pubky-homeserver
    
    log_success "Pubky Homeserver installé dans /usr/local/bin/"
}

# Configuration du service systemd
create_systemd_service() {
    log_info "Création du service systemd..."
    
    sudo tee /etc/systemd/system/pubky-homeserver.service > /dev/null << EOF
[Unit]
Description=Pubky Homeserver
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$DATA_DIR
ExecStart=/usr/local/bin/pubky-homeserver \\
    --data $DATA_DIR \\
    --http 0.0.0.0:6286 \\
    --pubky $PUBLIC_IP:6287 \\
    --admin 127.0.0.1:6288 \\
    --dht 0.0.0.0:6881
Restart=always
RestartSec=10
Environment=RUST_LOG=info

[Install]
WantedBy=multi-user.target
EOF
    
    # Recharger systemd et démarrer le service
    sudo systemctl daemon-reload
    sudo systemctl enable pubky-homeserver
    sudo systemctl start pubky-homeserver
    
    log_success "Service systemd créé et démarré"
}

# Configuration du firewall
setup_firewall() {
    log_info "Configuration du firewall..."
    
    if command -v ufw &> /dev/null; then
        # UFW (Ubuntu)
        sudo ufw allow ssh
        sudo ufw allow 6287/tcp comment 'Pubky Homeserver TLS'
        sudo ufw allow 6881/udp comment 'Pubky DHT'
        sudo ufw --force enable
    elif command -v firewall-cmd &> /dev/null; then
        # FirewallD (CentOS/RHEL)
        sudo firewall-cmd --permanent --add-port=6287/tcp
        sudo firewall-cmd --permanent --add-port=6881/udp
        sudo firewall-cmd --reload
    else
        log_warning "Aucun firewall détecté, configurez manuellement les ports 6287/tcp et 6881/udp"
    fi
    
    log_success "Firewall configuré"
}

# Vérification du déploiement
verify_deployment() {
    log_info "Vérification du déploiement..."
    
    # Attendre que le service démarre
    sleep 5
    
    # Vérifier le statut du service
    if sudo systemctl is-active --quiet pubky-homeserver; then
        log_success "Service Pubky Homeserver actif"
    else
        log_error "Problème avec le service"
        sudo systemctl status pubky-homeserver
        exit 1
    fi
    
    # Tester la connectivité locale
    if curl -s --connect-timeout 5 http://localhost:6286/health > /dev/null; then
        log_success "API HTTP accessible"
    else
        log_warning "API HTTP non accessible (normal pendant l'initialisation)"
    fi
}

# Affichage des informations finales
show_completion_info() {
    echo ""
    log_success "=== DÉPLOIEMENT TERMINÉ ==="
    echo -e "${GREEN}🎉 Pubky Homeserver est maintenant en cours d'exécution !${NC}"
    echo ""
    echo -e "${BLUE}📡 Accès externe:${NC}"
    echo -e "   Pubky TLS: https://$PUBLIC_IP:6287"
    echo -e "   DHT: $PUBLIC_IP:6881 (UDP)"
    echo ""
    echo -e "${BLUE}🔧 Accès local:${NC}"
    echo -e "   HTTP API: http://localhost:6286"
    echo -e "   Admin: http://localhost:6288"
    echo ""
    echo -e "${BLUE}📋 Commandes utiles:${NC}"
    echo -e "   Statut: ${YELLOW}sudo systemctl status pubky-homeserver${NC}"
    echo -e "   Logs: ${YELLOW}sudo journalctl -u pubky-homeserver -f${NC}"
    echo -e "   Redémarrer: ${YELLOW}sudo systemctl restart pubky-homeserver${NC}"
    echo -e "   Arrêter: ${YELLOW}sudo systemctl stop pubky-homeserver${NC}"
    echo ""
    echo -e "${BLUE}📁 Données stockées dans:${NC} $DATA_DIR"
}

# Fonction principale
main() {
    show_banner
    detect_environment
    install_dependencies
    get_public_ip
    install_pubky
    create_systemd_service
    setup_firewall
    verify_deployment
    show_completion_info
}

# Gestion des arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Variables d'environnement:"
        echo "  PUBKY_VERSION    Version à installer (défaut: v0.5.4)"
        echo "  PLATFORM         Plateforme cible (défaut: linux-amd64)"
        echo "  INSTALL_DIR      Répertoire d'installation (défaut: /opt/pubky)"
        echo "  DATA_DIR         Répertoire des données (défaut: /opt/pubky/data)"
        echo ""
        echo "Exemple:"
        echo "  PUBKY_VERSION=v0.5.5 $0"
        exit 0
        ;;
esac

# Vérification des permissions
if [[ $EUID -eq 0 ]]; then
    log_error "Ne pas exécuter ce script en tant que root"
    exit 1
fi

# Exécution
main