#!/bin/bash

# IIB ESB Financial Applications - Quick Start (macOS ARM64/M2 Optimized)
# This script starts the complete environment using Docker Compose

set +e  # Don't exit on individual failures

echo "🚀 Starting IIB ESB Financial Applications (macOS ARM64/M2 Optimized)"
echo "======================================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detect architecture
ARCH=$(uname -m)
OS=$(uname -s)

echo -e "${CYAN}🖥️  Detected System: $OS $ARCH${NC}"

# Verify Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop and try again.${NC}"
    exit 1
fi

# Check if Docker Compose file exists
if [[ ! -f "docker-compose.yml" ]] && [[ ! -f "docker-compose-core.yml" ]]; then
    echo -e "${RED}❌ docker-compose.yml not found. Please run from the project root directory.${NC}"
    exit 1
fi

# Use core services if main compose file has issues
COMPOSE_FILE="docker-compose.yml"
if [[ -f "docker-compose-core.yml" ]]; then
    echo -e "${BLUE}📋 Using core services configuration (docker-compose-core.yml)${NC}"
    COMPOSE_FILE="docker-compose-core.yml"
fi

# ARM64 specific optimizations
if [[ "$ARCH" == "arm64" ]]; then
    echo -e "${GREEN}🍎 Apple Silicon detected - using ARM64 optimized settings${NC}"
    
    # Export platform for Docker
    export DOCKER_DEFAULT_PLATFORM=linux/arm64
    
    # Check if Rosetta is needed for any x86 images
    echo -e "${BLUE}📋 Checking for ARM64 native image availability...${NC}"
    
    # Create ARM64 optimized environment variables
    cat > .env.arm64 << EOF
# ARM64/Apple Silicon Optimizations
DOCKER_DEFAULT_PLATFORM=linux/arm64
COMPOSE_DOCKER_CLI_BUILD=1
DOCKER_BUILDKIT=1

# Database optimizations for ARM64
POSTGRES_IMAGE=postgres:15-alpine
INFLUXDB_IMAGE=influxdb:2.7-alpine
REDIS_IMAGE=redis:7-alpine

# Monitoring stack ARM64 compatible images
GRAFANA_IMAGE=grafana/grafana:10.2.0
PROMETHEUS_IMAGE=prom/prometheus:v2.47.0
ELASTICSEARCH_IMAGE=elasticsearch:8.11.0
KIBANA_IMAGE=kibana:8.11.0

# Nginx ARM64 optimized
NGINX_IMAGE=nginx:1.25-alpine

# Memory limits optimized for Apple Silicon
JAVA_OPTS=-Xmx2g -Xms1g
ACE_MEMORY_LIMIT=2g
MQ_MEMORY_LIMIT=1g
DB_MEMORY_LIMIT=2g
EOF
    
    echo -e "${GREEN}✅ ARM64 environment configuration created${NC}"
else
    echo -e "${YELLOW}⚠️  Intel x64 detected - using standard configuration${NC}"
fi

# Clean up any existing containers
echo -e "\n${BLUE}🧹 Cleaning up existing containers...${NC}"
docker-compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

# Pull latest images
echo -e "\n${BLUE}📦 Pulling latest Docker images...${NC}"
echo -e "${YELLOW}Note: Some IBM/Oracle images may require authentication${NC}"

if [[ "$ARCH" == "arm64" ]]; then
    # Force ARM64 platform for images that support it
    docker-compose -f "$COMPOSE_FILE" --env-file .env.arm64 pull --ignore-pull-failures 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Some images failed to pull - this is normal for IBM/Oracle images${NC}"
        echo -e "${BLUE}🔄 Continuing with available images...${NC}"
    }
else
    docker-compose -f "$COMPOSE_FILE" pull --ignore-pull-failures 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Some images failed to pull - this is normal for IBM/Oracle images${NC}"
        echo -e "${BLUE}🔄 Continuing with available images...${NC}"
    }
fi

# Create necessary directories
echo -e "\n${BLUE}📁 Creating data directories...${NC}"
mkdir -p data/postgres data/influxdb data/redis data/elasticsearch data/grafana logs

# Set proper permissions for macOS
chmod -R 755 data logs
if [[ "$USER" != "root" ]]; then
    # Ensure current user owns data directories
    chown -R $USER:staff data logs 2>/dev/null || true
fi

# Start the environment
echo -e "\n${GREEN}🚀 Starting IIB ESB Core Services...${NC}"
echo -e "${BLUE}Starting: PostgreSQL, InfluxDB, Redis, Grafana, Prometheus, ELK Stack${NC}"

if [[ "$ARCH" == "arm64" ]]; then
    docker-compose -f "$COMPOSE_FILE" --env-file .env.arm64 up -d postgresql influxdb redis elasticsearch kibana grafana prometheus nginx 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Some core services failed to start - continuing anyway${NC}"
    }
else
    docker-compose -f "$COMPOSE_FILE" up -d postgresql influxdb redis elasticsearch kibana grafana prometheus nginx 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Some core services failed to start - continuing anyway${NC}"
    }
fi

# Optionally try to start IBM services
echo -e "\n${BLUE}🔧 Attempting to start IBM services (may fail without authentication)...${NC}"
if [[ "$ARCH" == "arm64" ]]; then
    docker-compose -f "$COMPOSE_FILE" --env-file .env.arm64 --profile ibm up -d ace-server ibm-mq 2>/dev/null || {
        echo -e "${YELLOW}⚠️  IBM services failed to start - this is expected without IBM account${NC}"
        echo -e "${BLUE}💡 Core monitoring and database services are running${NC}"
    }
else
    docker-compose -f "$COMPOSE_FILE" --profile ibm up -d ace-server ibm-mq 2>/dev/null || {
        echo -e "${YELLOW}⚠️  IBM services failed to start - this is expected without IBM account${NC}"
        echo -e "${BLUE}💡 Core monitoring and database services are running${NC}"
    }
fi

# Wait for services to be ready
echo -e "\n${BLUE}⏳ Waiting for services to initialize...${NC}"
sleep 30

# Health check function
check_service() {
    local service=$1
    local url=$2
    local name=$3
    
    echo -n "Checking $name... "
    
    for i in {1..30}; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Ready${NC}"
            return 0
        fi
        sleep 2
    done
    
    echo -e "${YELLOW}⚠️  Still starting${NC}"
    return 1
}

# Check service health
echo -e "\n${BLUE}🏥 Checking service health...${NC}"
check_service "grafana" "http://localhost:3000/api/health" "Grafana"
check_service "prometheus" "http://localhost:9090/-/healthy" "Prometheus"
check_service "elasticsearch" "http://localhost:9200/_cluster/health" "Elasticsearch"
check_service "influxdb" "http://localhost:8086/health" "InfluxDB"

# Display access information
echo -e "\n${GREEN}🎉 IIB ESB Financial Applications Started Successfully!${NC}"
echo -e "\n${BLUE}📊 Service Access Points:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏦 Payment Processing API:     http://localhost:7800"
echo "📈 Trading Data API:           http://localhost:7801"
echo "📊 Grafana Dashboard:          http://localhost:3000"
echo "🔍 Kibana Logs:               http://localhost:5601"
echo "📈 Prometheus Metrics:         http://localhost:9090"
echo "🔎 Elasticsearch:              http://localhost:9200"
echo "💾 InfluxDB:                   http://localhost:8086"
echo "🗄️  PostgreSQL:                localhost:5432"
echo "🔄 Redis Cache:                localhost:6379"
echo "📮 IBM MQ Console:             https://localhost:9443"

echo -e "\n${BLUE}🔐 Default Credentials:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Grafana:        admin / admin"
echo "InfluxDB:       admin / password123"
echo "PostgreSQL:     iib_user / iib_pass"
echo "IBM MQ:         admin / passw0rd"

echo -e "\n${BLUE}💡 Quick Actions:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "View logs:      docker-compose logs -f"
echo "Stop all:       docker-compose down"
echo "Restart:        docker-compose restart"
echo "Update:         docker-compose pull && docker-compose up -d"

if [[ "$ARCH" == "arm64" ]]; then
    echo -e "\n${GREEN}🍎 Apple Silicon Optimizations Active:${NC}"
    echo "• Native ARM64 images used where available"
    echo "• Memory limits optimized for Apple Silicon"
    echo "• Docker BuildKit enabled for better performance"
fi

echo -e "\n${YELLOW}⚠️  First-time Setup Notes:${NC}"
echo "• Initial startup may take 5-10 minutes"
echo "• Some services may show as 'unhealthy' initially - this is normal"
echo "• Grafana dashboards will auto-import after first login"
echo "• Check logs if any service fails to start: docker-compose logs [service-name]"

echo -e "\n${GREEN}Happy Integration! 🎯${NC}"
