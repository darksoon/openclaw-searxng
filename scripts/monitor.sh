#!/bin/bash
# Monitoring script for OpenClaw + SearXNG

set -e

echo "📊 OpenClaw + SearXNG Monitor"
echo "=============================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REFRESH_INTERVAL=${1:-5}  # seconds
LOG_FILE="./monitor.log"
MAX_LOG_LINES=1000

# Check if services are running
check_services() {
    echo -e "${BLUE}🔄 Checking services...${NC}"
    
    # Check SearXNG
    if docker ps --format '{{.Names}}' | grep -q '^searxng$'; then
        SEARXNG_STATUS="${GREEN}✅ RUNNING${NC}"
        SEARXNG_UPTIME=$(docker inspect --format='{{.State.StartedAt}}' searxng 2>/dev/null | xargs date -d 2>/dev/null +"%H:%M:%S" || echo "N/A")
    else
        SEARXNG_STATUS="${RED}❌ STOPPED${NC}"
        SEARXNG_UPTIME="N/A"
    fi
    
    # Check OpenClaw
    if docker ps --format '{{.Names}}' | grep -q '^openclaw$'; then
        OPENCLAW_STATUS="${GREEN}✅ RUNNING${NC}"
        OPENCLAW_UPTIME=$(docker inspect --format='{{.State.StartedAt}}' openclaw 2>/dev/null | xargs date -d 2>/dev/null +"%H:%M:%S" || echo "N/A")
    else
        OPENCLAW_STATUS="${RED}❌ STOPPED${NC}"
        OPENCLAW_UPTIME="N/A"
    fi
}

# Check resource usage
check_resources() {
    echo -e "${BLUE}📈 Checking resources...${NC}"
    
    # CPU and Memory
    SEARXNG_CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" searxng 2>/dev/null || echo "N/A")
    SEARXNG_MEM=$(docker stats --no-stream --format "{{.MemUsage}}" searxng 2>/dev/null | cut -d'/' -f1 | tr -d ' ' || echo "N/A")
    
    OPENCLAW_CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" openclaw 2>/dev/null || echo "N/A")
    OPENCLAW_MEM=$(docker stats --no-stream --format "{{.MemUsage}}" openclaw 2>/dev/null | cut -d'/' -f1 | tr -d ' ' || echo "N/A")
    
    # Disk usage
    DISK_USAGE=$(df -h . | awk 'NR==2{print $5}')
    
    # Network connections
    NET_CONNECTIONS=$(netstat -an | grep -c 'ESTABLISHED')
}

# Check service health
check_health() {
    echo -e "${BLUE}❤️  Checking health...${NC}"
    
    # SearXNG health
    if curl -s --max-time 5 "http://localhost:8888" > /dev/null; then
        SEARXNG_HEALTH="${GREEN}✅ HEALTHY${NC}"
    else
        SEARXNG_HEALTH="${RED}❌ UNHEALTHY${NC}"
    fi
    
    # OpenClaw health
    if docker exec openclaw openclaw doctor --non-interactive > /dev/null 2>&1; then
        OPENCLAW_HEALTH="${GREEN}✅ HEALTHY${NC}"
    else
        OPENCLAW_HEALTH="${RED}❌ UNHEALTHY${NC}"
    fi
    
    # Test search functionality
    if [ "$SEARXNG_HEALTH" = "${GREEN}✅ HEALTHY${NC}" ]; then
        SEARCH_TEST=$(curl -s --max-time 10 "http://localhost:8888/search?q=test&format=json&num_results=1" | grep -c '"results"' || echo "0")
        if [ "$SEARCH_TEST" -gt 0 ]; then
            SEARCH_STATUS="${GREEN}✅ WORKING${NC}"
        else
            SEARCH_STATUS="${YELLOW}⚠️  DEGRADED${NC}"
        fi
    else
        SEARCH_STATUS="${RED}❌ FAILED${NC}"
    fi
}

# Check logs for errors
check_logs() {
    echo -e "${BLUE}📝 Checking logs...${NC}"
    
    # Recent errors from SearXNG
    SEARXNG_ERRORS=$(docker logs searxng --tail 20 2>/dev/null | grep -i "error\|failed\|exception" | tail -3 || echo "No errors")
    
    # Recent errors from OpenClaw
    OPENCLAW_ERRORS=$(docker logs openclaw --tail 20 2>/dev/null | grep -i "error\|failed\|exception" | tail -3 || echo "No errors")
    
    # Count total errors in log file
    if [ -f "$LOG_FILE" ]; then
        TOTAL_ERRORS=$(grep -c -i "error\|failed\|exception" "$LOG_FILE" 2>/dev/null || echo "0")
    else
        TOTAL_ERRORS="0"
    fi
}

# Display dashboard
display_dashboard() {
    clear
    echo "=================================================="
    echo "           OPENCLAW + SEARXNG MONITOR            "
    echo "=================================================="
    echo " Last update: $(date '+%Y-%m-%d %H:%M:%S')"
    echo " Refresh: every ${REFRESH_INTERVAL}s"
    echo "=================================================="
    echo ""
    
    # Services status
    echo "📦 SERVICES STATUS"
    echo "──────────────────"
    printf "%-15s %-20s %-15s\n" "Service" "Status" "Uptime"
    printf "%-15s %-20s %-15s\n" "SearXNG" "$SEARXNG_STATUS" "$SEARXNG_UPTIME"
    printf "%-15s %-20s %-15s\n" "OpenClaw" "$OPENCLAW_STATUS" "$OPENCLAW_UPTIME"
    echo ""
    
    # Resource usage
    echo "📈 RESOURCE USAGE"
    echo "─────────────────"
    printf "%-15s %-15s %-15s\n" "Service" "CPU" "Memory"
    printf "%-15s %-15s %-15s\n" "SearXNG" "$SEARXNG_CPU" "$SEARXNG_MEM"
    printf "%-15s %-15s %-15s\n" "OpenClaw" "$OPENCLAW_CPU" "$OPENCLAW_MEM"
    printf "%-15s %-15s %-15s\n" "Disk" "$DISK_USAGE" "used"
    printf "%-15s %-15s\n" "Connections" "$NET_CONNECTIONS"
    echo ""
    
    # Health status
    echo "❤️  HEALTH STATUS"
    echo "────────────────"
    printf "%-15s %-20s\n" "Service" "Health"
    printf "%-15s %-20s\n" "SearXNG" "$SEARXNG_HEALTH"
    printf "%-15s %-20s\n" "OpenClaw" "$OPENCLAW_HEALTH"
    printf "%-15s %-20s\n" "Search" "$SEARCH_STATUS"
    echo ""
    
    # Recent errors
    echo "🚨 RECENT ERRORS"
    echo "────────────────"
    echo "SearXNG:"
    echo "  $SEARXNG_ERRORS" | sed 's/^/  /'
    echo ""
    echo "OpenClaw:"
    echo "  $OPENCLAW_ERRORS" | sed 's/^/  /'
    echo ""
    echo "Total errors in log: $TOTAL_ERRORS"
    echo ""
    
    # Quick actions
    echo "⚡ QUICK ACTIONS"
    echo "────────────────"
    echo "  [R] Restart services  [L] View logs  [S] Stop monitor"
    echo "  [T] Run test suite    [C] Clear logs [Q] Quit"
    echo ""
    echo "=================================================="
}

# Log current status
log_status() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local status_line="$timestamp | SearXNG: $SEARXNG_STATUS | OpenClaw: $OPENCLAW_STATUS | Search: $SEARCH_STATUS"
    
    # Append to log file
    echo "$status_line" >> "$LOG_FILE"
    
    # Trim log file if too large
    if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt $MAX_LOG_LINES ]; then
        tail -n $MAX_LOG_LINES "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

# Handle user input
handle_input() {
    read -t 1 -n 1 key 2>/dev/null || true
    
    case $key in
        r|R)
            echo -e "\n${YELLOW}🔄 Restarting services...${NC}"
            docker-compose restart
            sleep 5
            ;;
        l|L)
            echo -e "\n${YELLOW}📋 Showing logs...${NC}"
            echo "SearXNG logs (last 10 lines):"
            docker logs searxng --tail 10
            echo ""
            echo "OpenClaw logs (last 10 lines):"
            docker logs openclaw --tail 10
            echo ""
            read -p "Press Enter to continue..."
            ;;
        t|T)
            echo -e "\n${YELLOW}🧪 Running test suite...${NC}"
            ./scripts/test.sh --quick
            read -p "Press Enter to continue..."
            ;;
        c|C)
            echo -e "\n${YELLOW}🧹 Clearing log file...${NC}"
            > "$LOG_FILE"
            ;;
        s|S)
            echo -e "\n${YELLOW}🛑 Stopping monitor...${NC}"
            exit 0
            ;;
        q|Q)
            echo -e "\n${YELLOW}👋 Goodbye!${NC}"
            exit 0
            ;;
    esac
}

# Main monitoring loop
main() {
    echo "Starting monitor with ${REFRESH_INTERVAL}s refresh interval..."
    echo "Log file: $LOG_FILE"
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    while true; do
        check_services
        check_resources
        check_health
        check_logs
        display_dashboard
        log_status
        handle_input
        sleep "$REFRESH_INTERVAL"
    done
}

# Parse command line arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Usage: ./monitor.sh [REFRESH_INTERVAL]"
        echo ""
        echo "Monitor OpenClaw + SearXNG services"
        echo ""
        echo "Arguments:"
        echo "  REFRESH_INTERVAL  Refresh interval in seconds (default: 5)"
        echo ""
        echo "Controls:"
        echo "  R - Restart services"
        echo "  L - View logs"
        echo "  T - Run test suite"
        echo "  C - Clear logs"
        echo "  S - Stop monitor"
        echo "  Q - Quit"
        ;;
    *)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            REFRESH_INTERVAL=$1
        fi
        main
        ;;
esac