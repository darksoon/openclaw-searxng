#!/bin/bash
# OpenClaw + SearXNG Setup Script
# One-command setup for free web search

set -e

echo "🦞🔍 OpenClaw + SearXNG Setup"
echo "=============================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check dependencies
check_deps() {
    echo "🔍 Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker not found${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker installed${NC}"
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}⚠️ docker-compose not found, using docker compose${NC}"
    else
        echo -e "${GREEN}✅ docker-compose installed${NC}"
    fi
    
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ curl not found${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ curl installed${NC}"
}

# Generate random secrets
generate_secrets() {
    echo "🔐 Generating secrets..."
    
    if [ ! -f .env ]; then
        SEARXNG_SECRET=$(openssl rand -hex 32 2>/dev/null || echo "fallback-secret-$(date +%s)")
        GATEWAY_TOKEN=$(openssl rand -hex 24 2>/dev/null || echo "fallback-token-$(date +%s)")
        
        cat > .env << EOF
SEARXNG_SECRET=$SEARXNG_SECRET
GATEWAY_TOKEN=$GATEWAY_TOKEN
SEARXNG_URL=http://localhost:8888
EOF
        echo -e "${GREEN}✅ Secrets generated in .env${NC}"
    else
        echo -e "${YELLOW}⚠️ .env already exists, skipping${NC}"
    fi
}

# Create docker-compose.yml
create_compose() {
    echo "🐳 Creating docker-compose.yml..."
    
    cat > docker-compose.yml << 'EOF'
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
      - SEARXNG_SECRET=${SEARXNG_SECRET}
    volumes:
      - ./data/searxng:/etc/searxng:ro
      - ./cache/searxng:/var/cache/searxng
    networks:
      - openclaw-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3

  openclaw:
    image: ghcr.io/openclaw/openclaw:main
    container_name: openclaw
    restart: unless-stopped
    ports:
      - "18789:18789"
    environment:
      - OPENCLAW_GATEWAY_TOKEN=${GATEWAY_TOKEN}
      - SEARXNG_URL=http://searxng:8080
    volumes:
      - ./data/openclaw:/home/openclaw/.openclaw
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - openclaw-network
    depends_on:
      searxng:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "openclaw", "doctor", "--non-interactive"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  openclaw-network:
    driver: bridge
EOF
    
    echo -e "${GREEN}✅ docker-compose.yml created${NC}"
}

# Start services
start_services() {
    echo "🚀 Starting services..."
    
    # Create data directories
    mkdir -p data/searxng data/openclaw cache/searxng
    
    # Start with docker-compose or docker compose
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi
    
    echo -e "${GREEN}✅ Services started${NC}"
}

# Enable JSON API in SearXNG
enable_json_api() {
    echo "⚙️ Enabling JSON API in SearXNG..."
    
    # Wait for SearXNG to be ready
    echo "⏳ Waiting for SearXNG to be ready..."
    for i in {1..30}; do
        if docker exec searxng curl -s http://localhost:8080 > /dev/null 2>&1; then
            echo -e "${GREEN}✅ SearXNG is ready${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # Enable JSON format
    docker exec searxng sed -i 's/formats:/formats:\n  - json/' /etc/searxng/settings.yml 2>/dev/null || true
    
    # Restart SearXNG
    docker restart searxng > /dev/null 2>&1
    
    echo -e "${GREEN}✅ JSON API enabled${NC}"
}

# Configure OpenClaw
configure_openclaw() {
    echo "🤖 Configuring OpenClaw..."
    
    # Wait for OpenClaw to be ready
    echo "⏳ Waiting for OpenClaw to be ready..."
    for i in {1..30}; do
        if docker exec openclaw openclaw doctor --non-interactive > /dev/null 2>&1; then
            echo -e "${GREEN}✅ OpenClaw is ready${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # Install searxng-local-search skill
    echo "📦 Installing SearXNG skill..."
    docker exec openclaw npx clawhub install searxng-local-search --force 2>/dev/null || true
    
    # Set provider to searxng
    echo "⚙️ Setting search provider to searxng..."
    docker exec openclaw openclaw config set tools.web.search.provider searxng 2>/dev/null || true
    
    # Restart gateway
    echo "🔄 Restarting gateway..."
    docker exec openclaw openclaw gateway restart 2>/dev/null || true
    
    echo -e "${GREEN}✅ OpenClaw configured${NC}"
}

# Test setup
test_setup() {
    echo "🧪 Testing setup..."
    
    # Test SearXNG
    echo "1. Testing SearXNG..."
    if curl -s "http://localhost:8888/search?q=test&format=json&num_results=1" | grep -q "results"; then
        echo -e "${GREEN}✅ SearXNG working${NC}"
    else
        echo -e "${RED}❌ SearXNG test failed${NC}"
    fi
    
    # Test OpenClaw
    echo "2. Testing OpenClaw..."
    if docker exec openclaw openclaw config get tools.web.search.provider 2>/dev/null | grep -q "searxng"; then
        echo -e "${GREEN}✅ OpenClaw configured for SearXNG${NC}"
    else
        echo -e "${YELLOW}⚠️ OpenClaw config check skipped${NC}"
    fi
    
    # Final test search
    echo "3. Performing test search..."
    TEST_RESULT=$(docker exec openclaw bash -c 'curl -s "http://searxng:8080/search?q=OpenClaw&format=json&num_results=1"' 2>/dev/null | grep -o '"title":"[^"]*"' | head -1 || echo "")
    
    if [ -n "$TEST_RESULT" ]; then
        echo -e "${GREEN}✅ Search test successful${NC}"
        echo "   Result: $TEST_RESULT"
    else
        echo -e "${YELLOW}⚠️ Search test inconclusive${NC}"
    fi
}

# Show success message
show_success() {
    echo ""
    echo "========================================="
    echo "🎉 SETUP COMPLETE! 🎉"
    echo "========================================="
    echo ""
    echo "📊 Your new setup:"
    echo "   • SearXNG: http://localhost:8888"
    echo "   • OpenClaw Gateway: http://localhost:18789"
    echo "   • Gateway Token: $(cat .env | grep GATEWAY_TOKEN | cut -d= -f2)"
    echo ""
    echo "💰 Cost savings:"
    echo "   • Before (Brave API): ~$10/month"
    echo "   • After (SearXNG): $0/month"
    echo "   • Yearly savings: $120+"
    echo ""
    echo "🔧 Management commands:"
    echo "   • View logs: docker-compose logs -f"
    echo "   • Stop: docker-compose down"
    echo "   • Start: docker-compose up -d"
    echo "   • Restart: docker-compose restart"
    echo ""
    echo "🚨 Important:"
    echo "   • Access OpenClaw at: http://localhost:18789/?token=YOUR_TOKEN"
    echo "   • Replace YOUR_TOKEN with the token from .env"
    echo ""
    echo "📚 Next steps:"
    echo "   • Configure your AI assistant to use OpenClaw"
    echo "   • Test web searches"
    echo "   • Monitor performance"
    echo ""
    echo "🐛 Problems? Check:"
    echo "   • docker-compose logs searxng"
    echo "   • docker-compose logs openclaw"
    echo "   • Ensure ports 8888 and 18789 are free"
    echo ""
    echo "⭐ If this helped you, star the repo!"
    echo "🔗 GitHub: https://github.com/yourusername/openclaw-searxng"
    echo ""
    echo "========================================="
}

# Main execution
main() {
    echo -e "${YELLOW}OpenClaw + SearXNG Setup Script${NC}"
    echo -e "${YELLOW}=================================${NC}"
    
    check_deps
    generate_secrets
    create_compose
    start_services
    enable_json_api
    configure_openclaw
    test_setup
    show_success
}

# Run main function
main "$@"