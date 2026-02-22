# 🦞🔍 OpenClaw + SearXNG: Kostenlose Web-Suche für deinen KI-Assistenten

**Brave hat sein Free Tier gekillt? Kein Problem!** Hier ist die Lösung: Self-hosted SearXNG + OpenClaw = **komplett kostenlose Web-Suche** für deinen KI-Assistenten.

![OpenClaw + SearXNG](https://img.shields.io/badge/OpenClaw-SearXNG-blue)
![Kostenlos](https://img.shields.io/badge/Kostenlos-0€-green)
![Self-Hosted](https://img.shields.io/badge/Self--Hosted-Privacy-orange)

## 🎯 Was du bekommst

| Vorher (Brave API) | Nachher (SearXNG) |
|-------------------|-------------------|
| ❌ $10+/Monat | ✅ **0€/Monat** |
| ❌ Rate Limits | ✅ **Unbegrenzt** |
| ❌ API-Key nötig | ✅ **Kein API-Key** |
| ❌ Externe Abhängigkeit | ✅ **100% Self-Hosted** |
| ❌ Nur Brave Results | ✅ **70+ Suchmaschinen** |

## 🚀 In 5 Minuten fertig

### 1. SearXNG Container starten
```bash
docker run -d \
  --name searxng \
  --restart unless-stopped \
  -p 8888:8080 \
  -e SEARXNG_BASE_URL=http://localhost:8888 \
  searxng/searxng:latest
```

### 2. JSON API aktivieren
```bash
docker exec searxng sed -i 's/formats:/formats:\\n  - json/' /etc/searxng/settings.yml
docker restart searxng
```

### 3. OpenClaw Plugin installieren
```bash
npx clawhub install searxng-local-search --force
```

### 4. Gateway neustarten
```bash
openclaw gateway restart
```

**Fertig!** Dein OpenClaw sucht jetzt über deine eigene SearXNG-Instanz.

## 🔧 Wie es funktioniert

```
┌─────────────┐    ┌─────────────┐    ┌─────────────────┐
│   OpenClaw  │───▶│   SearXNG   │───▶│ 70+ Suchmaschinen│
│    (KI)     │◀───│ (Aggregator)│◀───│ Google, DDG, ...│
└─────────────┘    └─────────────┘    └─────────────────┘
      │                    │                    │
      │ Self-Hosted        │ Privacy-Respecting │ Free to use
      │ 0€ Kosten          │ No Tracking        │ No API Keys
```

## 📊 Performance-Vergleich

**Test: "Flutter Android Auto 2025"**
- **Brave API (alt):** 10 Ergebnisse, $0.001 pro Suche
- **SearXNG (neu):** 27 Ergebnisse, **$0.000 pro Suche**

**Aggregierte Quellen:**
- ✅ Google (via Startpage)
- ✅ DuckDuckGo  
- ✅ Brave Search
- ✅ Bing
- ✅ 70+ weitere Engines

## 🛡️ Warum besser?

| Kriterium | Brave API | SearXNG |
|-----------|-----------|---------|
| **Kosten** | $10+/Monat | **0€** |
| **Privatsphäre** | Brave sieht deine Queries | **Nur du** siehst sie |
| **Redundanz** | Single Point of Failure | **Multi-Engine** |
| **Kontrolle** | Brave's Regeln | **Deine Regeln** |
| **Uptime** | Abhängig von Brave | **Deine Infrastruktur** |

## 🎭 Real-World Beispiel

**Vorher (mit Brave API):**
```bash
$ openclaw "Was ist das Wetter in Berlin?"
# ❌ "missing_brave_api_key" - $10 zahlen oder keine Suche
```

**Nachher (mit SearXNG):**
```bash
$ openclaw "Was ist das Wetter in Berlin?"
# ✅ 25 Ergebnisse von Wetter.com, DWD, Berlin.de, etc.
# ✅ Kosten: 0€
# ✅ Privacy: Deine Daten bleiben lokal
```

## 📈 Für wen ist das?

- **💰 Sparfüchse:** Keine API-Kosten mehr
- **🛡️ Privacy-Nerds:** Deine Queries bleiben lokal
- **⚙️ Self-Hoster:** 100% Kontrolle über deine Infrastruktur
- **🔧 Tüftler:** Customize deine Search-Engines
- **🚀 Early Adopters:** Bleib unabhängig von API-Änderungen

## 🚨 Wichtiger Hinweis

**"Brave" in der Config ≠ Brave API mehr!**
- **Vorher:** `provider: "brave"` = Bezahlte Brave Search API
- **Nachher:** `provider: "searxng"` = SearXNG scraped Brave Search (kostenlos!)

## 📚 Vollständiges Tutorial

Siehe [SETUP.md](SETUP.md) für detaillierte Anleitung mit:
- Docker-Compose Setup
- Unraid Template
- Troubleshooting
- Monitoring & Logs
- Backup & Restore

## 🤝 Beitragen

Found a bug? Have improvements? PRs welcome!
- [GitHub Repo](https://github.com/darksoon/openclaw-searxng)
- [Issues](https://github.com/darksoon/openclaw-searxng/issues)
- [Discord](https://discord.gg/openclaw)

## 📢 Spread the Word

Like this setup? Share it!
- 🔄 Retweet our announcement
- ⭐ Star the GitHub repo  
- 💬 Join the Discord discussion
- 🐦 Tag @OpenClawAI & @SearXNG

---

**TL;DR:** Brave API tot? SearXNG + OpenClaw = Kostenlose, private, self-hosted Web-Suche für deinen KI-Assistenten. 5 Minuten Setup, 0€ Kosten. 🎉

*Getagged: #OpenClaw #SearXNG #SelfHosted #Privacy #Kostenlos #KI #AIAssistant #Docker #OpenSource*