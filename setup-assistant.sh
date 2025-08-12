#!/bin/bash

# IIB ESB Financial Applications - Quick Setup Validation (macOS ARM64/M2 Optimized)
# This script helps users choose the best setup option and validates prerequisites

set -e

echo "🎯 IIB ESB Financial Applications - Setup Assistant (macOS ARM64/M2 Optimized)"
echo "================================================================================"

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

echo -e "\n${CYAN}🖥️  Detected System: $OS $ARCH${NC}"
if [[ "$ARCH" == "arm64" ]]; then
    echo -e "${GREEN}✅ ARM64 (Apple Silicon M1/M2/M3) detected - optimized downloads will be used${NC}"
elif [[ "$ARCH" == "x86_64" ]]; then
    echo -e "${YELLOW}⚠️  Intel x64 detected - ARM64 downloads recommended for better performance${NC}"
else
    echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"
    exit 1
fi

echo -e "\n${BLUE}Choose your setup approach:${NC}"
echo "1. 🐳 Docker-based setup (Recommended - Fast & Easy)"
echo "2. 💻 Native installation (Advanced - Full Control)"
echo "3. 🔗 Verify download links only"
echo "4. ℹ️  Show system requirements"

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo -e "\n${CYAN}🐳 Docker-Based Setup Selected${NC}"
        echo "================================"
        
        # Check Docker
        if command -v docker &> /dev/null; then
            echo -e "${GREEN}✅ Docker found: $(docker --version)${NC}"
            
            # Check for Apple Silicon specific Docker setup
            if [[ "$ARCH" == "arm64" ]]; then
                echo -e "${BLUE}🍎 Apple Silicon detected - ensuring ARM64 image compatibility${NC}"
                if docker buildx version &> /dev/null; then
                    echo -e "${GREEN}✅ Docker Buildx available for multi-architecture support${NC}"
                else
                    echo -e "${YELLOW}⚠️  Docker Buildx not found - some ARM64 images may not work${NC}"
                fi
            fi
        else
            echo -e "${RED}❌ Docker not found${NC}"
            echo ""
            echo "📥 Download Docker Desktop for macOS:"
            if [[ "$ARCH" == "arm64" ]]; then
                echo "• macOS ARM64 (Apple Silicon): https://desktop.docker.com/mac/main/arm64/Docker.dmg"
                echo "• ⭐ RECOMMENDED for your M1/M2/M3 Mac"
            else
                echo "• macOS Intel: https://desktop.docker.com/mac/main/amd64/Docker.dmg"
            fi
            echo "• Windows: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
            echo "• Linux: https://docs.docker.com/engine/install/"
            exit 1
        fi
        
        # Check Docker Compose
        if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
            echo -e "${GREEN}✅ Docker Compose available${NC}"
        else
            echo -e "${RED}❌ Docker Compose not available${NC}"
            exit 1
        fi
        
        # Check Docker daemon
        if docker info &> /dev/null; then
            echo -e "${GREEN}✅ Docker daemon running${NC}"
        else
            echo -e "${RED}❌ Docker daemon not running${NC}"
            echo "Please start Docker Desktop and try again."
            exit 1
        fi
        
        # Check resources
        echo -e "\n${BLUE}🔍 Checking system resources...${NC}"
        MEMORY_GB=$(docker system info --format '{{.MemTotal}}' 2>/dev/null | awk '{print int($1/1024/1024/1024)}')
        if [ "$MEMORY_GB" -ge 8 ]; then
            echo -e "${GREEN}✅ Memory: ${MEMORY_GB}GB available${NC}"
        else
            echo -e "${YELLOW}⚠️  Warning: Only ${MEMORY_GB}GB memory available (8GB recommended)${NC}"
        fi
        
        echo -e "\n${GREEN}🚀 Ready for Docker setup!${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Run: ./quick-start.sh"
        echo "2. Wait 5-10 minutes for initialization"
        echo "3. Access applications:"
        echo "   • Payment API: http://localhost:7800"
        echo "   • Trading API: http://localhost:7801"
        echo "   • Grafana: http://localhost:3000"
        ;;
        
    2)
        echo -e "\n${CYAN}💻 Native Installation Selected${NC}"
        echo "==============================="
        echo ""
        echo "📖 Please refer to: documentation/DOWNLOAD_LINKS_GUIDE.md"
        echo ""
        echo "🔗 Active download links:"
        echo ""
        echo "${YELLOW}IBM Software:${NC}"
        echo "• ACE Developer (Linux): https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/IMA/0aj9z/0/12.0.3.0-ACE-LINUX64-DEVELOPER.tar.gz"
        echo "• ACE Developer (Windows): https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/IMA/0aj9z/0/12.0.3.0-ACE-WIN64-DEVELOPER.exe"
        if [[ "$ARCH" == "arm64" ]]; then
            echo "• MQ Developer (macOS ARM64): https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev934_mac_arm64.pkg ⭐ RECOMMENDED"
            echo "• MQ Developer (macOS Intel): https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev934_mac_x86-64.pkg"
        else
            echo "• MQ Developer (macOS Intel): https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev934_mac_x86-64.pkg"
            echo "• MQ Developer (macOS ARM64): https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev934_mac_arm64.pkg"
        fi
        echo ""
        echo "${YELLOW}Databases:${NC}"
        echo "• Oracle XE (Linux): https://download.oracle.com/otn-pub/otn_software/db-express/oracle-database-xe-21c-1.0-1.ol7.x86_64.rpm"
        if [[ "$ARCH" == "arm64" ]]; then
            echo "• PostgreSQL (macOS ARM64): https://get.enterprisedb.com/postgresql/postgresql-15.5-1-osx-arm64.dmg ⭐ RECOMMENDED"
            echo "• PostgreSQL (macOS Intel): https://get.enterprisedb.com/postgresql/postgresql-15.5-1-osx.dmg"
            echo "• InfluxDB (macOS ARM64): https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4_darwin_arm64.tar.gz ⭐ RECOMMENDED"
        else
            echo "• PostgreSQL (macOS Intel): https://get.enterprisedb.com/postgresql/postgresql-15.5-1-osx.dmg"
            echo "• InfluxDB (macOS Intel): https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4_darwin_amd64.tar.gz"
        fi
        echo ""
        echo "⏱️  Estimated installation time: 2-3 hours"
        ;;
        
    3)
        echo -e "\n${CYAN}🔗 Verifying Download Links${NC}"
        echo "============================"
        ./scripts/verify-download-links.sh
        ;;
        
    4)
        echo -e "\n${CYAN}ℹ️  System Requirements${NC}"
        echo "======================"
        echo ""
        echo "${YELLOW}Docker-Based Setup:${NC}"
        echo "• CPU: 4+ cores recommended"
        echo "• RAM: 16GB minimum, 32GB recommended"
        echo "• Storage: 100GB free space"
        echo "• Network: Internet connection for image downloads"
        echo "• Docker Desktop 4.25.0+"
        echo ""
        echo "${YELLOW}Native Installation:${NC}"
        echo "• CPU: 8+ cores recommended"
        echo "• RAM: 32GB minimum, 64GB recommended"
        echo "• Storage: 200GB free space"
        echo "• Network: Internet for downloads"
        echo "• IBM ACE 12.0.3.0"
        echo "• IBM MQ 9.3.4"
        echo "• Oracle XE 21c / PostgreSQL 15 / InfluxDB 2.7"
        echo "• ELK Stack 8.11.0"
        echo "• Prometheus 2.47.0 / Grafana 10.2.0"
        echo ""
        echo "${YELLOW}Supported Platforms:${NC}"
        echo "• Linux x86_64 (RHEL 8+, Ubuntu 20.04+)"
        echo "• Windows 10/11 Professional"
        echo "• macOS 12+ (Intel and Apple Silicon)"
        echo ""
        echo "${YELLOW}Network Requirements:${NC}"
        echo "• Ports 7600-7801, 8086, 9090, 3000, 5601, 9200"
        echo "• Internet access for downloading images/software"
        echo "• Corporate firewall may need configuration"
        ;;
        
    *)
        echo -e "${RED}Invalid choice. Please run the script again and select 1-4.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}📚 Additional Resources:${NC}"
echo "• Full documentation: documentation/"
echo "• Architecture diagrams: documentation/ARCHITECTURE_DIAGRAMS.md"
echo "• Error logging system: documentation/ERROR_LOGGING_SYSTEM.md"
echo "• Local setup guide: LOCAL_SETUP_GUIDE.md"
echo ""
echo -e "${GREEN}Happy Integration! 🚀${NC}"
