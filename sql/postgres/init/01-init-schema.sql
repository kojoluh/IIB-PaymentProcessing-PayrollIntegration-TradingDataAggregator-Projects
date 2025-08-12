-- PostgreSQL initialization script for IIB ESB
-- This script creates the necessary database schemas and tables

-- Create error logging schema
CREATE SCHEMA IF NOT EXISTS error_log;

-- Create error log table
CREATE TABLE IF NOT EXISTS error_log.error_log (
    id SERIAL PRIMARY KEY,
    correlation_id VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    severity VARCHAR(50) NOT NULL,
    error_code VARCHAR(50),
    error_message TEXT,
    stack_trace TEXT,
    source_component VARCHAR(255),
    message_flow VARCHAR(255),
    node_name VARCHAR(255),
    additional_data JSONB,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by VARCHAR(255)
);

-- Create audit log table
CREATE TABLE IF NOT EXISTS error_log.audit_log (
    id SERIAL PRIMARY KEY,
    correlation_id VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    operation VARCHAR(100) NOT NULL,
    component VARCHAR(255),
    details JSONB,
    user_id VARCHAR(255),
    session_id VARCHAR(255)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_error_log_correlation_id ON error_log.error_log(correlation_id);
CREATE INDEX IF NOT EXISTS idx_error_log_timestamp ON error_log.error_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_error_log_severity ON error_log.error_log(severity);
CREATE INDEX IF NOT EXISTS idx_audit_log_correlation_id ON error_log.audit_log(correlation_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON error_log.audit_log(timestamp);

-- Insert sample data for testing
INSERT INTO error_log.error_log (correlation_id, severity, error_code, error_message, source_component, message_flow, node_name)
VALUES 
    ('TEST-001', 'INFO', 'INIT', 'Database initialization completed successfully', 'PostgreSQL', 'INIT_FLOW', 'InitNode'),
    ('TEST-002', 'INFO', 'READY', 'IIB ESB system ready for processing', 'SystemMonitor', 'HEALTH_CHECK', 'StatusNode');

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA error_log TO iib_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA error_log TO iib_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA error_log TO iib_user;
