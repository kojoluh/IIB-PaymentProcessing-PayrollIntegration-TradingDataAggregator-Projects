#!/bin/bash

# IIB ESB Financial Applications - Build Script
# This script builds BAR files from the IIB toolkit projects

set -e

echo "🔨 IIB Application Build Script"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TOOLKIT_WORKSPACE="/opt/ibm/ace-toolkit/workspace"
BUILD_OUTPUT_DIR="deployment/bars"
MQSI_PROFILE="/opt/ibm/ace-12.0.3.0/server/bin/mqsiprofile"

# Check if IIB Toolkit is installed
check_toolkit() {
    echo -e "${BLUE}🔍 Checking IIB Toolkit installation...${NC}"
    
    if [ ! -f "$MQSI_PROFILE" ]; then
        echo -e "${YELLOW}⚠️  IIB Toolkit not found at expected location${NC}"
        echo -e "${YELLOW}Please ensure IBM App Connect Enterprise Toolkit is installed${NC}"
        echo -e "${YELLOW}Or update the MQSI_PROFILE path in this script${NC}"
        
        # Try alternative locations
        ALTERNATIVE_PATHS=(
            "/opt/IBM/ACE/12.0/server/bin/mqsiprofile"
            "/usr/local/ace/server/bin/mqsiprofile"
            "$HOME/IBM/ACE/12.0/server/bin/mqsiprofile"
        )
        
        for alt_path in "${ALTERNATIVE_PATHS[@]}"; do
            if [ -f "$alt_path" ]; then
                echo -e "${GREEN}✅ Found toolkit at: $alt_path${NC}"
                MQSI_PROFILE="$alt_path"
                return 0
            fi
        done
        
        echo -e "${RED}❌ IBM ACE Toolkit not found${NC}"
        echo -e "${YELLOW}Please install IBM App Connect Enterprise Toolkit${NC}"
        echo -e "${YELLOW}Download from: https://www.ibm.com/support/fixcentral/swg/selectFixes?product=ibm%2FWebSphere%2FIBM+App+Connect+Enterprise&release=12.0.3.0&platform=Linux+64-bit,x86_64&function=all${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ IIB Toolkit found${NC}"
}

# Source the mqsiprofile
source_profile() {
    echo -e "${BLUE}📝 Sourcing mqsiprofile...${NC}"
    source "$MQSI_PROFILE"
    echo -e "${GREEN}✅ Environment configured${NC}"
}

# Create build directories
create_build_dirs() {
    echo -e "${BLUE}📁 Creating build directories...${NC}"
    
    mkdir -p "$BUILD_OUTPUT_DIR"
    mkdir -p logs/build
    
    echo -e "${GREEN}✅ Build directories created${NC}"
}

# Build a single project
build_project() {
    local project_name=$1
    local project_path=$2
    
    echo -e "${BLUE}🔨 Building project: $project_name${NC}"
    
    # Check if project exists
    if [ ! -d "$project_path" ]; then
        echo -e "${RED}❌ Project directory not found: $project_path${NC}"
        return 1
    fi
    
    # Create BAR file name
    local bar_file="$BUILD_OUTPUT_DIR/${project_name}.bar"
    local log_file="logs/build/${project_name}-build.log"
    
    echo -e "${YELLOW}Building BAR file: $bar_file${NC}"
    
    # Build the BAR file using mqsipackagebar
    if mqsipackagebar \
        -a "$bar_file" \
        -w "$PWD" \
        -k "$project_name" \
        -v trace \
        > "$log_file" 2>&1; then
        
        echo -e "${GREEN}✅ Successfully built $project_name${NC}"
        echo -e "${GREEN}   BAR file: $bar_file${NC}"
        echo -e "${GREEN}   Size: $(du -h "$bar_file" | cut -f1)${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to build $project_name${NC}"
        echo -e "${RED}   Check log: $log_file${NC}"
        echo -e "${YELLOW}Last 10 lines of build log:${NC}"
        tail -n 10 "$log_file" || true
        return 1
    fi
}

# Validate BAR file
validate_bar_file() {
    local bar_file=$1
    local project_name=$(basename "$bar_file" .bar)
    
    echo -e "${BLUE}🔍 Validating BAR file: $(basename "$bar_file")${NC}"
    
    # Check if file exists and has content
    if [ ! -f "$bar_file" ] || [ ! -s "$bar_file" ]; then
        echo -e "${RED}❌ BAR file is empty or missing${NC}"
        return 1
    fi
    
    # List contents of BAR file
    if mqsireadbar -b "$bar_file" > "logs/build/${project_name}-contents.log" 2>&1; then
        echo -e "${GREEN}✅ BAR file is valid${NC}"
        
        # Show summary of contents
        local message_flows=$(grep -c "\.msgflow" "logs/build/${project_name}-contents.log" 2>/dev/null || echo "0")
        local esql_modules=$(grep -c "\.esql" "logs/build/${project_name}-contents.log" 2>/dev/null || echo "0")
        local java_classes=$(grep -c "\.class" "logs/build/${project_name}-contents.log" 2>/dev/null || echo "0")
        
        echo -e "${GREEN}   Message Flows: $message_flows${NC}"
        echo -e "${GREEN}   ESQL Modules: $esql_modules${NC}"
        echo -e "${GREEN}   Java Classes: $java_classes${NC}"
        
        return 0
    else
        echo -e "${RED}❌ Failed to read BAR file contents${NC}"
        return 1
    fi
}

# Build all projects
build_all_projects() {
    echo -e "${BLUE}🏗️  Building all IIB projects...${NC}"
    
    local projects=(
        "Project1-PaymentProcessingSystem"
        "Project2-TradingDataAggregator"
    )
    
    local success_count=0
    local total_count=0
    
    for project in "${projects[@]}"; do
        ((total_count++))
        echo -e "\n${BLUE}===========================================${NC}"
        echo -e "${BLUE}Building Project $total_count/$((${#projects[@]})): $project${NC}"
        echo -e "${BLUE}===========================================${NC}"
        
        if build_project "$project" "$project"; then
            if validate_bar_file "$BUILD_OUTPUT_DIR/${project}.bar"; then
                ((success_count++))
            fi
        fi
    done
    
    echo -e "\n${BLUE}===========================================${NC}"
    echo -e "${BLUE}Build Summary${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${GREEN}Successful builds: $success_count/$total_count${NC}"
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}🎉 All projects built successfully!${NC}"
        list_bar_files
        return 0
    else
        echo -e "${YELLOW}⚠️  Some builds failed. Check the logs for details.${NC}"
        return 1
    fi
}

# List generated BAR files
list_bar_files() {
    echo -e "\n${BLUE}📦 Generated BAR Files:${NC}"
    echo -e "${BLUE}========================${NC}"
    
    if [ -d "$BUILD_OUTPUT_DIR" ] && [ "$(ls -A $BUILD_OUTPUT_DIR/*.bar 2>/dev/null)" ]; then
        for bar_file in "$BUILD_OUTPUT_DIR"/*.bar; do
            if [ -f "$bar_file" ]; then
                local filename=$(basename "$bar_file")
                local size=$(du -h "$bar_file" | cut -f1)
                local date=$(ls -la "$bar_file" | awk '{print $6, $7, $8}')
                
                echo -e "${GREEN}  📄 $filename${NC}"
                echo -e "${GREEN}     Size: $size, Created: $date${NC}"
            fi
        done
    else
        echo -e "${YELLOW}  No BAR files found${NC}"
    fi
}

# Clean build artifacts
clean_build() {
    echo -e "${BLUE}🧹 Cleaning build artifacts...${NC}"
    
    if [ -d "$BUILD_OUTPUT_DIR" ]; then
        rm -rf "$BUILD_OUTPUT_DIR"/*.bar 2>/dev/null || true
        echo -e "${GREEN}✅ Removed BAR files${NC}"
    fi
    
    if [ -d "logs/build" ]; then
        rm -rf logs/build/*.log 2>/dev/null || true
        echo -e "${GREEN}✅ Removed build logs${NC}"
    fi
    
    echo -e "${GREEN}✅ Clean completed${NC}"
}

# Show help
show_help() {
    echo "IIB Application Build Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build [project-name]     Build specific project or all projects"
    echo "  validate [bar-file]      Validate a specific BAR file"
    echo "  list                     List generated BAR files"
    echo "  clean                    Clean build artifacts"
    echo "  help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build                                     # Build all projects"
    echo "  $0 build Project1-PaymentProcessingSystem   # Build specific project"
    echo "  $0 validate deployment/bars/Project1.bar    # Validate BAR file"
    echo "  $0 list                                      # List BAR files"
    echo "  $0 clean                                     # Clean build artifacts"
}

# Main execution
main() {
    local command=${1:-build}
    
    case $command in
        build)
            check_toolkit
            source_profile
            create_build_dirs
            
            if [ -n "$2" ]; then
                # Build specific project
                echo -e "${BLUE}Building specific project: $2${NC}"
                if build_project "$2" "$2"; then
                    validate_bar_file "$BUILD_OUTPUT_DIR/${2}.bar"
                fi
            else
                # Build all projects
                build_all_projects
            fi
            ;;
        validate)
            if [ -n "$2" ]; then
                check_toolkit
                source_profile
                validate_bar_file "$2"
            else
                echo -e "${RED}❌ Please specify BAR file to validate${NC}"
                show_help
                exit 1
            fi
            ;;
        list)
            list_bar_files
            ;;
        clean)
            clean_build
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
