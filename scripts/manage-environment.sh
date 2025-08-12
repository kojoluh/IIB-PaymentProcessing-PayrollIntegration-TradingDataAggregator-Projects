#!/bin/bash

# IIB ESB Financial Applications - Environment Management Script
# This script manages the Docker environment for the IIB applications

set -e

echo "🌐 IIB Environment Management Script"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Show environment status
show_status() {
    echo -e "${BLUE}📊 Environment Status${NC}"
    echo -e "${BLUE}=====================${NC}"
    
    # Check Docker status
    if docker info > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker is running${NC}"
    else
        echo -e "${RED}❌ Docker is not running${NC}"
        return 1
    fi
    
    # Show running containers
    echo -e "\n${BLUE}🐳 Running Containers:${NC}"
    docker-compose ps
    
    # Show resource usage
    echo -e "\n${BLUE}💾 Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    # Show service health
    echo -e "\n${BLUE}🏥 Service Health:${NC}"
    check_services_health
}

# Check service health
check_services_health() {
    local services=(
        "ace-server:7600:ACE Server"
        "ibm-mq:9443:IBM MQ Console"
        "oracle-xe:1521:Oracle Database"
        "postgresql:5432:PostgreSQL"
        "influxdb:8086:InfluxDB"
        "redis:6379:Redis"
        "elasticsearch:9200:Elasticsearch"
        "kibana:5601:Kibana"
        "grafana:3000:Grafana"
        "prometheus:9090:Prometheus"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r container port name <<< "$service_info"
        
        if docker ps --format '{{.Names}}' | grep -q "^$container$"; then
            if timeout 5 bash -c "cat < /dev/null > /dev/tcp/localhost/$port" 2>/dev/null; then
                echo -e "${GREEN}✅ $name (localhost:$port)${NC}"
            else
                echo -e "${YELLOW}⚠️  $name - Container running but port not responding${NC}"
            fi
        else
            echo -e "${RED}❌ $name - Container not running${NC}"
        fi
    done
}

# Start the environment
start_environment() {
    echo -e "${BLUE}🚀 Starting IIB Environment...${NC}"
    
    # Start in proper order
    echo -e "${BLUE}Starting infrastructure services...${NC}"
    docker-compose up -d oracle-xe postgresql influxdb redis
    
    echo -e "${BLUE}Waiting for databases to initialize...${NC}"
    sleep 30
    
    echo -e "${BLUE}Starting messaging services...${NC}"
    docker-compose up -d ibm-mq
    
    echo -e "${BLUE}Starting monitoring services...${NC}"
    docker-compose up -d elasticsearch prometheus
    sleep 20
    
    echo -e "${BLUE}Starting visualization services...${NC}"
    docker-compose up -d kibana grafana
    
    echo -e "${BLUE}Starting ACE server...${NC}"
    docker-compose up -d ace-server
    
    echo -e "${BLUE}Starting load balancer...${NC}"
    docker-compose up -d nginx
    
    echo -e "${GREEN}✅ Environment started${NC}"
    
    # Wait for services to be ready
    echo -e "${YELLOW}Waiting for services to initialize...${NC}"
    sleep 60
    
    show_status
}

# Stop the environment
stop_environment() {
    echo -e "${BLUE}🛑 Stopping IIB Environment...${NC}"
    
    docker-compose stop
    
    echo -e "${GREEN}✅ Environment stopped${NC}"
}

# Restart the environment
restart_environment() {
    echo -e "${BLUE}🔄 Restarting IIB Environment...${NC}"
    
    stop_environment
    sleep 10
    start_environment
}

# Reset the environment (remove containers and volumes)
reset_environment() {
    echo -e "${YELLOW}⚠️  This will remove all containers and data volumes${NC}"
    echo -e "${YELLOW}Are you sure? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🗑️  Resetting environment...${NC}"
        
        docker-compose down -v --remove-orphans
        docker system prune -f
        
        # Remove any orphaned volumes
        docker volume ls -q | grep -E "(iib|esb)" | xargs -r docker volume rm
        
        echo -e "${GREEN}✅ Environment reset completed${NC}"
    else
        echo -e "${BLUE}Reset cancelled${NC}"
    fi
}

# Update Docker images
update_images() {
    echo -e "${BLUE}📥 Updating Docker images...${NC}"
    
    docker-compose pull
    
    echo -e "${GREEN}✅ Images updated${NC}"
    echo -e "${YELLOW}Restart the environment to use updated images${NC}"
}

# View logs
view_logs() {
    local service=$1
    local lines=${2:-100}
    
    if [ -n "$service" ]; then
        echo -e "${BLUE}📋 Showing logs for $service (last $lines lines):${NC}"
        docker-compose logs --tail="$lines" -f "$service"
    else
        echo -e "${BLUE}📋 Showing logs for all services (last $lines lines):${NC}"
        docker-compose logs --tail="$lines" -f
    fi
}

# Execute command in container
exec_command() {
    local service=$1
    shift
    local command="$*"
    
    if [ -z "$service" ] || [ -z "$command" ]; then
        echo -e "${RED}❌ Usage: $0 exec <service> <command>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔧 Executing in $service: $command${NC}"
    docker-compose exec "$service" bash -c "$command"
}

# Open shell in container
shell_access() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo -e "${RED}❌ Usage: $0 shell <service>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🐚 Opening shell in $service container...${NC}"
    docker-compose exec "$service" bash
}

# Backup data
backup_data() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${BLUE}💾 Creating backup in $backup_dir...${NC}"
    mkdir -p "$backup_dir"
    
    # Backup database data
    echo -e "${BLUE}Backing up Oracle database...${NC}"
    docker exec oracle-xe bash -c "expdp system/password123 full=y directory=DATA_PUMP_DIR dumpfile=backup.dmp" || true
    docker cp oracle-xe:/opt/oracle/admin/XE/dpdump/backup.dmp "$backup_dir/oracle_backup.dmp" 2>/dev/null || true
    
    echo -e "${BLUE}Backing up PostgreSQL database...${NC}"
    docker exec postgresql pg_dumpall -U iib_user > "$backup_dir/postgresql_backup.sql"
    
    echo -e "${BLUE}Backing up InfluxDB data...${NC}"
    docker exec influxdb influxd backup -portable /tmp/backup
    docker cp influxdb:/tmp/backup "$backup_dir/influxdb_backup"
    
    echo -e "${BLUE}Backing up application logs...${NC}"
    cp -r logs "$backup_dir/" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Backup completed: $backup_dir${NC}"
}

# Show resource usage
show_resources() {
    echo -e "${BLUE}📈 Resource Usage Monitoring${NC}"
    echo -e "${BLUE}=============================${NC}"
    
    # System resources
    echo -e "\n${BLUE}💻 System Resources:${NC}"
    echo "CPU Usage: $(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')"
    echo "Memory Usage: $(top -l 1 -n 0 | grep "PhysMem" | awk '{print $2}')"
    echo "Disk Usage: $(df -h . | tail -1 | awk '{print $5}')"
    
    # Docker resources
    echo -e "\n${BLUE}🐳 Docker Resources:${NC}"
    docker system df
    
    # Container resource usage
    echo -e "\n${BLUE}📊 Container Resource Usage:${NC}"
    docker stats --no-stream
}

# Monitor services
monitor_services() {
    echo -e "${BLUE}👁️  Service Monitoring${NC}"
    echo -e "${BLUE}====================${NC}"
    
    while true; do
        clear
        echo -e "${BLUE}$(date): Monitoring IIB Environment${NC}"
        echo -e "${BLUE}=====================================${NC}"
        
        check_services_health
        echo ""
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
        
        echo -e "\n${YELLOW}Press Ctrl+C to exit monitoring${NC}"
        sleep 10
    done
}

# Show help
show_help() {
    echo "IIB Environment Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  status                    Show environment status"
    echo "  start                     Start the environment"
    echo "  stop                      Stop the environment"
    echo "  restart                   Restart the environment"
    echo "  reset                     Reset environment (removes all data)"
    echo "  update                    Update Docker images"
    echo "  logs [service] [lines]    View logs (default: all services, 100 lines)"
    echo "  exec <service> <command>  Execute command in container"
    echo "  shell <service>           Open shell in container"
    echo "  backup                    Backup data"
    echo "  resources                 Show resource usage"
    echo "  monitor                   Monitor services (real-time)"
    echo "  help                      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status                        # Show current status"
    echo "  $0 start                         # Start all services"
    echo "  $0 logs ace-server 50           # Show last 50 lines of ACE server logs"
    echo "  $0 exec postgresql 'psql -U iib_user -l'  # List PostgreSQL databases"
    echo "  $0 shell ace-server              # Open shell in ACE container"
    echo "  $0 monitor                       # Real-time monitoring"
}

# Main execution
main() {
    local command=${1:-status}
    
    case $command in
        status)
            show_status
            ;;
        start)
            start_environment
            ;;
        stop)
            stop_environment
            ;;
        restart)
            restart_environment
            ;;
        reset)
            reset_environment
            ;;
        update)
            update_images
            ;;
        logs)
            view_logs "$2" "$3"
            ;;
        exec)
            shift
            exec_command "$@"
            ;;
        shell)
            shell_access "$2"
            ;;
        backup)
            backup_data
            ;;
        resources)
            show_resources
            ;;
        monitor)
            monitor_services
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
