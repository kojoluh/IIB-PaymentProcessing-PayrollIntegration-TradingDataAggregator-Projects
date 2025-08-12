# Testing Framework for IIB ESB Financial Applications

## Project 1: Payment Processing System Tests

### Test Scenarios

#### 1. Payment Validation Tests
- **Valid Payment Test**: Standard credit card payment within limits
- **Invalid Amount Test**: Zero or negative amounts
- **Currency Validation Test**: Unsupported currency codes
- **Account Format Test**: Invalid account number formats

#### 2. Fraud Detection Tests
- **High Amount Transaction**: Payment above $10,000 threshold
- **Rapid Transaction Test**: Multiple payments within short timeframe
- **Off-Hours Transaction**: Payment outside business hours
- **Geographic Anomaly**: Payment from unusual location
- **New Device Test**: Payment from unrecognized device

#### 3. Gateway Integration Tests
- **Stripe Integration**: Credit card processing via Stripe API
- **PayPal Integration**: Digital wallet payment processing
- **Bank Transfer**: ACH/Wire transfer processing
- **Decline Scenarios**: Various decline reason codes
- **Timeout Handling**: Gateway timeout scenarios

#### 4. Error Handling Tests
- **Network Failure**: Gateway connectivity issues
- **Database Failure**: Audit logging failures
- **Invalid Input**: Malformed JSON messages
- **System Overload**: High volume stress testing

### Sample Test Cases

#### Test Case 1: Valid Credit Card Payment
```json
{
  "testName": "ValidCreditCardPayment",
  "input": {
    "payment": {
      "amount": 100.00,
      "currency": "USD",
      "method": "CREDIT_CARD",
      "cardNumber": "4111111111111111",
      "accountNumber": "12345678"
    },
    "customer": {
      "id": "CUST001",
      "email": "test@example.com"
    },
    "merchant": {
      "id": "MERCH001"
    },
    "transaction": {
      "location": "US-NY"
    },
    "device": {
      "fingerprint": "known-device-123"
    }
  },
  "expectedOutput": {
    "validation": {
      "isValid": true
    },
    "fraudAnalysis": {
      "status": "APPROVED",
      "riskScore": 0
    },
    "gateway": {
      "success": true,
      "status": "AUTHORIZED"
    }
  }
}
```

#### Test Case 2: High-Risk Fraud Detection
```json
{
  "testName": "HighRiskFraudDetection",
  "input": {
    "payment": {
      "amount": 15000.00,
      "currency": "USD",
      "method": "CREDIT_CARD",
      "cardNumber": "4111111111111111",
      "accountNumber": "12345678"
    },
    "customer": {
      "id": "CUST001"
    },
    "merchant": {
      "id": "MERCH001"
    },
    "transaction": {
      "location": "RU-MOSCOW"
    },
    "device": {
      "fingerprint": "unknown-device-456"
    }
  },
  "expectedOutput": {
    "validation": {
      "isValid": true
    },
    "fraudAnalysis": {
      "status": "HIGH_RISK",
      "riskScore": 90,
      "requiresManualReview": true
    }
  }
}
```

## Project 2: Trading Data Aggregator Tests

### Test Scenarios

#### 1. Market Data Parsing Tests
- **Binary Feed Parsing**: NYSE/NASDAQ binary format
- **Trade Message Processing**: Trade execution messages
- **Quote Message Processing**: Bid/ask quote messages
- **Order Book Processing**: Market depth data
- **Error Message Handling**: Malformed binary data

#### 2. Technical Analysis Tests
- **Moving Average Calculation**: SMA and EMA calculations
- **RSI Calculation**: Relative Strength Index
- **MACD Calculation**: Moving Average Convergence Divergence
- **Bollinger Bands**: Statistical analysis bands
- **Volume Analysis**: Volume-based indicators

#### 3. Risk Analytics Tests
- **VaR Calculation**: Value at Risk computation
- **Expected Shortfall**: Tail risk measurement
- **Volatility Analysis**: Historical volatility
- **Beta Calculation**: Systematic risk measurement
- **Stress Testing**: Scenario analysis

#### 4. Data Quality Tests
- **Price Validation**: Reasonable price ranges
- **Volume Validation**: Volume consistency
- **Timestamp Validation**: Proper time sequencing
- **Duplicate Detection**: Duplicate message handling
- **Gap Analysis**: Missing data detection

### Sample Test Cases

#### Test Case 1: Trade Message Processing
```json
{
  "testName": "TradeMessageProcessing",
  "input": {
    "messageType": "TRADE",
    "binaryData": "01415041004E4120000003E8000000640000000005F5E100",
    "expectedSymbol": "AAPL",
    "expectedPrice": 150.25,
    "expectedVolume": 1000
  },
  "expectedOutput": {
    "messageType": "TRADE",
    "instrument": {
      "symbol": "AAPL",
      "exchange": "NASDAQ"
    },
    "marketData": {
      "price": 150.25,
      "volume": 1000
    },
    "requiresAnalysis": true
  }
}
```

#### Test Case 2: Technical Indicators
```json
{
  "testName": "TechnicalIndicatorsCalculation",
  "input": {
    "instrument": {
      "symbol": "MSFT",
      "exchange": "NASDAQ"
    },
    "marketData": {
      "price": 300.50,
      "volume": 2000,
      "timestamp": "2025-08-07T14:30:00Z"
    },
    "historicalPrices": [295.0, 297.5, 299.0, 301.0, 300.5]
  },
  "expectedOutput": {
    "technicalAnalysis": {
      "indicators": {
        "sma20": 298.6,
        "rsi": 65.2,
        "macd": 1.25
      },
      "signals": {
        "overallSignal": "BUY",
        "signalStrength": 3
      }
    }
  }
}
```

### Performance Test Requirements

#### Payment Processing Performance
- **Throughput**: 1000 transactions per second
- **Latency**: < 100ms end-to-end processing
- **Concurrent Users**: 500 simultaneous connections
- **Data Volume**: 1M transactions per day

#### Trading Data Performance
- **Throughput**: 10,000 messages per second
- **Latency**: < 10ms for market data processing
- **Data Volume**: 100M market data points per day
- **Real-time Processing**: Sub-millisecond technical indicators

### Test Execution Instructions

1. **Setup Test Environment**
   ```bash
   # Start IIB Test Environment
   mqsistart TEST_NODE
   
   # Deploy test applications
   mqsideploy TEST_NODE -e TestEG -a test-applications/PaymentProcessingTest.bar
   mqsideploy TEST_NODE -e TestEG -a test-applications/TradingDataTest.bar
   ```

2. **Run Unit Tests**
   ```bash
   # Payment Processing Tests
   curl -X POST http://localhost:7800/test/payment-validation -d @test-cases/payment-tests.json
   
   # Trading Data Tests
   curl -X POST http://localhost:7801/test/market-data -d @test-cases/trading-tests.json
   ```

3. **Performance Testing**
   ```bash
   # Load testing with JMeter
   jmeter -n -t performance-tests/payment-load-test.jmx
   jmeter -n -t performance-tests/trading-data-load-test.jmx
   ```

4. **Integration Testing**
   ```bash
   # End-to-end integration tests
   ./run-integration-tests.sh
   ```

### Expected Test Results

#### Payment Processing System
- **Validation Accuracy**: 99.9% correct validation decisions
- **Fraud Detection**: 95% fraud detection rate with <2% false positives
- **Gateway Success**: 99.5% successful gateway integrations
- **Performance**: <100ms average response time

#### Trading Data Aggregator
- **Data Accuracy**: 99.99% accurate market data processing
- **Technical Indicators**: <1% calculation variance from reference
- **Risk Analytics**: Real-time VaR calculations within 5ms
- **Throughput**: Sustained 10,000 msg/sec processing rate

### Monitoring and Alerting

#### Key Performance Indicators (KPIs)
- **Payment Success Rate**: >99%
- **Fraud Detection Accuracy**: >95%
- **Market Data Latency**: <10ms
- **System Availability**: >99.9%
- **Error Rate**: <0.1%

#### Alert Thresholds
- **High Error Rate**: >1% errors in 5 minutes
- **High Latency**: >500ms average response time
- **Low Throughput**: <50% of expected volume
- **System Down**: No successful transactions in 1 minute
