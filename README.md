# IIB ESB Financial Applications - Complete Development Guide

Welcome to the **IBM Integration Bus ESB Financial Applications** project! This comprehensive guide will help you set up, build, deploy, and manage two enterprise-grade financial applications using IBM Integration Bus v12.3.

## 🏗️ Project Overview

This project contains two complete financial applications:

1. **Payment Processing System** - Enterprise payment processing with fraud detection
2. **Trading Data Aggregation Platform** - Real-time market data processing and analytics

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Prerequisites](#-prerequisites)
- [Project Structure](#-project-structure)
- [Installation Guide](#️-installation-guide)
- [Building Applications](#-building-applications)
- [Deployment](#-deployment)
- [Environment Management](#-environment-management)
- [Architecture Overview](#-architecture-overview)
- [API Documentation](#-api-documentation)
- [Monitoring & Observability](#-monitoring--observability)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## 🚀 Quick Start

Get up and running in under 10 minutes:

### 🍎 macOS Apple Silicon (M1/M2/M3) Users - RECOMMENDED
```bash
# 1. Clone and navigate to the project
cd new-project-esql-iib-toolkit

# 2. Use ARM64-optimized setup (better performance)
./quick-start-macos.sh

# 3. Or use the interactive setup assistant
./setup-assistant.sh
```

**📖 See [MACOS_ARM64_GUIDE.md](MACOS_ARM64_GUIDE.md) for detailed Apple Silicon optimization guide**

### Standard Setup (All Platforms)
```bash
# 1. Clone and navigate to the project
cd new-project-esql-iib-toolkit

# 2. Start the complete environment
./quick-start.sh

# 3. Wait for initialization (5-10 minutes)
# The script will show you all service URLs when ready

# 4. Access the applications
open http://localhost:7800/api/payments    # Payment Processing
open http://localhost:7801/api/market-data # Trading Data
open http://localhost:3000                 # Grafana Dashboard
```

## 📦 Prerequisites

### Required Software

1. **Docker Desktop** (Latest version) ⭐ REQUIRED
   - **Windows**: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe
   - **macOS Intel**: https://desktop.docker.com/mac/main/amd64/Docker.dmg
   - **macOS Apple Silicon**: https://desktop.docker.com/mac/main/arm64/Docker.dmg
   - **Linux**: https://docs.docker.com/engine/install/
   - **Requirements**: Minimum 8GB RAM, 50GB storage

2. **IBM App Connect Enterprise Toolkit v12.0.3.0** (For building BAR files)
   - **Developer Edition (Free)**: https://www.ibm.com/support/pages/downloading-ibm-app-connect-enterprise-developer-edition
   - **Linux x86_64**: https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/IMA/0aj9z/0/12.0.3.0-ACE-LINUX64-DEVELOPER.tar.gz
   - **Windows x64**: https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/IMA/0aj9z/0/12.0.3.0-ACE-WIN64-DEVELOPER.exe
   - **Enterprise Edition**: https://www.ibm.com/support/fixcentral/ (Search: "IBM App Connect Enterprise 12.0.3.0")

3. **Git** (For version control)
   - **Windows**: https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe
   - **macOS**: `brew install git` or https://git-scm.com/download/mac
   - **Linux**: `sudo apt-get install git`

### System Requirements

- **CPU**: 4+ cores recommended
- **RAM**: 16GB minimum, 32GB recommended
- **Storage**: 100GB free space
- **Network**: Internet connection for Docker image downloads

## 📁 Project Structure

```
new-project-esql-iib-toolkit/
├── Project1-PaymentProcessingSystem/          # Payment processing application
│   ├── esql/                                  # ESQL business logic modules
│   │   ├── PaymentValidator.esql              # Payment validation logic
│   │   ├── FraudDetector.esql                # Fraud detection algorithms
│   │   └── PaymentGatewayIntegration.esql    # Gateway integrations
│   └── flows/                                 # Message flow definitions
├── Project2-TradingDataAggregator/            # Trading data application
│   ├── esql/                                  # ESQL business logic modules
│   │   ├── MarketDataParser.esql             # Market data parsing
│   │   ├── TechnicalIndicators.esql          # Technical analysis
│   │   └── RiskAnalytics.esql                # Risk calculations
│   └── flows/                                 # Message flow definitions
├── shared-resources/                          # Common utilities
│   └── CommonUtils.esql                      # Shared ESQL functions
├── config/                                    # Configuration files
│   ├── nginx/                                # Load balancer config
│   └── mq/                                   # MQ configuration
├── deployment/                               # Deployment artifacts
│   └── bars/                                # Generated BAR files
├── scripts/                                 # Management scripts
│   ├── build-applications.sh               # Build BAR files
│   ├── deploy-applications.sh              # Deploy applications
│   └── manage-environment.sh               # Environment management
├── monitoring/                              # Monitoring configurations
│   ├── prometheus/                          # Metrics collection
│   └── grafana/                            # Dashboards
├── documentation/                           # Architecture docs
├── docker-compose.yml                      # Docker orchestration
├── quick-start.sh                         # One-click setup
└── README.md                             # This file
```

## 🛠️ Installation Guide

### Option 1: One-Click Setup (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd new-project-esql-iib-toolkit

# Run the quick start script
./quick-start.sh

# Follow the on-screen instructions
```

### Option 2: Manual Setup

1. **Install Docker Desktop**
   ```bash
   # Verify Docker installation
   docker --version
   docker-compose --version
   ```

2. **Start Infrastructure Services**
   ```bash
   docker-compose up -d oracle-xe postgresql influxdb ibm-mq redis
   ```

3. **Start Monitoring Stack**
   ```bash
   docker-compose up -d elasticsearch prometheus grafana kibana
   ```

4. **Start IIB Services**
   ```bash
   docker-compose up -d ace-server nginx
   ```

5. **Verify Services**
   ```bash
   ./scripts/manage-environment.sh status
   ```

## 🔨 Building Applications

### Using Build Script (Recommended)

```bash
# Build all applications
./scripts/build-applications.sh build

# Build specific project
./scripts/build-applications.sh build Project1-PaymentProcessingSystem

# Validate BAR files
./scripts/build-applications.sh validate deployment/bars/Project1-PaymentProcessingSystem.bar

# List generated BAR files
./scripts/build-applications.sh list
```

### Manual Build Process

1. **Install IBM ACE Toolkit**
   - Download and install IBM App Connect Enterprise Toolkit
   - Add toolkit to PATH: `export PATH=$PATH:/opt/ibm/ace-12.0.3.0/server/bin`

2. **Source ACE Profile**
   ```bash
   source /opt/ibm/ace-12.0.3.0/server/bin/mqsiprofile
   ```

3. **Build BAR Files**
   ```bash
   mqsipackagebar -a deployment/bars/PaymentProcessing.bar -w . -k Project1-PaymentProcessingSystem
   mqsipackagebar -a deployment/bars/TradingData.bar -w . -k Project2-TradingDataAggregator
   ```

## 📊 Deployment

### Automated Deployment

```bash
# Deploy all applications
./scripts/deploy-applications.sh deploy

# Deploy specific application
./scripts/deploy-applications.sh deploy PaymentProcessingSystem.bar

# Check deployment status
./scripts/deploy-applications.sh status

# List deployed applications
./scripts/deploy-applications.sh list
```

### Manual Deployment

```bash
# Copy BAR files to ACE server
docker cp deployment/bars/PaymentProcessing.bar ace-server:/home/aceuser/bars/

# Deploy to ACE server
docker exec ace-server mqsideploy ACESERVER -a /home/aceuser/bars/PaymentProcessing.bar

# Verify deployment
docker exec ace-server mqsilist ACESERVER
```

## 🌐 Environment Management

Use the environment management script for comprehensive control:

```bash
# Show environment status
./scripts/manage-environment.sh status

# Start/stop environment
./scripts/manage-environment.sh start
./scripts/manage-environment.sh stop
./scripts/manage-environment.sh restart

# View logs
./scripts/manage-environment.sh logs ace-server 100
./scripts/manage-environment.sh logs  # All services

# Shell access
./scripts/manage-environment.sh shell ace-server
./scripts/manage-environment.sh shell postgresql

# Resource monitoring
./scripts/manage-environment.sh monitor
./scripts/manage-environment.sh resources

# Backup data
./scripts/manage-environment.sh backup
```

## 🏛️ Architecture Overview

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client Apps   │    │   Web Browser   │    │   Trading APIs  │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      Nginx (Port 80)      │
                    │     Load Balancer         │
                    └─────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼──────────┐ ┌─────────▼──────────┐ ┌────────▼──────────┐
│   Payment API      │ │   Trading API      │ │   Management      │
│   (Port 7800)      │ │   (Port 7801)      │ │   (Port 7600)     │
└─────────┬──────────┘ └─────────┬──────────┘ └────────┬──────────┘
          │                      │                     │
          └──────────────────────┼─────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │    IBM App Connect        │
                    │    Enterprise Server      │
                    │                           │
                    │ ┌─────────┐ ┌───────────┐ │
                    │ │Payment  │ │Trading    │ │
                    │ │Processing│ │Data       │ │
                    │ │System   │ │Aggregator │ │
                    │ └─────────┘ └───────────┘ │
                    └─────────────┬─────────────┘
                                 │
    ┌────────────────────────────┼────────────────────────────┐
    │                            │                            │
┌───▼────┐ ┌──────────▼─────────┐ │ ┌──────────▼──────────────┐
│IBM MQ  │ │   Database Layer   │ │ │   Monitoring Stack      │
│Message │ │                    │ │ │                         │
│Queue   │ │┌─────────────────┐ │ │ │┌─────────┐ ┌──────────┐ │
│        │ ││Oracle XE        │ │ │ ││Grafana  │ │Prometheus│ │
│        │ ││(Payments)       │ │ │ ││         │ │          │ │
│        │ │└─────────────────┘ │ │ │└─────────┘ └──────────┘ │
│        │ │┌─────────────────┐ │ │ │┌─────────┐ ┌──────────┐ │
│        │ ││PostgreSQL       │ │ │ ││Kibana   │ │ELK Stack │ │
│        │ ││(Config/Audit)   │ │ │ ││         │ │          │ │
│        │ │└─────────────────┘ │ │ │└─────────┘ └──────────┘ │
│        │ │┌─────────────────┐ │ │ └─────────────────────────┘
│        │ ││InfluxDB         │ │ │
│        │ ││(Time Series)    │ │ │
│        │ │└─────────────────┘ │ │
│        │ │┌─────────────────┐ │ │
│        │ ││Redis (Cache)    │ │ │
│        │ │└─────────────────┘ │ │
└────────┘ └────────────────────┘ │
```

### Component Interactions

1. **API Gateway Layer** (Nginx)
   - Load balances requests between ACE instances
   - SSL termination and security headers
   - Request routing and rate limiting

2. **Integration Layer** (IBM ACE)
   - Message processing and transformation
   - Business logic execution (ESQL)
   - Protocol mediation and service orchestration

3. **Data Layer**
   - **Oracle XE**: Payment transactions and fraud data
   - **PostgreSQL**: Configuration and audit logs
   - **InfluxDB**: Time-series market data
   - **Redis**: Session caching and temporary storage

4. **Messaging Layer** (IBM MQ)
   - Reliable message delivery
   - Transaction coordination
   - Event-driven communication

5. **Monitoring Layer**
   - **Prometheus**: Metrics collection
   - **Grafana**: Visualization dashboards
   - **ELK Stack**: Log aggregation and analysis

## 📚 API Documentation

### Payment Processing API

**Base URL**: `http://localhost:7800/api/payments`

#### Endpoints

**POST /api/payments/process**
Process a payment transaction
```json
{
  "transactionId": "TXN001",
  "customerId": "CUST123",
  "merchantId": "MERCH456",
  "amount": 100.50,
  "currency": "USD",
  "paymentMethod": "CREDIT_CARD",
  "cardNumber": "4111111111111111",
  "expiryDate": "12/25",
  "cvv": "123"
}
```

**GET /api/payments/{transactionId}**
Get payment status
```json
{
  "transactionId": "TXN001",
  "status": "COMPLETED",
  "amount": 100.50,
  "currency": "USD",
  "fraudScore": 15,
  "processedAt": "2025-01-27T10:00:00Z"
}
```

### Trading Data API

**Base URL**: `http://localhost:7801/api/market-data`

#### Endpoints

**POST /api/market-data/ingest**
Ingest market data
```json
{
  "symbol": "AAPL",
  "price": 150.25,
  "volume": 1000000,
  "timestamp": "2025-01-27T10:00:00Z",
  "exchange": "NASDAQ"
}
```

**GET /api/market-data/{symbol}/indicators**
Get technical indicators
```json
{
  "symbol": "AAPL",
  "sma20": 148.50,
  "ema20": 149.75,
  "rsi": 65.5,
  "macd": 2.5,
  "timestamp": "2025-01-27T10:00:00Z"
}
```

## 📊 Monitoring & Observability

### Grafana Dashboards

Access: `http://localhost:3000` (admin/admin123)

**Pre-configured Dashboards:**
- IIB Performance Metrics
- Payment Processing KPIs
- Trading Data Analytics
- System Resource Usage
- Error Tracking and Alerts

### Prometheus Metrics

Access: `http://localhost:9090`

**Key Metrics:**
- `ace_message_flow_throughput`
- `payment_transaction_count`
- `fraud_detection_score`
- `market_data_ingestion_rate`
- `system_cpu_usage`

### ELK Stack

**Elasticsearch**: `http://localhost:9200`
**Kibana**: `http://localhost:5601`

**Log Categories:**
- ACE server logs
- Payment transaction logs
- Market data processing logs
- System error logs
- Audit trail logs

## 🔧 Troubleshooting

### Common Issues

#### 1. Services Not Starting

```bash
# Check Docker status
docker info

# Check container logs
docker-compose logs ace-server

# Restart specific service
docker-compose restart ace-server
```

#### 2. Database Connection Issues

```bash
# Test Oracle connection
docker exec oracle-xe sqlplus system/password123@localhost:1521/XE

# Test PostgreSQL connection
docker exec postgresql psql -U iib_user -d iib_config

# Check database logs
docker-compose logs oracle-xe postgresql
```

#### 3. Application Deployment Failures

```bash
# Check BAR file integrity
./scripts/build-applications.sh validate deployment/bars/PaymentProcessing.bar

# Redeploy application
./scripts/deploy-applications.sh deploy PaymentProcessing.bar

# Check ACE server logs
docker exec ace-server cat /var/mqsi/ACESERVER/stdout
```

#### 4. Performance Issues

```bash
# Monitor resource usage
docker stats

# Check system resources
./scripts/manage-environment.sh resources

# View detailed monitoring
./scripts/manage-environment.sh monitor
```

### Getting Help

1. **Check Logs**: Always start with checking logs for error messages
2. **Resource Monitor**: Use the built-in resource monitoring tools
3. **Documentation**: Refer to IBM ACE documentation for specific errors
4. **Community**: Check IBM developer forums and Stack Overflow

## 🤝 Contributing

### Development Setup

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/your-feature`
3. **Make changes and test thoroughly**
4. **Submit pull request with detailed description**

### Code Standards

- **ESQL**: Follow IBM ESQL coding standards
- **Documentation**: Update documentation for any changes
- **Testing**: Include unit tests for new functionality
- **Commit Messages**: Use conventional commit format

### Testing

```bash
# Run integration tests
./scripts/test-integration.sh

# Performance testing
./scripts/test-performance.sh

# Security testing
./scripts/test-security.sh
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- IBM App Connect Enterprise team for the excellent integration platform
- Docker community for containerization tools
- Open source monitoring tools (Prometheus, Grafana, ELK Stack)

## 📞 Support

For technical support or questions:

1. **Documentation**: Check this README and the `/documentation` folder
2. **Issues**: Create GitHub issues for bugs or feature requests
3. **Discussions**: Use GitHub Discussions for questions and community support

---

**Happy Integration!** 🚀

*Built with ❤️ for the IBM Integration Bus community*
