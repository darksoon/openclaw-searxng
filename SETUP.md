# 🛠️ Complete Setup Tutorial

## 📋 Prerequisites

- Docker & Docker Compose
- OpenClaw installed (local instance or container)
- 1GB RAM free for SearXNG
- Port 8888 free (or any other port)

## 🐳 Docker Compose Setup (Recommended)

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

**Start:**
```bash
# 1. Create directory
mkdir openclaw-searxng && cd openclaw-searxng

# 2. Create docker-compose.yml
nano docker-compose.yml  # paste above

# 3. Start
docker-compose up -d

# 4. Check logs
docker-compose logs -f
```

## 🖥️ Unraid Setup

### Create Template
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

### SearXNG on Unraid
1. **CA App**: Install SearXNG
2. **Port**: Set to 8888
3. **Enable JSON API** (see below)

## ⚙️ SearXNG Configuration

### Enable JSON API
```bash
# Enter container
docker exec searxng bash

# Edit config
nano /etc/searxng/settings.yml

# Find:
# formats:
#   - html

# Change to:
formats:
  - html
  - json

# Restart container
docker restart searxng
```

### Alternative: One-Liner
```bash
docker exec searxng sed -i 's/formats:/formats:\\n  - json/' /etc/searxng/settings.yml && docker restart searxng
```

### Test
```bash
curl "http://localhost:8888/search?q=test&format=json" | jq '.results[0]'
```

## 🤖 OpenClaw Configuration

### Set Config
```bash
# Enter OpenClaw container
docker exec openclaw bash

# Set provider to searxng
openclaw config set tools.web.search.provider searxng

# Or edit config file directly
nano /home/openclaw/.openclaw/openclaw.json
# Change: "provider": "brave" → "provider": "searxng"
```

### Install Plugin
```bash
npx clawhub install searxng-local-search --force
```

### Restart Gateway
```bash
openclaw gateway restart
```

## 🔍 Test Script

```bash
#!/bin/bash
# test-searxng.sh

echo "🧪 Testing SearXNG + OpenClaw Setup..."

# 1. Test SearXNG API
echo "1. Testing SearXNG JSON API..."
curl -s "http://localhost:8888/search?q=OpenClaw&format=json&num_results=1" | jq -r '.results[0].title' || echo "❌ SearXNG not responding"

# 2. Check OpenClaw config
echo "2. Checking OpenClaw config..."
docker exec openclaw openclaw config get tools.web.search.provider | grep -q "searxng" && echo "✅ Config: searxng" || echo "❌ Config not set"

# 3. Test search
echo "3. Performing test search..."
docker exec openclaw openclaw exec "~/.local/bin/searxng-search 'test search' 1" | head -5

# 4. Cost check
echo "4. Cost analysis..."
echo "   Before (Brave API): ~$10/month for 2000 searches"
echo "   After (SearXNG): $0/month for unlimited searches"
echo "   Savings: 100% 🎉"

echo "✅ Setup complete!"
```

## 🐛 Troubleshooting

### Problem: "missing_brave_api_key"
**Solution:** Config is still on `provider: "brave"`. Change to `provider: "searxng"`.

### Problem: SearXNG returns 403 Forbidden
**Solution:** JSON format not enabled. See "Enable JSON API" above.

### Problem: OpenClaw can't reach SearXNG
**Solution:** 
```bash
# Test URL from container
docker exec openclaw curl -s http://searxng:8080/search?q=test

# If unreachable: check network
docker network ls
docker network inspect openclaw-network
```

### Problem: Bootloop after config change
**Solution:**
```bash
docker exec openclaw openclaw doctor --fix
docker restart openclaw
```

## 📊 Monitoring

### View Logs
```bash
# SearXNG logs
docker logs searxng --tail 50

# OpenClaw logs  
docker logs openclaw --tail 50

# Combined logs
docker-compose logs -f
```

### Performance Monitoring
```bash
# CPU/Memory usage
docker stats searxng openclaw

# Request count
docker exec searxng tail -f /var/log/searxng/access.log | awk '{print $1}'
```

### Health Checks
```bash
#!/bin/bash
# health-check.sh

# SearXNG health
curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/health
echo " SearXNG HTTP status"

# OpenClaw health
docker exec openclaw openclaw doctor --non-interactive
echo " OpenClaw health"
```

## 🔄 Backup & Restore

### Backup
```bash
#!/bin/bash
# backup.sh
BACKUP_DIR="./backup-$(date +%Y%m%d)"

mkdir -p $BACKUP_DIR

# SearXNG config
docker cp searxng:/etc/searxng/settings.yml $BACKUP_DIR/searxng-settings.yml

# OpenClaw config
docker cp openclaw:/home/openclaw/.openclaw/openclaw.json $BACKUP_DIR/openclaw-config.json

# Docker compose
cp docker-compose.yml $BACKUP_DIR/

echo "✅ Backup created in $BACKUP_DIR"
```

### Restore
```bash
#!/bin/bash
# restore.sh BACKUP_DIR
BACKUP_DIR=$1

# SearXNG config
docker cp $BACKUP_DIR/searxng-settings.yml searxng:/etc/searxng/settings.yml
docker restart searxng

# OpenClaw config  
docker cp $BACKUP_DIR/openclaw-config.json openclaw:/home/openclaw/.openclaw/openclaw.json
docker restart openclaw

echo "✅ Restored from $BACKUP_DIR"
```

## 🚀 Optimization

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
# Cache for frequently searched queries
openclaw config set agents.defaults.cache.enabled true
openclaw config set agents.defaults.cache.ttl "1h"
```

## 📈 Success Metrics

After switching, track:
- **Cost:** From $10+/Month to $0
- **Performance:** < 500ms latency per search
- **Reliability:** 99.9% uptime
- **Results:** 2-3x more results through multi-engine

## 🆘 Help & Support

- **GitHub Issues:** [openclaw/openclaw](https://github.com/openclaw/openclaw)
- **Discord:** [OpenClaw Community](https://discord.gg/openclaw)
- **Twitter:** [@OpenClawAI](https://twitter.com/OpenClawAI)

---

**Done!** Your OpenClaw now searches for free, privately, and self-hosted via SearXNG. 🎉

*Last updated: $(date)*
