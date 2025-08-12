#!/bin/bash

# IIB ESB Financial Applications - Application Deployment Script
# This script deploys BAR files to the running ACE server

set -e

echo "📦 IIB Application Deployment Script"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if ACE server is running
check_ace_server() {
    echo -e "${BLUE}🔍 Checking ACE server status...${NC}"
    
    if ! docker ps | grep -q "ace-server"; then
        echo -e "${RED}❌ ACE server container is not running${NC}"
        echo "Please start the environment first with: ./quick-start.sh"
        exit 1
    fi
    
    # Wait for ACE to be ready
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec ace-server mqsilist > /dev/null 2>&1; then
            echo -e "${GREEN}✅ ACE server is ready${NC}"
            return 0
        fi
        echo -n "."
        sleep 5
        ((attempt++))
    done
    
    echo -e "${RED}❌ ACE server is not responding${NC}"
    exit 1
}

# List available BAR files
list_bar_files() {
    echo -e "${BLUE}📋 Available BAR files:${NC}"
    
    if [ ! -d "deployment/bars" ]; then
        mkdir -p deployment/bars
        echo -e "${YELLOW}⚠️  deployment/bars directory created${NC}"
        echo -e "${YELLOW}Please copy your BAR files to this directory${NC}"
        return 1
    fi
    
    local bar_count=0
    for bar_file in deployment/bars/*.bar; do
        if [ -f "$bar_file" ]; then
            filename=$(basename "$bar_file")
            echo -e "  📄 $filename"
            ((bar_count++))
        fi
    done
    
    if [ $bar_count -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No BAR files found in deployment/bars${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Found $bar_count BAR file(s)${NC}"
    return 0
}

# Deploy a single BAR file
deploy_bar_file() {
    local bar_file=$1
    local filename=$(basename "$bar_file")
    
    echo -e "${BLUE}📦 Deploying $filename...${NC}"
    
    # Copy BAR file to container if needed
    docker cp "$bar_file" ace-server:/home/aceuser/bars/
    
    # Deploy the application
    if docker exec ace-server bash -c "mqsideploy ACESERVER -a /home/aceuser/bars/$filename"; then
        echo -e "${GREEN}✅ Successfully deployed $filename${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to deploy $filename${NC}"
        return 1
    fi
}

# List deployed applications
list_deployed_applications() {
    echo -e "${BLUE}📋 Currently deployed applications:${NC}"
    
    if docker exec ace-server bash -c "mqsilist ACESERVER" 2>/dev/null; then
        echo -e "${GREEN}✅ Application list retrieved${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not retrieve application list${NC}"
    fi
}

# Undeploy an application
undeploy_application() {
    local app_name=$1
    
    echo -e "${BLUE}🗑️  Undeploying application: $app_name${NC}"
    
    if docker exec ace-server bash -c "mqsistop ACESERVER -e $app_name" 2>/dev/null; then
        if docker exec ace-server bash -c "mqsideploy ACESERVER -d $app_name" 2>/dev/null; then
            echo -e "${GREEN}✅ Successfully undeployed $app_name${NC}"
        else
            echo -e "${RED}❌ Failed to undeploy $app_name${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not stop $app_name (might not be running)${NC}"
    fi
}

# Show application status
show_application_status() {
    echo -e "${BLUE}📊 Application Status Report${NC}"
    echo -e "${BLUE}=============================${NC}"
    
    echo -e "${BLUE}Integration Server Status:${NC}"
    docker exec ace-server bash -c "mqsireportproperties ACESERVER" 2>/dev/null || true
    
    echo -e "\n${BLUE}Deployed Applications:${NC}"
    docker exec ace-server bash -c "mqsilist ACESERVER" 2>/dev/null || true
    
    echo -e "\n${BLUE}Message Flow Status:${NC}"
    docker exec ace-server bash -c "mqsireportproperties ACESERVER -o ComIbmJVMManager -r" 2>/dev/null || true
}

# Start/Stop applications
control_application() {
    local action=$1
    local app_name=$2
    
    case $action in
        start)
            echo -e "${BLUE}🚀 Starting application: $app_name${NC}"
            docker exec ace-server bash -c "mqsistart ACESERVER -e $app_name"
            ;;
        stop)
            echo -e "${BLUE}🛑 Stopping application: $app_name${NC}"
            docker exec ace-server bash -c "mqsistop ACESERVER -e $app_name"
            ;;
        restart)
            echo -e "${BLUE}🔄 Restarting application: $app_name${NC}"
            docker exec ace-server bash -c "mqsistop ACESERVER -e $app_name && mqsistart ACESERVER -e $app_name"
            ;;
    esac
}

# Show help
show_help() {
    echo "IIB Application Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy [bar-file]     Deploy a specific BAR file or all BAR files"
    echo "  list                  List deployed applications"
    echo "  status                Show detailed application status"
    echo "  undeploy <app-name>   Undeploy an application"
    echo "  start <app-name>      Start an application"
    echo "  stop <app-name>       Stop an application"
    echo "  restart <app-name>    Restart an application"
    echo "  help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy                                    # Deploy all BAR files"
    echo "  $0 deploy PaymentProcessingSystem.bar        # Deploy specific BAR file"
    echo "  $0 list                                      # List deployed apps"
    echo "  $0 status                                    # Show detailed status"
    echo "  $0 undeploy PaymentProcessingSystem          # Remove an app"
    echo "  $0 restart PaymentProcessingSystem           # Restart an app"
}

# Main execution
main() {
    local command=${1:-deploy}
    
    case $command in
        deploy)
            check_ace_server
            if [ -n "$2" ]; then
                # Deploy specific BAR file
                if [ -f "deployment/bars/$2" ]; then
                    deploy_bar_file "deployment/bars/$2"
                else
                    echo -e "${RED}❌ BAR file not found: deployment/bars/$2${NC}"
                    exit 1
                fi
            else
                # Deploy all BAR files
                if list_bar_files; then
                    local success_count=0
                    local total_count=0
                    
                    for bar_file in deployment/bars/*.bar; do
                        if [ -f "$bar_file" ]; then
                            ((total_count++))
                            if deploy_bar_file "$bar_file"; then
                                ((success_count++))
                            fi
                        fi
                    done
                    
                    echo -e "\n${GREEN}📊 Deployment Summary: $success_count/$total_count successful${NC}"
                    
                    if [ $success_count -gt 0 ]; then
                        echo -e "\n${BLUE}📋 Final application status:${NC}"
                        list_deployed_applications
                    fi
                else
                    echo -e "${YELLOW}No BAR files to deploy${NC}"
                    exit 1
                fi
            fi
            ;;
        list)
            check_ace_server
            list_deployed_applications
            ;;
        status)
            check_ace_server
            show_application_status
            ;;
        undeploy)
            if [ -n "$2" ]; then
                check_ace_server
                undeploy_application "$2"
            else
                echo -e "${RED}❌ Please specify application name${NC}"
                show_help
                exit 1
            fi
            ;;
        start|stop|restart)
            if [ -n "$2" ]; then
                check_ace_server
                control_application "$command" "$2"
            else
                echo -e "${RED}❌ Please specify application name${NC}"
                show_help
                exit 1
            fi
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $command${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
