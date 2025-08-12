# Technical Specifications: Payroll Integration

## 1. Architecture Overview
The solution will be implemented as a message flow within IBM Integration Bus (IIB) v12. It will leverage ESQL for transformation logic and connect to various resources including an SFTP server, an Oracle Database for staging, and IBM MQ for asynchronous communication.

## 2. End-to-End Data Flow
1.  **File Ingestion**: An `FileInput` node polls a designated SFTP directory for new payroll files.
2.  **Parsing & Validation**: A `Compute` node (`PayrollParser.esql`) parses the input file, validates each record, and converts them into a canonical JSON model. Invalid records are routed to an error flow.
3.  **Parallel Transformation**:
    *   A `Compute` node (`GhIPSS_Transformer.esql`) transforms the canonical model into the GhIPSS ACH fixed-width format.
    *   A `Compute` node (`FlexCube_Transformer.esql`) transforms the canonical model into an XML message for FlexCube.
4.  **Staging & Output**:
    *   The generated GhIPSS ACH file is written to an outbound SFTP directory using a `FileOutput` node.
    *   The FlexCube XML message is sent to an MQ queue using an `MQOutput` node.
    *   All processed transactions are logged to an Oracle DB staging table via a `Database` node for reconciliation.
5.  **Error Handling**: Invalid files or records are archived, and a detailed rejection report is generated and sent to an operations team.

## 3. Component Details
- **ESQL `PayrollParser`**: Parses CSV/XML, enforces business rules.
- **ESQL `GhIPSS_Transformer`**: Builds the header, detail, and control records for the ACH file, including hash total calculations.
- **ESQL `FlexCube_Transformer`**: Creates the XML structure for FlexCube journal entries.
- **Message Flow `PayrollProcessingFlow`**: Orchestrates the entire process.
- **Database**: Oracle DB for staging, auditing, and reconciliation tables.