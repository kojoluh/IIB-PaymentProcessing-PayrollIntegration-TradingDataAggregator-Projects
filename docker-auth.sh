#!/bin/bash

# Docker Authentication Helper Script for IIB ESB
# This script helps authenticate with various Docker registries

echo "🔐 Docker Registry Authentication Helper"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\n${BLUE}Available authentication options:${NC}"
echo "1. IBM Container Registry (icr.io)"
echo "2. Oracle Container Registry"
echo "3. Docker Hub (for private repos)"
echo "4. Check current authentication status"
echo "5. Logout from all registries"

read -p "Choose an option (1-5): " choice

case $choice in
    1)
        echo -e "\n${CYAN}🔵 IBM Container Registry Authentication${NC}"
        echo "For IBM software (ACE, MQ), you need an IBM ID:"
        echo "1. Create free IBM ID at: https://www.ibm.com/account/"
        echo "2. Login to IBM Container Registry:"
        echo ""
        echo "Command to run:"
        echo -e "${YELLOW}docker login icr.io${NC}"
        echo ""
        echo "Username: Your IBM ID email"
        echo "Password: Your IBM ID password or API key"
        echo ""
        read -p "Do you want to login now? (y/n): " login_ibm
        if [[ "$login_ibm" == "y" || "$login_ibm" == "Y" ]]; then
            docker login icr.io
        fi
        ;;
        
    2)
        echo -e "\n${CYAN}🔴 Oracle Container Registry Authentication${NC}"
        echo "For Oracle Database images, you need an Oracle account:"
        echo "1. Create free Oracle account at: https://profile.oracle.com/myprofile/account/create-account.jspx"
        echo "2. Accept Oracle Standard Terms at: https://container-registry.oracle.com/"
        echo "3. Login to Oracle Container Registry:"
        echo ""
        echo "Command to run:"
        echo -e "${YELLOW}docker login container-registry.oracle.com${NC}"
        echo ""
        echo "Username: Your Oracle account username"
        echo "Password: Your Oracle account password"
        echo ""
        read -p "Do you want to login now? (y/n): " login_oracle
        if [[ "$login_oracle" == "y" || "$login_oracle" == "Y" ]]; then
            docker login container-registry.oracle.com
        fi
        ;;
        
    3)
        echo -e "\n${CYAN}🐳 Docker Hub Authentication${NC}"
        echo "For private Docker Hub repositories:"
        echo ""
        echo "Command to run:"
        echo -e "${YELLOW}docker login${NC}"
        echo ""
        echo "Username: Your Docker Hub username"
        echo "Password: Your Docker Hub password or access token"
        echo ""
        read -p "Do you want to login now? (y/n): " login_docker
        if [[ "$login_docker" == "y" || "$login_docker" == "Y" ]]; then
            docker login
        fi
        ;;
        
    4)
        echo -e "\n${BLUE}🔍 Current Authentication Status${NC}"
        echo "Checking authentication for various registries..."
        echo ""
        
        # Check Docker Hub
        if docker system info | grep -q "Username:"; then
            echo -e "Docker Hub: ${GREEN}✅ Authenticated${NC}"
            docker system info | grep "Username:"
        else
            echo -e "Docker Hub: ${YELLOW}⚠️  Not authenticated${NC}"
        fi
        
        # Check IBM Container Registry
        if docker system info 2>/dev/null | grep -q "icr.io"; then
            echo -e "IBM Registry (icr.io): ${GREEN}✅ Authenticated${NC}"
        else
            echo -e "IBM Registry (icr.io): ${YELLOW}⚠️  Not authenticated${NC}"
        fi
        
        # Check Oracle Container Registry
        if docker system info 2>/dev/null | grep -q "container-registry.oracle.com"; then
            echo -e "Oracle Registry: ${GREEN}✅ Authenticated${NC}"
        else
            echo -e "Oracle Registry: ${YELLOW}⚠️  Not authenticated${NC}"
        fi
        
        echo ""
        echo "Registry credentials are stored in:"
        echo "• macOS: ~/.docker/config.json"
        echo "• Linux: ~/.docker/config.json"
        echo "• Windows: %USERPROFILE%\\.docker\\config.json"
        ;;
        
    5)
        echo -e "\n${YELLOW}🚪 Logging out from all registries${NC}"
        echo "This will remove all stored Docker registry credentials."
        read -p "Are you sure? (y/n): " confirm_logout
        if [[ "$confirm_logout" == "y" || "$confirm_logout" == "Y" ]]; then
            docker logout
            docker logout icr.io 2>/dev/null || true
            docker logout container-registry.oracle.com 2>/dev/null || true
            echo -e "${GREEN}✅ Logged out from all registries${NC}"
        fi
        ;;
        
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "\n${BLUE}💡 Authentication Tips:${NC}"
echo "• Credentials are stored securely in Docker config"
echo "• Use API keys/tokens instead of passwords when possible"
echo "• For CI/CD, use service accounts or dedicated tokens"
echo "• Authentication persists until you logout or credentials expire"

echo -e "\n${GREEN}✅ Authentication helper complete!${NC}"
