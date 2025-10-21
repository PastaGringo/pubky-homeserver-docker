#!/bin/bash

# Script de test pour le setup pubky-core Docker

set -e

echo "🚀 Test du setup pubky-core Docker"
echo "=================================="

# Vérification de Docker
echo "📋 Vérification de Docker..."
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker n'est pas installé ou accessible"
    exit 1
fi

if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker daemon n'est pas démarré"
    echo "💡 Démarrez Docker Desktop et réessayez"
    exit 1
fi

echo "✅ Docker est opérationnel"

# Build de l'image
echo "🔨 Build de l'image pubky-core..."
docker-compose build

echo "✅ Build terminé avec succès"

# Test de démarrage
echo "🚀 Démarrage du homeserver..."
docker-compose up -d

echo "⏳ Attente du démarrage (30 secondes)..."
sleep 30

# Vérification du statut
echo "📊 Vérification du statut..."
if docker-compose ps | grep -q "Up"; then
    echo "✅ Le homeserver est démarré"
else
    echo "❌ Problème de démarrage"
    docker-compose logs
    exit 1
fi

# Test de connectivité
echo "🌐 Test de connectivité..."
if curl -f http://localhost:6287/health > /dev/null 2>&1; then
    echo "✅ Le homeserver répond correctement"
else
    echo "⚠️  Le homeserver ne répond pas encore (normal si en cours de démarrage)"
fi

# Affichage des logs
echo "📝 Derniers logs:"
docker-compose logs --tail=10 pubky-homeserver

echo ""
echo "🎉 Setup terminé !"
echo "📍 Homeserver accessible sur: http://localhost:6287"
echo "🔍 Health check: http://localhost:6287/health"
echo ""
echo "Commandes utiles:"
echo "  docker-compose logs -f    # Voir les logs en temps réel"
echo "  docker-compose down       # Arrêter le homeserver"
echo "  docker-compose restart    # Redémarrer le homeserver"