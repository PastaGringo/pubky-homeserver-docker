# Dockerfile pour pubky-core homeserver
# Télécharge le binaire pré-compilé depuis les releases GitHub

FROM alpine:3.20

# Arguments configurables
ARG PUBKY_VERSION=v0.5.4
ARG PLATFORM=linux-amd64

RUN echo "Téléchargement de pubky-core ${PUBKY_VERSION} pour ${PLATFORM}"

# Installation des dépendances runtime
RUN apk add --no-cache \
    ca-certificates \
    curl \
    tar

# Création d'un utilisateur non-root pour la sécurité
RUN addgroup -g 1000 pubky && \
    adduser -D -s /bin/sh -u 1000 -G pubky pubky

# Création du répertoire de travail
WORKDIR /tmp

# Téléchargement et extraction du binaire pubky-core
RUN curl -L "https://github.com/pubky/pubky-core/releases/download/${PUBKY_VERSION}/pubky-core-${PUBKY_VERSION}-${PLATFORM}.tar.gz" \
         -o pubky-core.tar.gz && \
    tar -xzf pubky-core.tar.gz && \
    mv pubky-core-${PUBKY_VERSION}-${PLATFORM}/pubky-homeserver /usr/local/bin/homeserver && \
    chmod +x /usr/local/bin/homeserver && \
    rm -rf /tmp/*

# Création des répertoires de données
RUN mkdir -p /app/data /app/config && \
    chown -R pubky:pubky /app

# Configuration par défaut dans le répertoire de données
RUN mkdir -p /app/data && \
    echo '[homeserver]' > /app/data/config.toml && \
    echo 'host = "0.0.0.0"' >> /app/data/config.toml && \
    echo 'port = 6287' >> /app/data/config.toml && \
    chown -R pubky:pubky /app/data

# Set the working directory
WORKDIR /app

# Exposition du port
EXPOSE 6287

# Changement vers l'utilisateur non-root
USER pubky

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:6287/health || exit 1

# Set the default command to run the binary
CMD ["homeserver", "--config", "/app/config/config.toml"]