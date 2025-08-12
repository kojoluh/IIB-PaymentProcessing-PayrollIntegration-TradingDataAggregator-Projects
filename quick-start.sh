#!/bin/bash

# IIB ESB Financial Applications - Quick Start Script
# This script sets up the complete development environment using Docker

set -e  # Exit on any error

echo "🚀 Starting IIB ESB Financial Applications Setup..."
echo "=================================================="
echo ""
echo -e "${BLUE}📋 For manual installation or native setup, see:${NC}"
echo -e "${BLUE}   📖 documentation/DOWNLOAD_LINKS_GUIDE.md${NC}"
echo -e "${BLUE}   🔗 Or run: ./scripts/verify-download-links.sh${NC}"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is installed and running
check_docker() {
    echo -e "${BLUE}📦 Checking Docker installation...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed. Please install Docker Desktop first.${NC}"
        echo "Download from: https://www.docker.com/products/docker-desktop/"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Docker is installed and running${NC}"
}

# Check if Docker Compose is available
check_docker_compose() {
    echo -e "${BLUE}🐳 Checking Docker Compose...${NC}"
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Docker Compose is not available. Please install Docker Compose.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker Compose is available${NC}"
}

# Create necessary directories
create_directories() {
    echo -e "${BLUE}📁 Creating directory structure...${NC}"
    
    # Create main directories
    mkdir -p {deployment/{bars,config,logs},config/{nginx/conf.d,mq},sql/{oracle/init,postgres/init},monitoring/{prometheus,grafana/{provisioning,dashboards}}}
    
    # Create specific config subdirectories
    mkdir -p config/nginx/ssl
    mkdir -p monitoring/grafana/provisioning/{datasources,dashboards}
    
    echo -e "${GREEN}✅ Directory structure created${NC}"
}

# Generate configuration files
generate_configs() {
    echo -e "${BLUE}⚙️  Generating configuration files...${NC}"
    
    # Nginx configuration
    cat > config/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Upstream for Payment Processing
    upstream payment_backend {
        server ace-server:7800 max_fails=3 fail_timeout=30s;
    }
    
    # Upstream for Trading Data
    upstream trading_backend {
        server ace-server:7801 max_fails=3 fail_timeout=30s;
    }
    
    # Health check endpoint
    server {
        listen 80;
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
    
    # Payment Processing API
    server {
        listen 80;
        server_name payment-api.local;
        
        location / {
            proxy_pass http://payment_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    
    # Trading Data API
    server {
        listen 80;
        server_name trading-api.local;
        
        location / {
            proxy_pass http://trading_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

    # Prometheus configuration
    cat > monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'ace-server'
    static_configs:
      - targets: ['ace-server:7600']
    scrape_interval: 10s

  - job_name: 'ibm-mq'
    static_configs:
      - targets: ['ibm-mq:9157']
    scrape_interval: 15s

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx:80']
EOF

    # Grafana datasource configuration
    cat > monitoring/grafana/provisioning/datasources/datasource.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true

  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    database: market-data
    user: admin
    password: password123
    editable: true
EOF

    # Oracle initialization script
    cat > sql/oracle/init/01-create-payment-schema.sql << 'EOF'
-- Create Payment Processing Schema
CREATE USER payment_user IDENTIFIED BY payment_password;
GRANT CONNECT, RESOURCE, DBA TO payment_user;
GRANT UNLIMITED TABLESPACE TO payment_user;

-- Connect as payment_user
CONNECT payment_user/payment_password;

-- Create Payment Transactions Table
CREATE TABLE payment_transactions (
    transaction_id VARCHAR2(50) PRIMARY KEY,
    customer_id VARCHAR2(50) NOT NULL,
    merchant_id VARCHAR2(50) NOT NULL,
    amount NUMBER(15,2) NOT NULL,
    currency VARCHAR2(3) NOT NULL,
    payment_method VARCHAR2(20) NOT NULL,
    card_number VARCHAR2(20),
    account_number VARCHAR2(30),
    transaction_status VARCHAR2(20) DEFAULT 'PENDING',
    risk_score NUMBER(3) DEFAULT 0,
    fraud_status VARCHAR2(20) DEFAULT 'UNKNOWN',
    gateway_response CLOB,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Fraud Detection Log Table
CREATE TABLE fraud_detection_log (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY,
    transaction_id VARCHAR2(50) NOT NULL,
    rule_name VARCHAR2(100),
    risk_score NUMBER(3),
    fraud_indicators CLOB,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fraud_transaction FOREIGN KEY (transaction_id) REFERENCES payment_transactions(transaction_id)
);

-- Create Audit Log Table
CREATE TABLE audit_log (
    audit_id NUMBER GENERATED ALWAYS AS IDENTITY,
    transaction_id VARCHAR2(50),
    event_type VARCHAR2(50) NOT NULL,
    event_data CLOB,
    user_id VARCHAR2(50),
    ip_address VARCHAR2(45),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_payment_customer ON payment_transactions(customer_id);
CREATE INDEX idx_payment_date ON payment_transactions(created_date);
CREATE INDEX idx_payment_status ON payment_transactions(transaction_status);
CREATE INDEX idx_fraud_transaction ON fraud_detection_log(transaction_id);
CREATE INDEX idx_audit_transaction ON audit_log(transaction_id);
CREATE INDEX idx_audit_date ON audit_log(created_date);

COMMIT;
EOF

    # PostgreSQL initialization script
    cat > sql/postgres/init/01-create-config-schema.sql << 'EOF'
-- Create Configuration and Metadata Schema

-- Application Configuration Table
CREATE TABLE app_config (
    config_id SERIAL PRIMARY KEY,
    application_name VARCHAR(100) NOT NULL,
    config_key VARCHAR(200) NOT NULL,
    config_value TEXT,
    config_type VARCHAR(50) DEFAULT 'STRING',
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(application_name, config_key)
);

-- System Monitoring Table
CREATE TABLE system_metrics (
    metric_id SERIAL PRIMARY KEY,
    metric_name VARCHAR(200) NOT NULL,
    metric_value DECIMAL(15,4),
    metric_unit VARCHAR(50),
    application_name VARCHAR(100),
    host_name VARCHAR(100),
    recorded_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Error Log Table
CREATE TABLE error_log (
    error_id SERIAL PRIMARY KEY,
    application_name VARCHAR(100) NOT NULL,
    error_type VARCHAR(100),
    error_message TEXT,
    stack_trace TEXT,
    correlation_id VARCHAR(100),
    occurred_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_config_app_key ON app_config(application_name, config_key);
CREATE INDEX idx_metrics_name_date ON system_metrics(metric_name, recorded_date);
CREATE INDEX idx_error_app_date ON error_log(application_name, occurred_date);

-- Insert default configuration
INSERT INTO app_config (application_name, config_key, config_value, description) VALUES
('PaymentProcessing', 'fraud.detection.threshold', '50', 'Fraud detection risk score threshold'),
('PaymentProcessing', 'max.transaction.amount', '100000', 'Maximum allowed transaction amount'),
('PaymentProcessing', 'supported.currencies', 'USD,EUR,GBP,JPY,CAD,AUD', 'Supported currency codes'),
('TradingDataAggregator', 'market.data.retention.days', '365', 'Number of days to retain market data'),
('TradingDataAggregator', 'technical.analysis.periods', '5,10,20,50,200', 'Moving average periods'),
('TradingDataAggregator', 'risk.var.confidence', '0.95,0.99', 'VaR confidence levels');

COMMIT;
EOF

    echo -e "${GREEN}✅ Configuration files generated${NC}"
}

# Pull Docker images
pull_images() {
    echo -e "${BLUE}📥 Pulling Docker images...${NC}"
    echo -e "${YELLOW}This may take several minutes...${NC}"
    
    # Pull all images in parallel to speed up the process
    docker-compose pull --parallel --quiet
    
    echo -e "${GREEN}✅ Docker images pulled successfully${NC}"
}

# Start services
start_services() {
    echo -e "${BLUE}🚀 Starting services...${NC}"
    echo -e "${YELLOW}This will take a few minutes for all services to initialize...${NC}"
    
    # Start infrastructure services first
    echo -e "${BLUE}Starting databases and message queues...${NC}"
    docker-compose up -d oracle-xe postgresql influxdb ibm-mq redis
    
    # Wait for databases to be ready
    echo -e "${YELLOW}Waiting for databases to initialize (60 seconds)...${NC}"
    sleep 60
    
    # Start monitoring services
    echo -e "${BLUE}Starting monitoring services...${NC}"
    docker-compose up -d elasticsearch prometheus
    sleep 30
    
    # Start visualization services
    echo -e "${BLUE}Starting visualization services...${NC}"
    docker-compose up -d kibana grafana
    
    # Start ACE server
    echo -e "${BLUE}Starting IBM App Connect Enterprise...${NC}"
    docker-compose up -d ace-server
    
    # Start load balancer
    echo -e "${BLUE}Starting load balancer...${NC}"
    docker-compose up -d nginx
    
    echo -e "${GREEN}✅ All services started${NC}"
}

# Wait for services to be healthy
wait_for_services() {
    echo -e "${BLUE}⏳ Waiting for services to be healthy...${NC}"
    
    # Function to check if a service is healthy
    check_service() {
        local service=$1
        local url=$2
        local max_attempts=30
        local attempt=1
        
        echo -e "${YELLOW}Checking $service...${NC}"
        
        while [ $attempt -le $max_attempts ]; do
            if curl -f -s "$url" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ $service is ready${NC}"
                return 0
            fi
            echo -n "."
            sleep 10
            ((attempt++))
        done
        
        echo -e "${RED}❌ $service failed to start properly${NC}"
        return 1
    }
    
    # Check each service
    check_service "ACE Server" "http://localhost:7600"
    check_service "MQ Console" "https://localhost:9443" || true  # MQ console might need login
    check_service "Grafana" "http://localhost:3000"
    check_service "Kibana" "http://localhost:5601"
    check_service "Prometheus" "http://localhost:9090"
    check_service "InfluxDB" "http://localhost:8086"
    
    echo -e "${GREEN}✅ Services health check completed${NC}"
}

# Deploy applications
deploy_applications() {
    echo -e "${BLUE}📦 Deploying IIB applications...${NC}"
    
    # Check if BAR files exist
    if [ ! -d "deployment/bars" ] || [ -z "$(ls -A deployment/bars 2>/dev/null)" ]; then
        echo -e "${YELLOW}⚠️  No BAR files found in deployment/bars directory${NC}"
        echo -e "${YELLOW}Please build and copy your BAR files to deployment/bars before running deployment${NC}"
        return 1
    fi
    
    # Wait a bit more for ACE to be fully ready
    echo -e "${YELLOW}Waiting for ACE server to be fully initialized...${NC}"
    sleep 30
    
    # Deploy each BAR file
    for bar_file in deployment/bars/*.bar; do
        if [ -f "$bar_file" ]; then
            filename=$(basename "$bar_file")
            echo -e "${BLUE}Deploying $filename...${NC}"
            
            docker exec ace-server bash -c "
                mqsideploy ACESERVER -a /home/aceuser/bars/$filename
            " || echo -e "${YELLOW}⚠️  Failed to deploy $filename${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Application deployment completed${NC}"
}

# Show service URLs
show_service_urls() {
    echo -e "${GREEN}"
    echo "🎉 IIB ESB Financial Applications are now running!"
    echo "=================================================="
    echo ""
    echo "📊 Management & Monitoring:"
    echo "  ACE Web UI:      https://localhost:9443 (admin/admin)"
    echo "  MQ Console:      https://localhost:9444/ibmmq/console/ (admin/admin123)"
    echo "  Grafana:         http://localhost:3000 (admin/admin123)"
    echo "  Kibana:          http://localhost:5601"
    echo "  Prometheus:      http://localhost:9090"
    echo ""
    echo "💾 Databases:"
    echo "  Oracle XE:       localhost:1521/XE (system/password123)"
    echo "  PostgreSQL:      localhost:5432/iib_config (iib_user/password123)"
    echo "  InfluxDB:        http://localhost:8086 (admin/password123)"
    echo "  Redis:           localhost:6379 (password123)"
    echo ""
    echo "🌐 Application APIs:"
    echo "  Payment API:     http://localhost:7800/api/payments"
    echo "  Trading API:     http://localhost:7801/api/market-data"
    echo "  Load Balancer:   http://localhost:80"
    echo ""
    echo "📝 Useful Commands:"
    echo "  View logs:       docker-compose logs -f [service-name]"
    echo "  Stop all:        docker-compose down"
    echo "  Restart service: docker-compose restart [service-name]"
    echo "  Shell access:    docker exec -it [container-name] bash"
    echo ""
    echo -e "${NC}"
}

# Test basic connectivity
test_connectivity() {
    echo -e "${BLUE}🧪 Testing basic connectivity...${NC}"
    
    # Test ACE health endpoint
    if curl -f -s http://localhost:7600 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ ACE Server is responding${NC}"
    else
        echo -e "${YELLOW}⚠️  ACE Server might not be fully ready yet${NC}"
    fi
    
    # Test database connections
    if docker exec postgresql pg_isready -U iib_user -d iib_config > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
    else
        echo -e "${YELLOW}⚠️  PostgreSQL connection issue${NC}"
    fi
    
    echo -e "${GREEN}✅ Basic connectivity tests completed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting IIB ESB Financial Applications Setup...${NC}"
    echo ""
    
    check_docker
    check_docker_compose
    create_directories
    generate_configs
    pull_images
    start_services
    wait_for_services
    test_connectivity
    
    # Only try to deploy if BAR files exist
    if [ -d "deployment/bars" ] && [ "$(ls -A deployment/bars 2>/dev/null)" ]; then
        deploy_applications
    else
        echo -e "${YELLOW}⚠️  Skipping application deployment - no BAR files found${NC}"
        echo -e "${YELLOW}To deploy applications later, copy BAR files to deployment/bars and run:${NC}"
        echo -e "${YELLOW}./scripts/deploy-applications.sh${NC}"
    fi
    
    show_service_urls
    
    echo -e "${GREEN}🚀 Setup completed successfully!${NC}"
    echo -e "${BLUE}You can now start developing and testing your IIB applications.${NC}"
}

# Run main function
main "$@"
