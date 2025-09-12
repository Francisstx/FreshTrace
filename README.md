# FreshTrace 🌱

A blockchain-based supply chain tracking system for agricultural products, enabling transparent farm-to-table traceability with IoT sensor integration on the Stacks blockchain.

## Overview

FreshTrace provides a decentralized solution for tracking agricultural products from farm to consumer, ensuring transparency, authenticity, and food safety throughout the supply chain. Built with Clarity smart contracts on Stacks, it leverages Bitcoin's security for immutable record-keeping and integrates with IoT sensors for automated environmental monitoring.

## Features

- **Producer Registration**: Farmers and producers can register and get verified
- **Batch Creation**: Track individual product batches with harvest dates, quantities, and locations
- **Event Tracking**: Log transportation, processing, and distribution events
- **IoT Sensor Integration**: Automated tracking of temperature, humidity, and GPS coordinates
- **Environmental Monitoring**: Real-time environmental data recording for quality assurance
- **Status Updates**: Real-time status tracking from harvest to retail
- **Verification System**: Contract owner can verify legitimate producers
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
- Event tracking functionality
- IoT sensor data recording
- Access control and error handling

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request