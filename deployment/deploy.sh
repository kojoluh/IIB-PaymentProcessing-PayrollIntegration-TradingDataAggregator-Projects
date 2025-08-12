# Deployment Configuration for IIB ESB Financial Applications
# IBM Integration Bus v12.3 Deployment Scripts

# Project 1: Payment Processing System Deployment
echo "Deploying Payment Processing System..."

# Create Integration Server
mqsicreateintegrationserver IB_NODE -e PaymentProcessingEG -w 7800 -p 7843 -k PaymentProcessingEG

# Deploy shared libraries first
mqsideploy IB_NODE -e PaymentProcessingEG -a shared-resources/CommonUtilities.bar

# Deploy Payment Processing Application
mqsideploy IB_NODE -e PaymentProcessingEG -a Project1-PaymentProcessingSystem/PaymentProcessingApp.bar

# Configure database connections
mqsisetdbparms IB_NODE -n PaymentDB -u payment_user -p payment_password

# Set environment variables
mqsichangeproperties IB_NODE -e PaymentProcessingEG -o ComIbmJVMManager -n jvmSystemProperty -v "payment.gateway.endpoint=https://api.stripe.com/v1"
mqsichangeproperties IB_NODE -e PaymentProcessingEG -o ComIbmJVMManager -n jvmSystemProperty -v "fraud.detection.threshold=50"

# Project 2: Trading Data Aggregator Deployment
echo "Deploying Trading Data Aggregation Platform..."

# Create Integration Server
mqsicreateintegrationserver IB_NODE -e TradingDataEG -w 7801 -p 7844 -k TradingDataEG

# Deploy shared libraries
mqsideploy IB_NODE -e TradingDataEG -a shared-resources/CommonUtilities.bar

# Deploy Trading Data Application
mqsideploy IB_NODE -e TradingDataEG -a Project2-TradingDataAggregator/TradingDataApp.bar

# Configure market data connections
mqsisetdbparms IB_NODE -n MarketDataDB -u market_user -p market_password

# Configure trading system endpoints
mqsichangeproperties IB_NODE -e TradingDataEG -o ComIbmJVMManager -n jvmSystemProperty -v "trading.system.endpoint=http://trading-platform.internal/api"
mqsichangeproperties IB_NODE -e TradingDataEG -o ComIbmJVMManager -n jvmSystemProperty -v "market.data.source=NYSE,NASDAQ,CME"

# Configure message queues
echo "Configuring WebSphere MQ..."

# Payment Processing Queues
echo "DEFINE QLOCAL(PAYMENT.IN) DEFPSIST(YES) MAXDEPTH(10000)" | runmqsc QM_IIB
echo "DEFINE QLOCAL(PAYMENT.OUT) DEFPSIST(YES) MAXDEPTH(10000)" | runmqsc QM_IIB
echo "DEFINE QLOCAL(PAYMENT.ERROR) DEFPSIST(YES) MAXDEPTH(5000)" | runmqsc QM_IIB

# Trading Data Queues
echo "DEFINE QLOCAL(MARKET.DATA.IN) DEFPSIST(YES) MAXDEPTH(50000)" | runmqsc QM_IIB
echo "DEFINE QLOCAL(NEWS.FEED) DEFPSIST(YES) MAXDEPTH(20000)" | runmqsc QM_IIB
echo "DEFINE QLOCAL(TRADING.ALERTS) DEFPSIST(YES) MAXDEPTH(10000)" | runmqsc QM_IIB
echo "DEFINE QLOCAL(ERROR.QUEUE) DEFPSIST(YES) MAXDEPTH(5000)" | runmqsc QM_IIB

# Start Integration Servers
mqsistart IB_NODE
mqsistartmsgflow IB_NODE -e PaymentProcessingEG -m PaymentProcessingFlow
mqsistartmsgflow IB_NODE -e TradingDataEG -m MarketDataAggregationFlow

echo "Deployment completed successfully!"
echo "Payment Processing System available on port 7800"
echo "Trading Data Aggregator available on port 7801"

# Health check endpoints
echo "Health check URLs:"
echo "- Payment Processing: http://localhost:7800/health"
echo "- Trading Data: http://localhost:7801/health"
