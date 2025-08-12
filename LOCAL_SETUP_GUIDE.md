# Local Development Setup Guide
## IBM Integration Bus v12.3 Financial Applications

This guide provides step-by-step instructions and download links for setting up the IIB ESB financial applications locally using both Docker containers and native installations.

## Prerequisites & System Requirements

### Minimum System Requirements
- **Operating System**: Windows 10/11, macOS 10.15+, or Linux (RHEL 8+, Ubuntu 18.04+)
- **Memory**: 16GB RAM minimum, 32GB recommended
- **CPU**: 4 cores minimum, 8 cores recommended
- **Disk Space**: 50GB free space minimum
- **Network**: Internet connection for downloads and external integrations

## Option 1: Docker-Based Setup (Recommended)

### 1. Docker Desktop Installation

#### Docker Desktop (Required for Container Setup)
- **Windows**: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe
- **macOS Intel**: https://desktop.docker.com/mac/main/amd64/Docker.dmg
- **macOS Apple Silicon**: https://desktop.docker.com/mac/main/arm64/Docker.dmg
- **Linux**: https://docs.docker.com/engine/install/ubuntu/

```bash
# Verify Docker installation
docker --version
docker-compose --version
```

#### IBM Integration Bus Docker Images (Auto-pulled)
The following images are automatically downloaded when you run `./quick-start.sh`:

```bash
# Core IBM Software Images
ibmcom/ace:12.0.3.0-ubuntu                    # IBM App Connect Enterprise
ibmcom/mq:9.3.4.0-r1                         # IBM MQ

# Database Images  
container-registry.oracle.com/database/express:21.3.0-xe  # Oracle XE
postgres:15-alpine                            # PostgreSQL
influxdb:2.7-alpine                          # InfluxDB
redis:7-alpine                               # Redis

# Monitoring Images
elasticsearch:8.11.0                         # Elasticsearch
kibana:8.11.0                               # Kibana
grafana/grafana:10.2.0                      # Grafana
prom/prometheus:v2.47.0                     # Prometheus
nginx:1.25-alpine                           # Nginx
```

### 2. Database Containers

#### Oracle Database XE (For Payment Processing)
```bash
# Pull Oracle Database XE image
docker pull container-registry.oracle.com/database/express:21.3.0-xe

# Run Oracle XE container
docker run -d \
  --name oracle-xe \
  -p 1521:1521 \
  -p 5500:5500 \
  -e ORACLE_PWD=password123 \
  -e ORACLE_CHARACTERSET=AL32UTF8 \
  -v oracle-data:/opt/oracle/oradata \
  container-registry.oracle.com/database/express:21.3.0-xe
```

#### PostgreSQL (For Audit and Configuration)
```bash
# Pull and run PostgreSQL
docker run -d \
  --name postgresql \
  -p 5432:5432 \
  -e POSTGRES_DB=iib_config \
  -e POSTGRES_USER=iib_user \
  -e POSTGRES_PASSWORD=password123 \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:15

# Connect to PostgreSQL
docker exec -it postgresql psql -U iib_user -d iib_config
```

#### InfluxDB (For Time-Series Market Data)
```bash
# Pull and run InfluxDB
docker run -d \
  --name influxdb \
  -p 8086:8086 \
  -e DOCKER_INFLUXDB_INIT_MODE=setup \
  -e DOCKER_INFLUXDB_INIT_USERNAME=admin \
  -e DOCKER_INFLUXDB_INIT_PASSWORD=password123 \
  -e DOCKER_INFLUXDB_INIT_ORG=trading-org \
  -e DOCKER_INFLUXDB_INIT_BUCKET=market-data \
  -v influxdb-data:/var/lib/influxdb2 \
  influxdb:2.7
```

### 3. Message Queue Setup

#### IBM MQ Developer Edition
```bash
# Pull IBM MQ image
docker pull ibmcom/mq:9.3.4.0-r1

# Run IBM MQ container
docker run -d \
  --name ibm-mq \
  --env LICENSE=accept \
  --env MQ_QMGR_NAME=QM_IIB \
  --env MQ_APP_PASSWORD=password123 \
  --env MQ_ADMIN_PASSWORD=admin123 \
  -p 1414:1414 \
  -p 9443:9443 \
  -p 9157:9157 \
  -v mq-data:/mnt/mqm \
  ibmcom/mq:9.3.4.0-r1

# Access MQ Console at: https://localhost:9443/ibmmq/console/
```

### 4. Monitoring Stack

#### ELK Stack (Elasticsearch, Logstash, Kibana)
```yaml
# docker-compose.elk.yml
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.8.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
      - "9300:9300"
    volumes:
      - es-data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:8.8.0
    container_name: logstash
    ports:
      - "5044:5044"
      - "9600:9600"
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
      - ./logstash/config:/usr/share/logstash/config
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:8.8.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  es-data:
```

#### Prometheus and Grafana
```bash
# Prometheus
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v prometheus-data:/prometheus \
  -v ./prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:v2.44.0

# Grafana
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin123 \
  -v grafana-data:/var/lib/grafana \
  grafana/grafana:10.0.0
```

### 5. Complete Docker Compose Setup

```yaml
# docker-compose.yml - Complete IIB Environment
version: '3.8'

services:
  # IBM Integration Bus
  iib-broker:
    image: ibmcom/ace:12.0.8.0-ubuntu
    container_name: iib-broker
    ports:
      - "7600:7600"   # Administration port
      - "7800:7800"   # Payment Processing EG
      - "7801:7801"   # Trading Data EG
      - "9443:9443"   # Web UI
    environment:
      - LICENSE=accept
      - ACE_SERVER_NAME=ACESERVER
    volumes:
      - ./bars:/home/aceuser/bars
      - ./config:/home/aceuser/config
      - iib-work:/home/aceuser/ace-server
    depends_on:
      - oracle-xe
      - postgresql
      - influxdb
      - ibm-mq

  # Oracle Database XE
  oracle-xe:
    image: container-registry.oracle.com/database/express:21.3.0-xe
    container_name: oracle-xe
    ports:
      - "1521:1521"
      - "5500:5500"
    environment:
      - ORACLE_PWD=password123
      - ORACLE_CHARACTERSET=AL32UTF8
    volumes:
      - oracle-data:/opt/oracle/oradata
      - ./sql/oracle:/docker-entrypoint-initdb.d

  # PostgreSQL
  postgresql:
    image: postgres:15
    container_name: postgresql
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=iib_config
      - POSTGRES_USER=iib_user
      - POSTGRES_PASSWORD=password123
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./sql/postgres:/docker-entrypoint-initdb.d

  # InfluxDB
  influxdb:
    image: influxdb:2.7
    container_name: influxdb
    ports:
      - "8086:8086"
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=admin
      - DOCKER_INFLUXDB_INIT_PASSWORD=password123
      - DOCKER_INFLUXDB_INIT_ORG=trading-org
      - DOCKER_INFLUXDB_INIT_BUCKET=market-data
    volumes:
      - influxdb-data:/var/lib/influxdb2

  # IBM MQ
  ibm-mq:
    image: ibmcom/mq:9.3.4.0-r1
    container_name: ibm-mq
    ports:
      - "1414:1414"
      - "9443:9443"
    environment:
      - LICENSE=accept
      - MQ_QMGR_NAME=QM_IIB
      - MQ_APP_PASSWORD=password123
      - MQ_ADMIN_PASSWORD=admin123
    volumes:
      - mq-data:/mnt/mqm

  # Redis for caching
  redis:
    image: redis:7-alpine
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data

  # Nginx Load Balancer
  nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - iib-broker

volumes:
  oracle-data:
  postgres-data:
  influxdb-data:
  mq-data:
  redis-data:
  iib-work:

networks:
  default:
    name: iib-network
```

## Option 2: Native Installation

### 1. IBM Integration Bus / App Connect Enterprise

#### Download Links
- **IBM App Connect Enterprise Developer Edition**: https://www.ibm.com/support/pages/downloading-ibm-app-connect-enterprise-developer-edition
- **IBM Integration Toolkit**: Included with ACE Developer Edition
- **System Requirements**: https://www.ibm.com/support/pages/system-requirements-ibm-app-connect-enterprise

#### Installation Steps (Linux)
```bash
# Download ACE Developer Edition (example for Linux x64)
wget https://ak-dsw-mul.dhe.ibm.com/sdfdl/v2/regs2/mbfd/Xa.2/Xb.WJL1cUPI6gANEhP8GuMD_Q/Xc.L3RyaWFs/Xd.LTEyMDEyNDc5NzA/Xf.lO0TO2SVRkCMeWyaO2KJ_-Q/12.0.8.0-ACE-LINUX64-DEVELOPER.tar.gz

# Extract installation files
tar -xzf 12.0.8.0-ACE-LINUX64-DEVELOPER.tar.gz

# Run installation
sudo ./ace-12.0.8.0/ace_install.sh

# Set environment variables
export MQSI_WORKPATH=/var/mqsi
export PATH=$PATH:/opt/ibm/ace-12/server/bin
```

#### Installation Steps (Windows)
```powershell
# Download and run installer
# Visit: https://www.ibm.com/support/pages/downloading-ibm-app-connect-enterprise-developer-edition
# Run: 12.0.8.0-ACE-WIN64-DEVELOPER.exe

# Set environment variables
setx ACE_HOME "C:\Program Files\IBM\ACE\12.0.8.0"
setx PATH "%PATH%;C:\Program Files\IBM\ACE\12.0.8.0\server\bin"
```

### 2. IBM MQ

#### Download Links
- **IBM MQ Advanced Developer Edition**: https://www.ibm.com/support/pages/downloading-ibm-mq-90
- **Documentation**: https://www.ibm.com/docs/en/ibm-mq/9.3

#### Installation (Linux)
```bash
# Download MQ Advanced for Developers
wget https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev93_linux_x86-64.tar.gz

# Extract and install
tar -xzf mqadv_dev93_linux_x86-64.tar.gz
sudo ./mqadv_dev93_linux_x86-64/mqlicense.sh -accept
sudo ./mqadv_dev93_linux_x86-64/mqinst
```

### 3. Database Systems

#### Oracle Database XE
- **Download**: https://www.oracle.com/database/technologies/xe-downloads.html
- **Documentation**: https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinl/

#### PostgreSQL
- **Download**: https://www.postgresql.org/download/
- **Documentation**: https://www.postgresql.org/docs/

#### InfluxDB
- **Download**: https://portal.influxdata.com/downloads/
- **Documentation**: https://docs.influxdata.com/influxdb/

### 4. Development Tools

#### IBM Integration Toolkit
- **Download**: Included with ACE Developer Edition
- **Alternative**: IBM App Connect Enterprise Toolkit

#### Eclipse IDE (for ESQL development)
- **Download**: https://www.eclipse.org/downloads/
- **Required Plugins**: IBM Integration Bus plugin

#### Git for Version Control
- **Download**: https://git-scm.com/downloads

## Quick Start Scripts

### Docker Quick Start
```bash
#!/bin/bash
# quick-start-docker.sh

echo "Starting IIB Financial Applications with Docker..."

# Create directories
mkdir -p ./bars ./config ./sql/oracle ./sql/postgres ./nginx

# Copy application BAR files
cp Project1-PaymentProcessingSystem/*.bar ./bars/
cp Project2-TradingDataAggregator/*.bar ./bars/

# Start all services
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 60

# Deploy applications
docker exec iib-broker mqsideploy IB_NODE -e PaymentProcessingEG -a /home/aceuser/bars/PaymentProcessingApp.bar
docker exec iib-broker mqsideploy IB_NODE -e TradingDataEG -a /home/aceuser/bars/TradingDataApp.bar

echo "IIB Financial Applications are now running!"
echo "Payment Processing API: http://localhost:7800/api/payments"
echo "Trading Data API: http://localhost:7801/api/market-data"
echo "MQ Console: https://localhost:9443/ibmmq/console/"
echo "Oracle DB: localhost:1521/XE (system/password123)"
echo "InfluxDB: http://localhost:8086 (admin/password123)"
```

### Native Installation Quick Start
```bash
#!/bin/bash
# quick-start-native.sh

echo "Starting IIB Financial Applications (Native)..."

# Create Integration Node
mqsicreateintegrationnode IB_NODE

# Start Integration Node
mqsistart IB_NODE

# Create Execution Groups
mqsicreateexecutiongroup IB_NODE -e PaymentProcessingEG
mqsicreateexecutiongroup IB_NODE -e TradingDataEG

# Deploy applications
mqsideploy IB_NODE -e PaymentProcessingEG -a PaymentProcessingApp.bar
mqsideploy IB_NODE -e TradingDataEG -a TradingDataApp.bar

# Configure database connections
mqsisetdbparms IB_NODE -n PaymentDB -u payment_user -p password123
mqsisetdbparms IB_NODE -n MarketDataDB -u market_user -p password123

echo "Applications deployed successfully!"
```

## Testing the Setup

### Health Check Endpoints
```bash
# Payment Processing System
curl http://localhost:7800/health

# Trading Data Aggregator
curl http://localhost:7801/health

# Sample payment request
curl -X POST http://localhost:7800/api/payments/process \
  -H "Content-Type: application/json" \
  -d '{
    "payment": {
      "amount": 100.00,
      "currency": "USD",
      "method": "CREDIT_CARD",
      "cardNumber": "4111111111111111"
    },
    "customer": {
      "id": "CUST001"
    }
  }'
```

## Troubleshooting

### Common Issues and Solutions

#### Port Conflicts
```bash
# Check port usage
netstat -tulpn | grep :7800

# Stop conflicting services
sudo systemctl stop apache2
sudo systemctl stop nginx
```

#### Memory Issues
```bash
# Increase Docker memory limit
# Docker Desktop -> Settings -> Resources -> Memory: 8GB+

# For native installation, adjust JVM heap
export ACE_JVM_OPTIONS="-Xms2g -Xmx4g"
```

#### Database Connection Issues
```bash
# Test Oracle connection
sqlplus system/password123@localhost:1521/XE

# Test PostgreSQL connection
psql -h localhost -p 5432 -U iib_user -d iib_config
```

## Next Steps

1. **Deploy Applications**: Follow the deployment scripts above
2. **Configure Monitoring**: Set up Prometheus, Grafana, and ELK stack
3. **Load Test Data**: Use the testing framework to validate functionality
4. **Customize Configuration**: Modify environment-specific settings
5. **Set up CI/CD**: Configure automated deployment pipeline

For production deployment, refer to the `SYSTEM_INTEGRATION.md` document for enterprise-grade configuration.
