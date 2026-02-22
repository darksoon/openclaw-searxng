# 🛠️ Vollständiges Setup Tutorial

## 📋 Voraussetzungen

- Docker & Docker Compose
- OpenClaw installiert (lokale Instanz oder Container)
- 1GB RAM frei für SearXNG
- Port 8888 frei (oder anderer Port)

## 🐳 Docker Compose Setup (Empfohlen)

```yaml
# docker-compose.yml
version: '3.8'

services:
  searxng:
    image: searxng/searxng:latest
    container_name: searxng
    restart: unless-stopped
    ports:
      - "8888:8080"
    environment:
      - SEARXNG_BASE_URL=http://localhost:8888
      - SEARXNG_SECRET=${SEARXNG_SECRET:-$(openssl rand -hex 32)}
    volumes:
      - ./searxng-data:/etc/searxng:ro
      - ./searxng-cache:/var/cache/searxng
    networks:
      - openclaw-network

  openclaw:
    image: ghcr.io/openclaw/openclaw:main
    container_name: openclaw
    restart: unless-stopped
    ports:
      - "18789:18789"
    environment:
      - OPENCLAW_GATEWAY_TOKEN=${GATEWAY_TOKEN:-$(openssl rand -hex 24)}
      - SEARXNG_URL=http://searxng:8080
    volumes:
      - ./openclaw-data:/home/openclaw/.openclaw
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - openclaw-network
    depends_on:
      - searxng

networks:
  openclaw-network:
    driver: bridge
```

**Starten:**
```bash
# 1. Verzeichnis erstellen
mkdir openclaw-searxng && cd openclaw-searxng

# 2. docker-compose.yml erstellen
nano docker-compose.yml  # oben einfügen

# 3. Starten
docker-compose up -d

# 4. Logs prüfen
docker-compose logs -f
```

## 🖥️ Unraid Setup

### Template erstellen
```xml
<?xml version="1.0" encoding="utf-8"?>
<Container>
  <Name>OpenClaw-SearXNG</Name>
  <Repository>ghcr.io/openclaw/openclaw:main</Repository>
  <Config>
    <Config Name="SEARXNG_URL" Target="http://192.168.1.100:8888" Default="http://localhost:8888" Mode="" Description="SearXNG URL"/>
    <Config Name="GATEWAY_TOKEN" Target="" Default="" Mode="" Description="OpenClaw Gateway Token"/>
  </Config>
  <Network>
    <Mode>bridge</Mode>
    <Publish>
      <Port>
        <HostPort>18789</HostPort>
        <ContainerPort>18789</ContainerPort>
        <Protocol>tcp</Protocol>
      </Port>
    </Publish>
  </Network>
</Container>
```

### SearXNG auf Unraid
1. **CA App**: SearXNG installieren
2. **Port**: 8888 setzen
3. **JSON API aktivieren** (siehe unten)

## ⚙️ SearXNG Konfiguration

### JSON API aktivieren
```bash
# In den Container
docker exec searxng bash

# Config bearbeiten
nano /etc/searxng/settings.yml

# Suchen nach:
# formats:
#   - html

# Ändern zu:
formats:
  - html
  - json

# Container neustarten
docker restart searxng
```

### Alternative: One-Liner
```bash
docker exec searxng sed -i 's/formats:/formats:\\n  - json/' /etc/searxng/settings.yml && docker restart searxng
```

### Testen
```bash
curl "http://localhost:8888/search?q=test&format=json" | jq '.results[0]'
```

## 🤖 OpenClaw Konfiguration

### Config setzen
```bash
# In den OpenClaw Container
docker exec openclaw bash

# Provider auf searxng setzen
openclaw config set tools.web.search.provider searxng

# Oder Config-Datei direkt bearbeiten
nano /home/openclaw/.openclaw/openclaw.json
# Ändern: "provider": "brave" → "provider": "searxng"
```

### Plugin installieren
```bash
npx clawhub install searxng-local-search --force
```

### Gateway neustarten
```bash
openclaw gateway restart
```

## 🔍 Test-Skript

```bash
#!/bin/bash
# test-searxng.sh

echo "🧪 Testing SearXNG + OpenClaw Setup..."

# 1. SearXNG API testen
echo "1. Testing SearXNG JSON API..."
curl -s "http://localhost:8888/search?q=OpenClaw&format=json&num_results=1" | jq -r '.results[0].title' || echo "❌ SearXNG not responding"

# 2. OpenClaw Config prüfen
echo "2. Checking OpenClaw config..."
docker exec openclaw openclaw config get tools.web.search.provider | grep -q "searxng" && echo "✅ Config: searxng" || echo "❌ Config not set"

# 3. Test-Suche durchführen
echo "3. Performing test search..."
docker exec openclaw openclaw exec "~/.local/bin/searxng-search 'test search' 1" | head -5

# 4. Kosten-Check
echo "4. Cost analysis..."
echo "   Before (Brave API): ~$10/month for 2000 searches"
echo "   After (SearXNG): $0/month for unlimited searches"
echo "   Savings: 100% 🎉"

echo "✅ Setup complete!"
```

## 🐛 Troubleshooting

### Problem: "missing_brave_api_key"
**Lösung:** Config ist noch auf `provider: "brave"`. Ändere zu `provider: "searxng"`.

### Problem: SearXNG gibt 403 Forbidden
**Lösung:** JSON Format nicht aktiviert. Siehe "JSON API aktivieren" oben.

### Problem: OpenClaw findet SearXNG nicht
**Lösung:** 
```bash
# URL in Container testen
docker exec openclaw curl -s http://searxng:8080/search?q=test

# Falls nicht erreichbar: Netzwerk prüfen
docker network ls
docker network inspect openclaw-network
```

### Problem: Bootloop nach Config-Änderung
**Lösung:**
```bash
docker exec openclaw openclaw doctor --fix
docker restart openclaw
```

## 📊 Monitoring

### Logs anzeigen
```bash
# SearXNG Logs
docker logs searxng --tail 50

# OpenClaw Logs  
docker logs openclaw --tail 50

# Kombinierte Logs
docker-compose logs -f
```

### Performance Monitoring
```bash
# CPU/Memory Usage
docker stats searxng openclaw

# Request Count
docker exec searxng tail -f /var/log/searxng/access.log | awk '{print $1}'
```

### Health Checks
```bash
#!/bin/bash
# health-check.sh

# SearXNG Health
curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/health
echo " SearXNG HTTP Status"

# OpenClaw Health
docker exec openclaw openclaw doctor --non-interactive
echo " OpenClaw Health"
```

## 🔄 Backup & Restore

### Backup
```bash
#!/bin/bash
# backup.sh
BACKUP_DIR="./backup-$(date +%Y%m%d)"

mkdir -p $BACKUP_DIR

# SearXNG Config
docker cp searxng:/etc/searxng/settings.yml $BACKUP_DIR/searxng-settings.yml

# OpenClaw Config
docker cp openclaw:/home/openclaw/.openclaw/openclaw.json $BACKUP_DIR/openclaw-config.json

# Docker Compose
cp docker-compose.yml $BACKUP_DIR/

echo "✅ Backup created in $BACKUP_DIR"
```

### Restore
```bash
#!/bin/bash
# restore.sh BACKUP_DIR
BACKUP_DIR=$1

# SearXNG Config
docker cp $BACKUP_DIR/searxng-settings.yml searxng:/etc/searxng/settings.yml
docker restart searxng

# OpenClaw Config  
docker cp $BACKUP_DIR/openclaw-config.json openclaw:/home/openclaw/.openclaw/openclaw.json
docker restart openclaw

echo "✅ Restored from $BACKUP_DIR"
```

## 🚀 Optimierung

### SearXNG Performance
```yaml
# In settings.yml
search:
  formats:
    - html
    - json
  max_results: 50
  results_per_page: 10
  
server:
  port: 8080
  bind_address: "0.0.0.0"
  secret_key: "your-secret-key-here"
  
engines:
  - name: google
    engine: google
    shortcut: g
  - name: duckduckgo
    engine: duckduckgo
    shortcut: d
  - name: bing
    engine: bing
    shortcut: b
```

### OpenClaw Cache
```bash
# Cache für häufig gesuchte Queries
openclaw config set agents.defaults.cache.enabled true
openclaw config set agents.defaults.cache.ttl "1h"
```

## 📈 Erfolgsmetriken

Nach der Umstellung tracken:
- **Kosten:** Von $10+/Monat auf $0
- **Performance:** Latenz < 500ms pro Suche
- **Zuverlässigkeit:** 99.9% Uptime
- **Results:** 2-3x mehr Ergebnisse durch Multi-Engine

## 🆘 Hilfe & Support

- **GitHub Issues:** [openclaw/openclaw](https://github.com/openclaw/openclaw)
- **Discord:** [OpenClaw Community](https://discord.gg/openclaw)
- **Twitter:** [@OpenClawAI](https://twitter.com/OpenClawAI)

---

**Fertig!** Dein OpenClaw sucht jetzt kostenlos, privat und selbst-gehostet über SearXNG. 🎉

*Letzte Aktualisierung: $(date)*