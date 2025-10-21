# Guide des boutons de déploiement

Ce guide explique comment configurer et utiliser les différents boutons de déploiement pour Pubky Homeserver.

## 🚀 Boutons disponibles

### 1. Deploy to DigitalOcean (App Platform)

**Bouton :**
```markdown
[![Deploy to DigitalOcean](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/PastaGringo/pubky-homeserver-docker/tree/main)
```

**Configuration requise :**
1. Le repository est configuré pour `PastaGringo/pubky-homeserver-docker`
2. Assurez-vous que le fichier `.do/app.yaml` est présent dans votre repository
3. Le repository doit être public ou accessible à DigitalOcean

**Fonctionnement :**
- Redirige vers DigitalOcean App Platform
- Utilise le fichier `.do/app.yaml` pour la configuration
- Déploiement automatique avec HTTPS
- Scaling automatique selon la charge

### 2. Script de déploiement en un clic

**Commande :**
```bash
curl -sSL https://raw.githubusercontent.com/PastaGringo/pubky-homeserver-docker/main/deploy-one-click.sh | bash
```

**Configuration requise :**
1. Le script est configuré pour le repository `PastaGringo/pubky-homeserver-docker`
2. Le script `deploy-one-click.sh` doit être dans la racine du repository
3. Le repository doit être public pour l'accès via `raw.githubusercontent.com`

**Fonctionnement :**
- Télécharge et exécute le script directement
- Installation automatique des dépendances
- Configuration du firewall et des services
- Démarrage automatique de Pubky Homeserver

## 🔧 Configuration pour votre repository

### Étape 1 : Personnaliser les URLs

Les URLs sont maintenant configurées pour le repository `PastaGringo/pubky-homeserver-docker` :

- `README.md` - Boutons et liens de déploiement
- `.do/app.yaml` - Configuration DigitalOcean App Platform
- `.do/deploy.template.yaml` - Template de déploiement
- `DEPLOY-BUTTONS.md` - Documentation des boutons

**Vérification des URLs :**
```bash
# Vérifier les URLs configurées
grep -r "PastaGringo/pubky-homeserver-docker" .
```

### Étape 2 : Configurer DigitalOcean App Platform

1. **Copiez le template :**
   ```bash
   cp .do/deploy.template.yaml .do/app.yaml
   ```

2. **Modifiez la configuration GitHub :**
   ```yaml
   github:
     repo: monusername/pubky-stack
     branch: main
     deploy_on_push: true
   ```

3. **Ajustez les ressources si nécessaire :**
   ```yaml
   instance_size_slug: basic-xxs  # 0.5 vCPU, 0.5 GB RAM
   # ou
   instance_size_slug: basic-xs   # 1 vCPU, 1 GB RAM
   ```

### Étape 3 : Tester les boutons

1. **Test local du script :**
   ```bash
   # Vérifier la syntaxe
   bash -n deploy-one-click.sh
   
   # Test avec variables d'environnement
   PUBKY_VERSION=v0.5.4 ./deploy-one-click.sh --help
   ```

2. **Test du bouton DigitalOcean :**
   - Cliquez sur le bouton dans votre README
   - Vérifiez que DigitalOcean peut accéder à votre repository
   - Testez le déploiement sur un petit droplet

## 🎨 Personnalisation des boutons

### Badges personnalisés

Vous pouvez créer vos propres badges avec [shields.io](https://shields.io/) :

```markdown
[![Version](https://img.shields.io/badge/Version-v0.5.4-blue)](https://github.com/pubky/pubky-core)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-green)](.)
[![Deploy](https://img.shields.io/badge/Deploy-One%20Click-orange)](https://cloud.digitalocean.com/apps/new)
```

### Boutons alternatifs

**Style GitHub :**
```markdown
[<img src="https://img.shields.io/badge/Deploy%20to-DigitalOcean-0080FF?style=for-the-badge&logo=digitalocean" height="32">](https://cloud.digitalocean.com/apps/new?repo=https://github.com/PastaGringo/pubky-homeserver-docker)
```

**Style personnalisé :**
```markdown
<a href="https://cloud.digitalocean.com/apps/new?repo=https://github.com/PastaGringo/pubky-homeserver-docker">
  <img src="https://www.deploytodo.com/do-btn-blue-ghost.svg" alt="Deploy to DigitalOcean">
</a>
```

## 🔒 Sécurité

### Repository public vs privé

**Repository public :**
- ✅ Boutons fonctionnent directement
- ✅ Script accessible via `raw.githubusercontent.com`
- ⚠️ Code visible par tous

**Repository privé :**
- ❌ Boutons nécessitent une configuration supplémentaire
- ❌ Script non accessible directement
- ✅ Code protégé

### Bonnes pratiques

1. **Ne jamais inclure de secrets** dans les fichiers de configuration
2. **Utiliser des variables d'environnement** pour les données sensibles
3. **Tester les scripts** avant de les publier
4. **Documenter les prérequis** clairement

## 🐛 Dépannage

### Bouton DigitalOcean ne fonctionne pas

1. **Vérifiez l'URL du repository** dans le lien
2. **Assurez-vous que le fichier `.do/app.yaml` existe**
3. **Vérifiez les permissions** du repository
4. **Testez l'accès** à votre repository depuis DigitalOcean

### Script de déploiement échoue

1. **Vérifiez l'URL** du script dans la commande curl
2. **Testez l'accès** au fichier raw sur GitHub
3. **Vérifiez les permissions** d'exécution
4. **Consultez les logs** d'erreur

### Erreurs de configuration

1. **Validez le YAML** avec un validateur en ligne
2. **Vérifiez les variables d'environnement** requises
3. **Testez avec des valeurs par défaut** d'abord
4. **Consultez la documentation** DigitalOcean App Platform

## 📚 Ressources

- [DigitalOcean App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- [GitHub Raw URLs](https://docs.github.com/en/repositories/working-with-files/using-files/getting-permanent-links-to-files)
- [Shields.io Badge Generator](https://shields.io/)
- [YAML Validator](https://yamlchecker.com/)