# 📦 Active Download Links and Setup Resources

This document provides **active, verified download links** for all software components needed to run the IIB ESB Financial Applications locally, either with Docker or as discrete resources.

## 🎯 Quick Setup Options

### Option 1: Docker-Based Setup (Recommended)
- **Pros**: Fastest setup, all services containerized, consistent environment
- **Requirements**: Only Docker Desktop needed
- **Time**: 10-15 minutes

### Option 2: Native Installation
- **Pros**: Full control, production-like setup, better performance
- **Requirements**: Install all components natively
- **Time**: 2-3 hours

---

## 🐳 **Option 1: Docker-Based Setup**

### Required Software

#### **1. Docker Desktop** ⭐ REQUIRED
- **Windows**: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe
- **macOS Intel**: https://desktop.docker.com/mac/main/amd64/Docker.dmg
- **macOS Apple Silicon**: https://desktop.docker.com/mac/main/arm64/Docker.dmg
- **Linux**: https://docs.docker.com/engine/install/
- **Version**: 4.25.0 or later
- **Resources**: Minimum 8GB RAM, 50GB storage

#### **2. Git** (Version Control)
- **Windows**: https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe
- **macOS**: `brew install git` or https://git-scm.com/download/mac
- **Linux**: `sudo apt-get install git` or equivalent

### Docker Images (Automatically Downloaded)
The following images will be pulled automatically when you run `./quick-start.sh`:

```bash
# Core IBM Software
ibmcom/ace:12.0.3.0-ubuntu                    # IBM App Connect Enterprise
ibmcom/mq:9.3.4.0-r1                         # IBM MQ
container-registry.oracle.com/database/express:21.3.0-xe  # Oracle XE

# Supporting Services  
postgres:15-alpine                            # PostgreSQL
influxdb:2.7-alpine                          # InfluxDB
redis:7-alpine                               # Redis
elasticsearch:8.11.0                         # Elasticsearch
kibana:8.11.0                               # Kibana
grafana/grafana:10.2.0                      # Grafana
prom/prometheus:v2.47.0                     # Prometheus
nginx:1.25-alpine                           # Nginx
```

### Quick Start Commands

```bash
# 1. Clone the repository
git clone https://github.com/your-org/iib-esb-financial-apps.git
cd iib-esb-financial-apps

# 2. Start everything with Docker
./quick-start.sh

# 3. Wait for initialization (5-10 minutes)
# Access your applications at:
# - Payment API: http://localhost:7800
# - Trading API: http://localhost:7801
# - Grafana: http://localhost:3000
```

---

## 🔧 **Option 2: Native Installation**

### Core IBM Software

#### **1. IBM App Connect Enterprise (ACE) v12.0.3.0** ⭐ CRITICAL
**Developer Edition (Free)**:
- **Download Page**: https://www.ibm.com/support/pages/downloading-ibm-app-connect-enterprise-developer-edition
- **Direct Links**:
  - **Linux x86_64**: https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/IMA/0aj9z/0/12.0.3.0-ACE-LINUX64-DEVELOPER.tar.gz
  - **Windows x64**: https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/IMA/0aj9z/0/12.0.3.0-ACE-WIN64-DEVELOPER.exe
  - **AIX**: https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/IMA/0aj9z/0/12.0.3.0-ACE-AIX64-DEVELOPER.tar.gz

**Enterprise Edition** (Requires IBM ID and entitlement):
- **IBM Fix Central**: https://www.ibm.com/support/fixcentral/
- Search: "IBM App Connect Enterprise 12.0.3.0"
- Product: "IBM App Connect Enterprise"
- Release: "12.0.3.0"

#### **2. IBM MQ v9.3.4** ⭐ CRITICAL
**Developer Edition (Free)**:
- **Download Page**: https://developer.ibm.com/tutorials/mq-connect-app-queue-manager-containers/
- **Direct Links**:
  - **Linux x86_64**: https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev934_linux_x86-64.tar.gz
  - **Windows x64**: https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev934_win_x86-64.zip
  - **macOS**: https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev934_mac_x86-64.pkg

**Enterprise Edition**:
- **IBM Passport Advantage**: https://www.ibm.com/software/passportadvantage/
- Product: "IBM MQ Advanced"

#### **3. IBM ACE Toolkit v12.0.3.0** (Development Environment)
**Included with ACE Developer Edition**:
- **Eclipse-based IDE** for message flow development
- **ESQL editor** with syntax highlighting
- **Flow debugger** and testing tools
- **BAR file builder** for deployment

### Database Systems

#### **1. Oracle Database 21c Express Edition (Free)**
- **Download Page**: https://www.oracle.com/database/technologies/xe-downloads.html
- **Direct Links**:
  - **Linux x86_64**: https://download.oracle.com/otn-pub/otn_software/db-express/oracle-database-xe-21c-1.0-1.ol7.x86_64.rpm
  - **Windows x64**: https://download.oracle.com/otn-pub/otn_software/db-express/OracleXE213_Win64.zip
- **Docker Image**: `container-registry.oracle.com/database/express:21.3.0-xe`

#### **2. PostgreSQL 15**
- **Download Page**: https://www.postgresql.org/download/
- **Direct Links**:
  - **Windows**: https://get.enterprisedb.com/postgresql/postgresql-15.5-1-windows-x64.exe
  - **macOS**: https://get.enterprisedb.com/postgresql/postgresql-15.5-1-osx.dmg
  - **Linux**: Package manager or https://www.postgresql.org/download/linux/

#### **3. InfluxDB 2.7** (Time-Series Database)
- **Download Page**: https://portal.influxdata.com/downloads/
- **Direct Links**:
  - **Linux x86_64**: https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4_linux_amd64.tar.gz
  - **Windows**: https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4_windows_amd64.zip
  - **macOS**: https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4_darwin_amd64.tar.gz

#### **4. Redis 7.2** (Caching)
- **Download Page**: https://redis.io/download/
- **Direct Links**:
  - **Source**: https://download.redis.io/redis-stable.tar.gz
  - **Windows**: https://github.com/microsoftarchive/redis/releases/download/win-3.0.504/Redis-x64-3.0.504.msi
  - **macOS**: `brew install redis`

### Monitoring Stack

#### **1. Elasticsearch 8.11.0**
- **Download Page**: https://www.elastic.co/downloads/elasticsearch
- **Direct Links**:
  - **Linux x86_64**: https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.11.0-linux-x86_64.tar.gz
  - **Windows**: https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.11.0-windows-x86_64.zip
  - **macOS**: https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.11.0-darwin-x86_64.tar.gz

#### **2. Kibana 8.11.0**
- **Download Page**: https://www.elastic.co/downloads/kibana
- **Direct Links**:
  - **Linux x86_64**: https://artifacts.elastic.co/downloads/kibana/kibana-8.11.0-linux-x86_64.tar.gz
  - **Windows**: https://artifacts.elastic.co/downloads/kibana/kibana-8.11.0-windows-x86_64.zip
  - **macOS**: https://artifacts.elastic.co/downloads/kibana/kibana-8.11.0-darwin-x86_64.tar.gz

#### **3. Grafana 10.2.0**
- **Download Page**: https://grafana.com/grafana/download
- **Direct Links**:
  - **Linux x86_64**: https://dl.grafana.com/oss/release/grafana-10.2.0.linux-amd64.tar.gz
  - **Windows**: https://dl.grafana.com/oss/release/grafana-10.2.0.windows-amd64.zip
  - **macOS**: https://dl.grafana.com/oss/release/grafana-10.2.0.darwin-amd64.tar.gz

#### **4. Prometheus 2.47.0**
- **Download Page**: https://prometheus.io/download/
- **Direct Links**:
  - **Linux x86_64**: https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
  - **Windows**: https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.windows-amd64.tar.gz
  - **macOS**: https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.darwin-amd64.tar.gz

### Web Server

#### **Nginx 1.25**
- **Download Page**: https://nginx.org/en/download.html
- **Direct Links**:
  - **Linux**: Package manager or https://nginx.org/packages/
  - **Windows**: https://nginx.org/download/nginx-1.25.3.zip
  - **macOS**: `brew install nginx`

---

## 📋 **Installation Verification Scripts**

### Docker Setup Verification

```bash
#!/bin/bash
# verify-docker-setup.sh

echo "🔍 Verifying Docker Setup..."

# Check Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker: $(docker --version)"
else
    echo "❌ Docker not installed"
    exit 1
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo "✅ Docker Compose available"
else
    echo "❌ Docker Compose not available"
    exit 1
fi

# Check Docker daemon
if docker info &> /dev/null; then
    echo "✅ Docker daemon running"
else
    echo "❌ Docker daemon not running"
    exit 1
fi

# Check available resources
MEMORY=$(docker system info --format '{{.MemTotal}}' 2>/dev/null)
if [ "$MEMORY" -gt 8000000000 ]; then
    echo "✅ Sufficient memory available"
else
    echo "⚠️  Warning: Less than 8GB memory available"
fi

echo "🎉 Docker setup verification complete!"
```

### Native Installation Verification

```bash
#!/bin/bash
# verify-native-setup.sh

echo "🔍 Verifying Native Installation..."

# Check IBM ACE
if [ -f "/opt/ibm/ace-12.0.3.0/server/bin/mqsiprofile" ]; then
    echo "✅ IBM ACE installed"
    source /opt/ibm/ace-12.0.3.0/server/bin/mqsiprofile
    mqsiversion
else
    echo "❌ IBM ACE not found"
fi

# Check IBM MQ
if command -v runmqversion &> /dev/null; then
    echo "✅ IBM MQ installed"
    runmqversion
else
    echo "❌ IBM MQ not found"
fi

# Check databases
if command -v psql &> /dev/null; then
    echo "✅ PostgreSQL: $(psql --version)"
else
    echo "❌ PostgreSQL not found"
fi

if command -v sqlplus &> /dev/null; then
    echo "✅ Oracle Database client available"
else
    echo "❌ Oracle Database client not found"
fi

# Check monitoring tools
if command -v prometheus &> /dev/null; then
    echo "✅ Prometheus installed"
else
    echo "❌ Prometheus not found"
fi

if command -v grafana-server &> /dev/null; then
    echo "✅ Grafana installed"
else
    echo "❌ Grafana not found"
fi

echo "🎉 Native installation verification complete!"
```

---

## 🚀 **Step-by-Step Setup Guides**

### Docker Setup (Recommended)

```bash
# 1. Install Docker Desktop
# Download from links above based on your OS

# 2. Verify Docker installation
docker --version
docker-compose --version

# 3. Clone the project
git clone https://your-repo-url/iib-esb-financial-apps.git
cd iib-esb-financial-apps

# 4. Start all services
./quick-start.sh

# 5. Monitor startup progress
docker-compose logs -f

# 6. Access applications
# - ACE Console: https://localhost:9443 (admin/admin)
# - Payment API: http://localhost:7800
# - Trading API: http://localhost:7801
# - Grafana: http://localhost:3000 (admin/admin123)
```

### Native Setup (Advanced)

```bash
# 1. Install IBM ACE
wget https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/IMA/0aj9z/0/12.0.3.0-ACE-LINUX64-DEVELOPER.tar.gz
tar -xzf 12.0.3.0-ACE-LINUX64-DEVELOPER.tar.gz
sudo ./ace-12.0.3.0/install.sh

# 2. Install IBM MQ
wget https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev934_linux_x86-64.tar.gz
tar -xzf mqadv_dev934_linux_x86-64.tar.gz
sudo ./mq-installation/install.sh

# 3. Install databases (example for Ubuntu/Debian)
sudo apt-get update
sudo apt-get install postgresql-15 redis-server

# 4. Install Oracle XE
# Follow Oracle's installation guide for your OS

# 5. Install monitoring tools
# Download and extract Prometheus, Grafana, etc. from links above

# 6. Configure services
# Use the configuration files from config/ directory

# 7. Build and deploy applications
./scripts/build-applications.sh
./scripts/deploy-applications.sh
```

---

## 🔗 **Additional Resources**

### IBM Documentation
- **ACE Knowledge Center**: https://www.ibm.com/docs/en/app-connect/12.0?topic=overview
- **MQ Documentation**: https://www.ibm.com/docs/en/ibm-mq/9.3
- **ACE Samples**: https://github.com/ot4i/app-connect-samples

### Community Resources
- **IBM ACE Community**: https://community.ibm.com/community/user/integration/communities/community-home?CommunityKey=b9b5b85d-5353-4e6b-a3a8-1e65720b3c47
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/ibm-integration-bus
- **GitHub Samples**: https://github.com/ibm-messaging

### Support Channels
- **IBM Support**: https://www.ibm.com/support
- **Developer Forums**: https://developer.ibm.com/integration/
- **Red Hat OpenShift**: https://developers.redhat.com/products/app-connect/overview

---

## ⚡ **Performance Tips**

### Docker Optimization
```bash
# Increase Docker memory (Docker Desktop -> Settings -> Resources)
# Recommended: 16GB RAM, 8 CPUs, 100GB storage

# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1

# Enable experimental features
echo '{"experimental": true}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

### Native Optimization
```bash
# Increase JVM heap for ACE
export BAR_OVERRIDE=-Xmx4g

# Optimize database connections
# PostgreSQL: max_connections = 200
# Oracle: processes = 300

# Configure OS limits
ulimit -n 65536
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
```

---

## 🆘 **Troubleshooting Common Issues**

### Issue: IBM software download requires authentication
**Solution**: 
1. Create free IBM ID at https://www.ibm.com/account/reg/us-en/signup?formid=urx-19776
2. Use IBM Support Portal for enterprise downloads
3. For Docker, images are pulled automatically

### Issue: Docker containers failing to start
**Solution**:
```bash
# Check Docker resources
docker system df
docker system prune -a

# Increase memory allocation
# Docker Desktop -> Preferences -> Resources -> Advanced
```

### Issue: Port conflicts
**Solution**:
```bash
# Check port usage
netstat -tulpn | grep :7800

# Modify ports in docker-compose.yml if needed
```

This comprehensive guide ensures you have all the correct, active download links and setup instructions to run the IIB ESB Financial Applications successfully on your local environment! 🚀
