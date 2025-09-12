# FreshTrace 🌱

A blockchain-based supply chain tracking system for agricultural products, enabling transparent farm-to-table traceability with IoT sensor integration and comprehensive quality certification system on the Stacks blockchain.

## Overview

FreshTrace provides a decentralized solution for tracking agricultural products from farm to consumer, ensuring transparency, authenticity, and food safety throughout the supply chain. Built with Clarity smart contracts on Stacks, it leverages Bitcoin's security for immutable record-keeping, integrates with IoT sensors for automated environmental monitoring, and supports comprehensive quality certification tracking including organic, fair-trade, and other industry standards.

## Features

- **Producer Registration**: Farmers and producers can register and get verified
- **Batch Creation**: Track individual product batches with harvest dates, quantities, and locations
- **Event Tracking**: Log transportation, processing, and distribution events
- **IoT Sensor Integration**: Automated tracking of temperature, humidity, and GPS coordinates
- **Environmental Monitoring**: Real-time environmental data recording for quality assurance
- **Quality Certification System**: Track organic, fair-trade, non-GMO, and other certifications
- **Certification Verification**: Contract owner verification of quality certifications
- **Certification Assignment**: Link multiple certifications to product batches
- **Certification Expiry Tracking**: Automated validation of certification validity periods
- **Status Updates**: Real-time status tracking from harvest to retail
- **Verification System**: Contract owner can verify legitimate producers and certifications
- **Immutable Records**: All tracking data stored permanently on blockchain

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic knowledge of Clarity smart contracts
- Stacks wallet for testing
- IoT sensors (optional, for automated data collection)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd freshtrace
```

2. Install dependencies:
```bash
clarinet install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
clarinet test
```

### Usage

#### Register as Producer
```clarity
(contract-call? .freshtrace register-producer "Green Valley Farm" "California, USA" "Organic")
```

#### Create Product Batch
```clarity
(contract-call? .freshtrace create-batch u1 "Organic Tomatoes" u1000 u1700000000 u1702000000 "Greenhouse A")
```

#### Add Quality Certification
```clarity
(contract-call? .freshtrace add-quality-certification "organic" "USDA Organic" "ORG-2024-001" u1700000000 u1752560000)
```

#### Verify Certification (Owner Only)
```clarity
(contract-call? .freshtrace verify-quality-certification u1)
```

#### Assign Certification to Batch
```clarity
(contract-call? .freshtrace assign-certification-to-batch u1 u1)
```

#### Add Tracking Event
```clarity
(contract-call? .freshtrace add-batch-event u1 "shipped" "Distribution Center" "Shipped to regional distributor")
```

#### Record IoT Sensor Data
```clarity
(contract-call? .freshtrace record-sensor-data u1 u2200 u6500 u37754000 u122419000)
```

#### Update Status
```clarity
(contract-call? .freshtrace update-batch-status u1 "delivered")
```

## Contract Functions

### Public Functions

- `register-producer`: Register a new producer
- `verify-producer`: Verify producer (owner only)
- `create-batch`: Create new product batch
- `add-quality-certification`: Add new quality certification
- `verify-quality-certification`: Verify certification (owner only)
- `assign-certification-to-batch`: Link certification to batch
- `add-batch-event`: Add tracking event to batch
- `record-sensor-data`: Record IoT sensor readings for a batch
- `update-batch-status`: Update batch status

### Read-Only Functions

- `get-producer`: Get producer information
- `get-batch`: Get batch details
- `get-batch-event`: Get specific batch event
- `get-batch-event-count`: Get total events for batch
- `get-sensor-data`: Get sensor reading for a batch
- `get-sensor-data-count`: Get total sensor readings for batch
- `get-quality-certification`: Get certification details
- `get-batch-certification`: Get specific batch certification
- `get-batch-certification-count`: Get total certifications for batch
- `is-certification-active-public`: Check if certification is active and valid
- `is-producer-verified`: Check producer verification status

## Data Structures

### Producer
- ID, name, location, certification type
- Owner address and verification status

### Batch
- Producer ID, product name, quantity
- Harvest/expiry dates, current location and status
- Creation timestamp

### Event
- Event type, location, timestamp
- Additional notes for context

### Sensor Data
- Temperature, humidity, GPS coordinates
- Timestamp and batch association

### Quality Certification
- Certification type (organic, fair-trade, non-GMO, etc.)
- Certifying body and certificate ID
- Issue and expiry dates
- Verification status and issuer information

## Quality Certification System

FreshTrace now supports comprehensive quality certification tracking for various industry standards:

### Supported Certification Types
- **Organic**: USDA Organic, EU Organic, JAS Organic
- **Fair Trade**: Fair Trade USA, Fairtrade International
- **Non-GMO**: Non-GMO Project Verified
- **Sustainability**: Rainforest Alliance, UTZ Certified
- **Religious**: Halal, Kosher
- **Regional**: Protected Designation of Origin (PDO), Geographic Indication

### Certification Features
- **Multi-certification Support**: Each batch can have up to 10 different certifications
- **Expiry Tracking**: Automatic validation of certification validity periods
- **Verification System**: Contract owner verification required for legitimacy
- **Immutable Records**: All certification data permanently stored on blockchain
- **Traceability**: Full audit trail from certification issuance to batch assignment

### Certification Workflow
1. **Add Certification**: Certifying bodies or producers add new certifications
2. **Owner Verification**: Contract owner verifies certification authenticity
3. **Batch Assignment**: Verified certifications are assigned to product batches
4. **Validity Checking**: System automatically validates certification status
5. **Consumer Access**: End consumers can verify all certifications for any batch

## IoT Sensor Integration

FreshTrace supports integration with various IoT sensors for automated environmental monitoring:

### Supported Measurements
- **Temperature**: Recorded in centigrade × 100 (e.g., 2200 = 22.00°C)
- **Humidity**: Recorded as percentage × 100 (e.g., 6500 = 65.00%)
- **GPS Coordinates**: Latitude and longitude × 1000000 for precision

### Data Recording
Sensor data is automatically timestamped and permanently stored on the blockchain, providing an immutable record of environmental conditions throughout the supply chain journey.

## Testing

Run the test suite:
```bash
clarinet test
```

Test coverage includes:
- Producer registration and verification
- Batch creation and management
- Quality certification system
- Certification verification and assignment
- Event tracking functionality
- IoT sensor data recording
- Access control and error handling

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request