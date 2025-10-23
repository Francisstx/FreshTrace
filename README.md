# FreshTrace 🌱

A blockchain-based supply chain tracking system for agricultural products, enabling transparent farm-to-table traceability with IoT sensor integration, comprehensive quality certification system, and consumer verification portal on the Stacks blockchain.

## Overview

FreshTrace provides a decentralized solution for tracking agricultural products from farm to consumer, ensuring transparency, authenticity, and food safety throughout the supply chain. Built with Clarity smart contracts on Stacks, it leverages Bitcoin's security for immutable record-keeping, integrates with IoT sensors for automated environmental monitoring, supports comprehensive quality certification tracking including organic, fair-trade, and other industry standards, and empowers consumers to verify product authenticity via QR code scanning.

## Features

- **Producer Registration**: Farmers and producers can register and get verified
- **Batch Creation**: Track individual product batches with harvest dates, quantities, and locations
- **QR Code Integration**: Each batch gets a unique QR code for instant verification
- **Event Tracking**: Log transportation, processing, and distribution events
- **IoT Sensor Integration**: Automated tracking of temperature, humidity, and GPS coordinates
- **Environmental Monitoring**: Real-time environmental data recording for quality assurance
- **Quality Certification System**: Track organic, fair-trade, non-GMO, and other certifications
- **Certification Verification**: Contract owner verification of quality certifications
- **Certification Assignment**: Link multiple certifications to product batches
- **Certification Expiry Tracking**: Automated validation of certification validity periods
- **Consumer Verification Portal**: QR code scanning system for end consumers
- **Verification Analytics**: Track consumer scans and engagement metrics
- **Complete Product History**: Consumers can view full supply chain journey
- **Status Updates**: Real-time status tracking from harvest to retail
- **Verification System**: Contract owner can verify legitimate producers and certifications
- **Immutable Records**: All tracking data stored permanently on blockchain

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic knowledge of Clarity smart contracts
- Stacks wallet for testing
- IoT sensors (optional, for automated data collection)
- QR code generator (optional, for physical product labeling)

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

#### Create Product Batch with QR Code
```clarity
(contract-call? .freshtrace create-batch u1 "Organic Tomatoes" u1000 u1700000000 u1702000000 "Greenhouse A" "QR-BATCH-001-2024")
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

#### Consumer Verification via QR Code
```clarity
(contract-call? .freshtrace verify-product-by-qr "QR-BATCH-001-2024" "Retail Store, New York")
```

#### Consumer Verification via Batch ID
```clarity
(contract-call? .freshtrace verify-product-by-batch u1 "Consumer Home, Boston")
```

## Contract Functions

### Public Functions

- `register-producer`: Register a new producer
- `verify-producer`: Verify producer (owner only)
- `create-batch`: Create new product batch with QR code
- `add-quality-certification`: Add new quality certification
- `verify-quality-certification`: Verify certification (owner only)
- `assign-certification-to-batch`: Link certification to batch
- `add-batch-event`: Add tracking event to batch
- `record-sensor-data`: Record IoT sensor readings for a batch
- `update-batch-status`: Update batch status
- `verify-product-by-qr`: Consumer verification via QR code scan
- `verify-product-by-batch`: Consumer verification via batch ID

### Read-Only Functions

- `get-producer`: Get producer information
- `get-batch`: Get batch details
- `get-batch-by-qr`: Get batch details by QR code
- `get-batch-id-by-qr`: Get batch ID from QR code
- `get-batch-event`: Get specific batch event
- `get-batch-event-count`: Get total events for batch
- `get-sensor-data`: Get sensor reading for a batch
- `get-sensor-data-count`: Get total sensor readings for batch
- `get-quality-certification`: Get certification details
- `get-batch-certification`: Get specific batch certification
- `get-batch-certification-count`: Get total certifications for batch
- `get-consumer-verification`: Get specific consumer verification record
- `get-consumer-verification-count`: Get total consumer verifications for batch
- `get-complete-verification-data`: Get all verification data for a batch
- `get-complete-verification-data-by-qr`: Get all verification data by QR code
- `is-certification-active-public`: Check if certification is active and valid
- `is-producer-verified`: Check producer verification status
- `is-batch-expired`: Check if batch has passed expiry date
- `is-qr-code-valid`: Validate if QR code exists in system

## Data Structures

### Producer
- ID, name, location, certification type
- Owner address and verification status

### Batch
- Producer ID, product name, quantity
- Harvest/expiry dates, current location and status
- QR code for consumer verification
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

### Consumer Verification
- Verifier principal address
- Timestamp of verification
- Scan location

## Consumer Verification Portal

FreshTrace now includes a comprehensive consumer verification system that allows end users to authenticate products and view complete supply chain information.

### Features

- **QR Code Scanning**: Instant product verification by scanning QR codes on packaging
- **Direct Batch Lookup**: Verify products using batch ID if QR code is unavailable
- **Complete Transparency**: View full product journey from farm to store
- **Verification Tracking**: All consumer scans are recorded with timestamp and location
- **Real-time Data**: Access current batch status, location, and quality metrics
- **Multi-level Information Access**:
  - Producer details and verification status
  - Product information (name, quantity, dates)
  - Quality certifications with validity status
  - Supply chain events and tracking history
  - IoT sensor readings (temperature, humidity, location)
  - Consumer engagement metrics

### Consumer Verification Workflow

1. **Scan QR Code**: Consumer scans QR code on product packaging
2. **Instant Lookup**: System retrieves batch data using QR code
3. **Display Information**: Complete product history is displayed
4. **Record Verification**: Scan is logged with timestamp and location
5. **Trust Building**: Consumers gain confidence in product authenticity

### Benefits for Consumers

- **Authenticity Guarantee**: Verify products are genuine and from verified producers
- **Safety Assurance**: Check environmental conditions during transit
- **Quality Confidence**: View all certifications (organic, fair-trade, etc.)
- **Transparency**: See complete supply chain journey
- **Informed Decisions**: Make purchasing decisions based on verifiable data

### Benefits for Producers

- **Consumer Engagement**: Track how many consumers verify products
- **Brand Trust**: Build reputation through transparency
- **Marketing Insights**: Understand where products are being purchased
- **Quality Proof**: Demonstrate commitment to quality standards
- **Competitive Advantage**: Differentiate through blockchain verification

## Quality Certification System

FreshTrace supports comprehensive quality certification tracking for various industry standards:

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

## QR Code Implementation Guide

### For Producers

1. **Generate Unique QR Codes**: Create unique identifiers for each batch
2. **Format**: Use alphanumeric strings up to 100 characters
3. **Best Practices**:
   - Include batch identifier prefix (e.g., "QR-BATCH-")
   - Add year/date information
   - Keep codes scannable and high-contrast
   - Test QR codes before mass printing

### For Consumers

1. **Scan QR Code**: Use any QR code scanner or FreshTrace mobile app
2. **View Information**: Instantly access complete product history
3. **Verify Authenticity**: Check producer verification status
4. **Review Quality**: View certifications and sensor data
5. **Track Journey**: See all supply chain events

## Testing

Run the test suite:
```bash
clarinet test
```

Test coverage includes:
- Producer registration and verification
- Batch creation and management with QR codes
- Quality certification system
- Certification verification and assignment
- Event tracking functionality
- IoT sensor data recording
- Consumer verification via QR code
- Consumer verification via batch ID
- QR code lookup and validation
- Complete verification data retrieval
- Access control and error handling
- Batch expiry validation

## API Integration Examples

### Mobile App Integration

```javascript
// Scan QR code and verify product
async function verifyProduct(qrCode, location) {
  const result = await callContract(
    'verify-product-by-qr',
    [qrCode, location]
  );
  return result;
}

// Get complete product information
async function getProductInfo(qrCode) {
  const data = await callReadOnly(
    'get-complete-verification-data-by-qr',
    [qrCode]
  );
  return data;
}
```

### Web Portal Integration

```javascript
// Display product information
async function displayProductDetails(batchId) {
  const verification = await getCompleteVerificationData(batchId);
  
  return {
    producer: verification.producer,
    batch: verification.batch,
    events: verification.event-count,
    sensors: verification.sensor-count,
    certifications: verification.cert-count,
    verifications: verification.verification-count
  };
}
```

## Security Considerations

- **Producer Verification**: Only verified producers can create batches
- **Owner Controls**: Critical functions restricted to contract owner
- **Data Validation**: Comprehensive input validation on all parameters
- **QR Code Uniqueness**: System prevents duplicate QR codes
- **Immutable Records**: All data permanently stored on blockchain
- **Certification Validation**: Automatic expiry checking for certifications
- **Access Control**: Proper authorization checks throughout

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or issues, please open an issue on GitHub or contact the development team.

## Roadmap

- [ ] Mobile app development for QR scanning
- [ ] Integration with major QR code platforms
- [ ] Analytics dashboard for consumer insights
- [ ] Multi-language support
- [ ] Enhanced IoT sensor compatibility
- [ ] AI-powered quality predictions
- [ ] Supply chain optimization recommendations