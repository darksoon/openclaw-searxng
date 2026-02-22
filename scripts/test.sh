#!/bin/bash
# Test script for OpenClaw + SearXNG setup

set -e

echo "🧪 OpenClaw + SearXNG Test Suite"
echo "================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper functions
pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

fail() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Test 1: Docker availability
test_docker() {
    info "Test 1: Checking Docker..."
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
        pass "Docker installed ($DOCKER_VERSION)"
    else
        fail "Docker not installed"
    fi
}

# Test 2: Docker Compose availability
test_docker_compose() {
    info "Test 2: Checking Docker Compose..."
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | tr -d ',')
        pass "Docker Compose installed ($COMPOSE_VERSION)"
    elif docker compose version &> /dev/null; then
        pass "Docker Compose (plugin) available"
    else
        fail "Docker Compose not installed"
    fi
}

# Test 3: Port availability
test_ports() {
    info "Test 3: Checking port availability..."
    
    # Check port 8888 (SearXNG)
    if lsof -i:8888 > /dev/null 2>&1; then
        fail "Port 8888 is already in use"
    else
        pass "Port 8888 is free"
    fi
    
    # Check port 18789 (OpenClaw)
    if lsof -i:18789 > /dev/null 2>&1; then
        fail "Port 18789 is already in use"
    else
        pass "Port 18789 is free"
    fi
}

# Test 4: Network connectivity
test_network() {
    info "Test 4: Testing network connectivity..."
    
    if curl -s --connect-timeout 5 https://github.com > /dev/null; then
        pass "Network connectivity OK"
    else
        fail "No network connectivity"
    fi
}

# Test 5: Required tools
test_tools() {
    info "Test 5: Checking required tools..."
    
    local tools=("curl" "git" "openssl")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        pass "All required tools available"
    else
        fail "Missing tools: ${missing[*]}"
    fi
}

# Test 6: Environment setup
test_environment() {
    info "Test 6: Testing environment setup..."
    
    # Create test directory
    TEST_DIR="/tmp/openclaw-test-$(date +%s)"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR" || exit 1
    
    # Copy docker-compose.yml
    cp "$(dirname "$0")/../docker-compose.yml" .
    
    # Generate .env
    cat > .env << EOF
SEARXNG_SECRET=test-secret-$(openssl rand -hex 16)
GATEWAY_TOKEN=test-token-$(openssl rand -hex 16)
SEARXNG_URL=http://localhost:8888
EOF
    
    if [ -f docker-compose.yml ] && [ -f .env ]; then
        pass "Environment setup successful"
    else
        fail "Environment setup failed"
    fi
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$TEST_DIR"
}

# Test 7: Docker image availability
test_docker_images() {
    info "Test 7: Checking Docker image availability..."
    
    # Check if we can pull images
    if docker pull searxng/searxng:latest --quiet > /dev/null 2>&1; then
        pass "SearXNG image available"
    else
        fail "Cannot pull SearXNG image"
    fi
    
    if docker pull ghcr.io/openclaw/openclaw:main --quiet > /dev/null 2>&1; then
        pass "OpenClaw image available"
    else
        fail "Cannot pull OpenClaw image"
    fi
}

# Test 8: System resources
test_resources() {
    info "Test 8: Checking system resources..."
    
    # Check memory (need at least 1GB free)
    FREE_MEM=$(free -m | awk '/^Mem:/{print $7}')
    if [ "$FREE_MEM" -gt 1024 ]; then
        pass "Sufficient memory available (${FREE_MEM}MB free)"
    else
        fail "Insufficient memory (${FREE_MEM}MB free, need 1024MB)"
    fi
    
    # Check disk space (need at least 2GB free)
    FREE_DISK=$(df -BG . | awk 'NR==2{print $4}' | tr -d 'G')
    if [ "$FREE_DISK" -gt 2 ]; then
        pass "Sufficient disk space (${FREE_DISK}GB free)"
    else
        fail "Insufficient disk space (${FREE_DISK}GB free, need 2GB)"
    fi
}

# Test 9: User permissions
test_permissions() {
    info "Test 9: Checking user permissions..."
    
    # Check if user can run docker without sudo
    if docker ps > /dev/null 2>&1; then
        pass "User has Docker permissions"
    else
        fail "User lacks Docker permissions (try adding to docker group)"
    fi
    
    # Check write permissions in current directory
    if [ -w . ]; then
        pass "Write permissions in current directory"
    else
        fail "No write permissions in current directory"
    fi
}

# Test 10: Firewall/security
test_firewall() {
    info "Test 10: Checking firewall/security..."
    
    # Check if Docker can create networks
    if docker network create test-network --driver bridge > /dev/null 2>&1; then
        docker network rm test-network > /dev/null 2>&1
        pass "Docker network creation allowed"
    else
        fail "Docker network creation blocked (check firewall)"
    fi
}

# Run all tests
run_all_tests() {
    echo "Running comprehensive test suite..."
    echo ""
    
    test_docker
    test_docker_compose
    test_ports
    test_network
    test_tools
    test_environment
    test_docker_images
    test_resources
    test_permissions
    test_firewall
    
    echo ""
    echo "================================="
    echo "Test Results:"
    echo "  Total tests: $TESTS_TOTAL"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! Your system is ready for OpenClaw + SearXNG.${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Run: ./scripts/setup.sh"
        echo "  2. Follow the setup instructions"
        echo "  3. Start using free web search!"
        return 0
    else
        echo -e "${RED}⚠️  Some tests failed. Please fix the issues above before proceeding.${NC}"
        echo ""
        echo "Common solutions:"
        echo "  • Install missing tools: sudo apt install docker docker-compose curl"
        echo "  • Add user to docker group: sudo usermod -aG docker \$USER"
        echo "  • Free up ports: kill processes using 8888 or 18789"
        echo "  • Check firewall: sudo ufw allow 8888,18789"
        return 1
    fi
}

# Quick test (basic checks only)
run_quick_test() {
    echo "Running quick test..."
    echo ""
    
    test_docker
    test_docker_compose
    test_ports
    test_network
    
    echo ""
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ Quick test passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Quick test failed${NC}"
        return 1
    fi
}

# Parse command line arguments
case "${1:-}" in
    "--quick"|"-q")
        run_quick_test
        ;;
    "--help"|"-h")
        echo "Usage: ./test.sh [OPTION]"
        echo ""
        echo "Options:"
        echo "  --quick, -q    Run quick test (basic checks only)"
        echo "  --help, -h     Show this help message"
        echo "  (no option)    Run comprehensive test suite"
        ;;
    *)
        run_all_tests
        ;;
esac

exit $?