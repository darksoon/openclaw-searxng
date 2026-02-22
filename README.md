# 🦞🔍 OpenClaw + SearXNG: Free Web Search for Your AI Assistant

**Brave killed its Free Tier? No problem!** Here's the solution: Self-hosted SearXNG + OpenClaw = **completely free web search** for your AI assistant.

🌍 **Choose your language:** [English](#-openclaw--searxng-free-web-search-for-your-ai-assistant) | [Deutsch](README_DE.md)

![OpenClaw + SearXNG](https://img.shields.io/badge/OpenClaw-SearXNG-blue)
![Free](https://img.shields.io/badge/Free-0€-green)
![Self-Hosted](https://img.shields.io/badge/Self--Hosted-Privacy-orange)

## 🎯 What You Get

| Before (Brave API) | After (SearXNG) |
|-------------------|-------------------|
| ❌ $10+/Month | ✅ **$0/Month** |
| ❌ Rate Limits | ✅ **Unlimited** |
| ❌ API Key Required | ✅ **No API Key** |
| ❌ External Dependency | ✅ **100% Self-Hosted** |
| ❌ Only Brave Results | ✅ **70+ Search Engines** |

## 🚀 Ready in 5 Minutes

### 1. Start SearXNG Container
```bash
docker run -d \
  --name searxng \
  --restart unless-stopped \
  -p 8888:8080 \
  -e SEARXNG_BASE_URL=http://localhost:8888 \
  searxng/searxng:latest
```

### 2. Enable JSON API
```bash
docker exec searxng sed -i 's/formats:/formats:\\n  - json/' /etc/searxng/settings.yml
docker restart searxng
```

### 3. Install OpenClaw Plugin
```bash
npx clawhub install searxng-local-search --force
```

### 4. Restart Gateway
```bash
openclaw gateway restart
```

**Done!** Your OpenClaw now searches through your own SearXNG instance.

## 🔧 How It Works

```
┌─────────────┐    ┌─────────────┐    ┌─────────────────┐
│   OpenClaw  │───▶│   SearXNG   │───▶│ 70+ Search Engines│
│    (AI)     │◀───│ (Aggregator)│◀───│ Google, DDG, ...│
└─────────────┘    └─────────────┘    └─────────────────┘
      │                    │                    │
      │ Self-Hosted        │ Privacy-Respecting │ Free to use
      │ $0 Cost            │ No Tracking        │ No API Keys
```

## 📊 Performance Comparison

**Test: "Flutter Android Auto 2025"**
- **Brave API (old):** 10 results, $0.001 per search
- **SearXNG (new):** 27 results, **$0.000 per search**

**Aggregated Sources:**
- ✅ Google (via Startpage)
- ✅ DuckDuckGo  
- ✅ Brave Search
- ✅ Bing
- ✅ 70+ more engines

## 🛡️ Why Better?

| Criteria | Brave API | SearXNG |
|-----------|-----------|---------|
| **Cost** | $10+/Month | **$0** |
| **Privacy** | Brave sees your queries | **Only you** see them |
| **Redundancy** | Single Point of Failure | **Multi-Engine** |
| **Control** | Brave's Rules | **Your Rules** |
| **Uptime** | Depends on Brave | **Your Infrastructure** |

## 🎭 Real-World Example

**Before (with Brave API):**
```bash
$ openclaw "What's the weather in Berlin?"
# ❌ "missing_brave_api_key" - pay $10 or no search
```

**After (with SearXNG):**
```bash
$ openclaw "What's the weather in Berlin?"
# ✅ 25 results from Wetter.com, DWD, Berlin.de, etc.
# ✅ Cost: $0
# ✅ Privacy: Your data stays local
```

## 📈 Who Is This For?

- **💰 Cost Savers:** No more API costs
- **🛡️ Privacy Nerds:** Your queries stay local
- **⚙️ Self-Hosters:** 100% control over your infrastructure
- **🔧 Tinkerers:** Customize your search engines
- **🚀 Early Adopters:** Stay independent from API changes

## 🚨 Important Note

**"Brave" in Config ≠ Brave API Anymore!**
- **Before:** `provider: "brave"` = Paid Brave Search API
- **After:** `provider: "searxng"` = SearXNG scrapes Brave Search (free!)

## 📚 Complete Tutorial

See [SETUP.md](SETUP.md) for detailed guide with:
- Docker-Compose Setup
- Unraid Template
- Troubleshooting
- Monitoring & Logs
- Backup & Restore

## 🤝 Contributing

Found a bug? Have improvements? PRs welcome!
- [GitHub Repo](https://github.com/darksoon/openclaw-searxng)
- [Issues](https://github.com/darksoon/openclaw-searxng/issues)

## 📢 Spread the Word

Like this setup? Share it!
- 🔄 Retweet our announcement
- ⭐ Star the GitHub repo  
- 💬 Join the Discord discussion
- 🐦 Tag @OpenClawAI & @SearXNG

---

**TL;DR:** Brave API dead? SearXNG + OpenClaw = Free, private, self-hosted web search for your AI assistant. 5 minute setup, $0 cost. 🎉

*Tagged: #OpenClaw #SearXNG #SelfHosted #Privacy #Free #AI #AIAssistant #Docker #OpenSource*
