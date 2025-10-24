# UNY-ID: Energy & RWA Passport System

**Compliance-native identity and attestation infrastructure for energy markets, carbon trading, and Real-World Assets (RWAs)**

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Smart Contracts](#smart-contracts)
4. [Credential Schemas](#credential-schemas)
5. [Workflows](#workflows)
6. [Integration Guide](#integration-guide)
7. [Standards & Compliance](#standards--compliance)
8. [Deployment](#deployment)
9. [API Reference](#api-reference)

---

## Overview

### What is UNY-ID?

**UNY-ID** is a **DID + NFT + ERC-6551** identity system that provides **provable, tradable, auditable, and privacy-preserving** identities for:

- **Entities**: People, companies, energy facilities
- **Devices**: Smart meters, inverters, EV chargers
- **Assets**: Solar farms, wind turbines, battery systems
- **Instruments**: RECs, EACs, carbon credits, green bonds

### Why It Exists

Traditional energy and carbon markets suffer from:

- **Spreadsheet cosplay** - Manual data entry, no cryptographic proof
- **Double-counting** - Same credit sold multiple times across registries
- **Compliance friction** - Weeks of KYC/AML for every transaction
- **Opaque provenance** - Can't trace energy from meter to certificate
- **Jurisdictional fragmentation** - Different rules in every market

**UNY-ID solves this** by making compliance **cryptographic, automated, and portable**.

### Core Capabilities

#### 1. **Universal Identity**
- **W3C DID** standard (`did:unykorn:<hash>`)
- **ERC-721 Soulbound Token** (non-transferable by default)
- **ERC-6551 Token-Bound Account** (wallet attached to identity)
- **Human-readable IDs** (`UNYID:US-ACME-PLANT01-MTR-INV12`)

#### 2. **Verifiable Credentials**
- **Schema-based** (KYC, facility, device, energy output, carbon, ESG)
- **Issuer permissions** (KYC providers, verifiers, MRV oracles)
- **Expiry & freshness** checks
- **Revocation** support
- **Privacy-preserving** (only hashes on-chain)

#### 3. **Dynamic Compliance**
- **Transfer hooks** (pre-flight checks before every transfer)
- **Jurisdiction rules** (allow/block by country)
- **Accreditation** (qualified purchaser, accredited investor)
- **Sanctions screening** (OFAC/FATF integration)
- **Lock-ups** (minimum holding periods)

#### 4. **MRV (Measurement, Reporting, Verification)**
- **Hardware-rooted** device attestations (TPM/TEE)
- **Signed meter readings** (ECDSA signatures from devices)
- **Anti-replay** protection (nonce-based)
- **Aggregation** (facility-level totals)
- **Standards**: OpenADR, IEEE 2030.5, OCPP, OPC-UA

#### 5. **Energy Certificates**
- **RECs/EACs** (Renewable Energy Certificates, Energy Attribute Certificates)
- **Vintage tracking** (month/year of generation)
- **Serial assignment** (unique serial per MWh)
- **Compliance-gated** transfers
- **Registry bridge** (I-REC, GOs, US RECs)

#### 6. **Regulated Securities**
- **ERC-1400-style partitions** (Reg D, Reg S, etc.)
- **Controller** force transfer (for legal compliance)
- **Document references** (offering memos, amendments)
- **Transfer restrictions** (lock-ups, whitelist)

#### 7. **Retirement/Redemption**
- **Anti-double-count** (nonce-based serial tracking)
- **Registry bridge** (Verra, Gold Standard, ACR, Puro)
- **Beneficiary tracking** (who retired for whom)
- **Evidence anchoring** (IPFS retirement certificates)

---

## Architecture

### System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         UNY-ID SYSTEM                             │
└─────────────────────────────────────────────────────────────────┘

┌───────────────────┐         ┌──────────────────────┐
│  IdentityNFT      │◄────────┤ AttestationRegistry  │
│  (ERC-721 SBT)    │         │  (Verifiable Creds)  │
│  + ERC-6551 TBA   │         └──────────────────────┘
└───────────────────┘                     ▲
         │                                │
         │  references                    │ validates
         ▼                                │
┌───────────────────┐         ┌──────────────────────┐
│ ComplianceRegistry│◄────────┤   DeviceOracle       │
│  (Transfer Rules) │         │   (MRV Data)         │
└───────────────────┘         └──────────────────────┘
         │                                │
         │ gates                          │ attests
         ▼                                ▼
┌───────────────────┐         ┌──────────────────────┐
│   ERC1155REC      │         │  ERC1400Adapter      │
│ (RECs/EACs/Certs) │         │ (Securities/Bonds)   │
└───────────────────┘         └──────────────────────┘
         │                                │
         └────────►  RetirementLocker  ◄──┘
                   (Anti-Double-Count)
                            │
                            ▼
                  ┌──────────────────┐
                  │ External         │
                  │ Registries       │
                  │ (Verra/GS/I-REC) │
                  └──────────────────┘
```

### Data Flow

1. **Enrollment**: Entity onboards → KYC VC issued → IdentityNFT minted
2. **Facility Setup**: Facility registered → Facility VC issued → Device credentials added
3. **MRV**: Device readings → DeviceOracle validates → Energy attestations recorded
4. **Issuance**: Policy conditions met → REC/certificate minted → Serial assigned
5. **Transfer**: Buyer presents IdentityNFT → ComplianceRegistry checks VCs → Transfer approved/denied
6. **Retirement**: Holder locks tokens → RetirementLocker marks serials retired → Bridge notifies registry

---

## Smart Contracts

### Core Contracts

| Contract | Purpose | Standards |
|----------|---------|-----------|
| **IdentityNFT** | Identity passport (SBT) | ERC-721, W3C DID, ERC-6551 |
| **AttestationRegistry** | Verifiable credentials | W3C VC Data Model |
| **ComplianceRegistry** | Transfer rules & gates | ERC-1066 (status codes) |
| **DeviceOracle** | MRV data ingress | EIP-712 (signatures) |
| **ERC1155REC** | Energy certificates | ERC-1155, I-REC, GO |
| **ERC1400Adapter** | Regulated securities | ERC-1400 (partitioned) |
| **RetirementLocker** | Retirement & anti-double-count | - |

### Contract Details

#### 1. IdentityNFT

**File**: `contracts/identity/IdentityNFT.sol`

**Features**:
- Non-transferable by default (Soulbound Token)
- W3C DID binding (`did:unykorn:<hash>`)
- ERC-6551 Token-Bound Account support
- Human-readable short IDs (`UNYID:...`)
- Credential anchor hashes (privacy-preserving)
- Entity types: Person, Company, Facility, Device

**Key Functions**:
```solidity
function mint(address to, string did, string shortId, uint8 entityType, ...) 
  → uint256 tokenId

function bindTBA(uint256 tokenId, address tbaAddress)

function anchorCredential(uint256 tokenId, bytes32 credentialHash, string schemaId)

function isValid(uint256 tokenId) → bool
```

#### 2. AttestationRegistry

**File**: `contracts/identity/AttestationRegistry.sol`

**Features**:
- Schema-based credential types (9 default schemas)
- Multi-issuer support (role-based permissions)
- Expiry and freshness validation
- Revocation with reason tracking
- Batch operations for efficiency

**Default Schemas**:
- `SCHEMA/KYC_ORG_v1` - Entity KYC/AML
- `SCHEMA/SANCTIONS_SCREEN_v1` - OFAC/FATF screening
- `SCHEMA/FACILITY_v1` - Physical facility
- `SCHEMA/DEVICE_METER_v1` - Smart meter/IoT device
- `SCHEMA/ENERGY_OUTPUT_v1` - MRV attestation
- `SCHEMA/REC_ISSUANCE_v1` - REC issuance record
- `SCHEMA/CARBON_CREDIT_v1` - Carbon credit
- `SCHEMA/RETIREMENT_v1` - Retirement proof
- `SCHEMA/ESG_DISCLOSURE_v1` - ESG reporting

**Key Functions**:
```solidity
function record(address subject, string schemaId, bytes32 dataHash, uint256 validUntil, ...)
  → bytes32 attestationId

function isValid(address subject, string schemaId) → bool

function isFresh(bytes32 attestationId, uint256 freshnessDays) → bool

function revoke(bytes32 attestationId, string reason)
```

#### 3. ComplianceRegistry

**File**: `contracts/compliance/ComplianceRegistry.sol`

**Features**:
- Token class → required credential mappings
- Jurisdiction-based restrictions (allow/block by country)
- Transfer pre-flight checks
- Whitelist/blacklist management
- Account freezing
- Sanctions integration

**Key Functions**:
```solidity
function setRules(bytes32 tokenClass, string[] requiredSchemas, uint256 freshnessDays, ...)

function preTransferCheck(bytes32 tokenClass, address from, address to, ...)
  → (bool allowed, string reason)

function isCompliant(address account, bytes32 tokenClass) → bool

function updateProfile(address account, string jurisdiction, bool accredited)

function freezeAccount(address account, string reason)
```

#### 4. DeviceOracle

**File**: `contracts/oracles/DeviceOracle.sol`

**Features**:
- Device registration (firmware hash + public key)
- Batch posting of signed readings
- ECDSA signature verification (EIP-191/EIP-712)
- Anti-replay protection (nonce-based)
- Facility aggregation support

**Key Functions**:
```solidity
function registerDevice(address owner, string deviceDid, string facilityDid, ...)

function postReading(MeterReading reading)

function postBatch(MeterReading[] readings)

function computeFacilityAggregate(string facilityDid, uint256 periodStart, uint256 periodEnd)
  → (uint256 totalKwh, uint256 deviceCount)
```

**MeterReading Struct**:
```solidity
struct MeterReading {
  string deviceDid;       // Device DID
  uint256 timestamp;      // Reading timestamp
  uint256 value;          // Reading value (watt-hours)
  uint8 valueType;        // 0=kWh, 1=kW, 2=voltage, 3=current
  bytes32 dataHash;       // Hash of full data
  bytes signature;        // Device signature
  uint256 nonce;          // Anti-replay nonce
}
```

#### 5. ERC1155REC

**File**: `contracts/tokens/ERC1155REC.sol`

**Features**:
- Multi-vintage support (one tokenId per vintage/facility/tech)
- Serial number assignment (for registry bridge)
- Compliance-gated transfers (via ComplianceRegistry)
- Metadata: region, technology, facility, vintage, MWh
- Retirement tracking

**Key Functions**:
```solidity
function createCertificate(string name, string region, string technology, uint256 vintage, ...)
  → uint256 tokenId

function issue(address to, uint256 tokenId, uint256 amount)
  → string[] serialNumbers

function retire(uint256 tokenId, uint256 amount, bytes32 evidenceHash, string[] serialStrings)

function getStats(uint256 tokenId) 
  → (uint256 issued, uint256 retired, uint256 outstanding)
```

#### 6. ERC1400Adapter

**File**: `contracts/tokens/ERC1400Adapter.sol`

**Features**:
- Partitions (tranches) for investor classes (Reg D, Reg S, etc.)
- Controller-driven force transfer (legal compliance)
- Transfer restrictions (lock-ups, whitelist)
- Document references (offering memos, amendments)

**Key Functions**:
```solidity
function createPartition(string name, bytes32 complianceClass) → bytes32 partitionId

function issueByPartition(bytes32 partitionId, address to, uint256 amount)

function transferByPartition(bytes32 partitionId, address to, uint256 amount)

function controllerTransfer(address from, address to, uint256 amount, string reason)

function publishDocument(string name, string uri, bytes32 documentHash)
```

#### 7. RetirementLocker

**File**: `contracts/retirement/RetirementLocker.sol`

**Features**:
- Multi-registry support (Verra, GS, ACR, Puro, I-REC, GO)
- Anti-double-count (nonce-based serial tracking)
- Evidence anchoring (IPFS certificates)
- Beneficiary tracking
- Retirement attestations (VCs)

**Key Functions**:
```solidity
function retire(address token, uint256 tokenId, uint256 amount, address beneficiary,
                string[] serials, bytes32 evidenceHash, string registry, string reason)
  → uint256 retirementId

function bridgeRetirement(uint256 retirementId, string registryRef)

function issueRetirementAttestation(uint256 retirementId) → bytes32 attestationId

function isSerialRetired(string registry, string serial) → bool
```

---

## Credential Schemas

### Schema Format

All credentials follow the **W3C Verifiable Credentials Data Model**:

```json
{
  "@context": ["https://www.w3.org/2018/credentials/v1"],
  "type": ["VerifiableCredential", "<SpecificType>"],
  "issuer": "did:unykorn:<issuer-hash>",
  "credentialSubject": {
    "id": "did:unykorn:<subject-hash>",
    ...
  },
  "issuanceDate": "2025-10-24T00:00:00Z",
  "expirationDate": "2026-10-24T00:00:00Z",
  "evidence": [...],
  "proof": {"type": "EcdsaSecp256k1Signature2019", "jws": "..."}
}
```

### Example: Facility Credential

```json
{
  "@context": ["https://www.w3.org/2018/credentials/v1"],
  "type": ["VerifiableCredential", "FacilityCredential"],
  "issuer": "did:unykorn:REGISTRY",
  "credentialSubject": {
    "id": "did:unykorn:ACME-PLANT01",
    "name": "ACME Solar Plant 01",
    "location": {"lat": 32.89, "lon": -96.76, "country": "US"},
    "gridZone": "ERCOT",
    "permits": ["PERMIT-12345"],
    "technology": "PV",
    "capacityMW": 50.2
  },
  "evidence": [{"type":"PermitDoc","hash":"b3..."}],
  "expirationDate": "2027-12-31T00:00:00Z",
  "proof": {"type":"EcdsaSecp256k1Signature2019","jws":"..."}
}
```

### Example: Energy Output Attestation

```json
{
  "schema": "SCHEMA/ENERGY_OUTPUT_v1",
  "subject": "did:unykorn:ACME-PLANT01:INV12",
  "timeWindow": {
    "from": "2025-10-01T00:00:00Z",
    "to": "2025-10-01T01:00:00Z"
  },
  "kwh": 1287.4,
  "meterSig": "0x...",
  "oracle": "did:unykorn:ORACLE01",
  "hash": "b9f7..."
}
```

### Example: REC Metadata

```json
{
  "name": "REC US-ERCOT 2025-10-01 (1 MWh)",
  "symbol": "REC",
  "attributes": [
    {"trait_type": "Region", "value": "ERCOT"},
    {"trait_type": "Vintage", "value": "2025-10"},
    {"trait_type": "Technology", "value": "PV"},
    {"trait_type": "Facility", "value": "ACME-PLANT01"},
    {"trait_type": "Serial", "value": "ERCOT-2025-10-000001"}
  ],
  "external_url": "https://unykorn.org/rec/serial/ERCOT-2025-10-000001"
}
```

---

## Workflows

### Workflow 1: Entity Onboarding

**Steps**:

1. **KYC/AML Check** (off-chain)
   - Collect entity information (name, address, beneficial owners)
   - Run KYC/AML screening via provider (Chainalysis, Elliptic, etc.)
   - Sanctions screening (OFAC, FATF)

2. **Issue KYC VC**
   ```javascript
   const kycHash = keccak256(kycDataJSON);
   const attestationId = await attestationRegistry.record(
     entityAddress,
     "SCHEMA/KYC_ORG_v1",
     kycHash,
     validUntil, // 1 year
     evidenceHash
   );
   ```

3. **Mint IdentityNFT**
   ```javascript
   const tokenId = await identityNFT.mint(
     entityAddress,
     "did:unykorn:abc123",
     "UNYID:US-ACME-HQ",
     1, // Company
     validUntil,
     metadataHash
   );
   ```

4. **Anchor VC to Identity**
   ```javascript
   await identityNFT.anchorCredential(tokenId, kycHash, "SCHEMA/KYC_ORG_v1");
   ```

5. **Update Compliance Profile**
   ```javascript
   await complianceRegistry.updateProfile(
     entityAddress,
     "US", // jurisdiction
     true  // accredited
   );
   ```

### Workflow 2: MRV → REC Issuance

**Steps**:

1. **Register Facility**
   ```javascript
   const facilityTokenId = await identityNFT.mint(
     ownerAddress,
     "did:unykorn:ACME-PLANT01",
     "UNYID:US-ACME-PLANT01",
     2, // Facility
     0, // no expiry
     facilityMetadataHash
   );
   ```

2. **Issue Facility VC**
   ```javascript
   const facilityHash = keccak256(facilityDataJSON);
   await attestationRegistry.record(
     ownerAddress,
     "SCHEMA/FACILITY_v1",
     facilityHash,
     validUntil,
     permitHash
   );
   ```

3. **Register Device**
   ```javascript
   await deviceOracle.registerDevice(
     ownerAddress,
     "did:unykorn:ACME-PLANT01:INV12",
     "did:unykorn:ACME-PLANT01",
     deviceCredentialHash,
     devicePublicKey,
     "inverter",
     "SolarEdge",
     "SE27.6K",
     firmwareHash
   );
   ```

4. **Post Meter Readings** (automated, every hour)
   ```javascript
   const reading = {
     deviceDid: "did:unykorn:ACME-PLANT01:INV12",
     timestamp: Date.now(),
     value: 1287400, // 1287.4 kWh in watt-hours
     valueType: 0, // kWh
     dataHash: keccak256(fullDataJSON),
     signature: deviceSignature,
     nonce: currentNonce + 1
   };
   await deviceOracle.postReading(reading);
   ```

5. **Create REC Certificate Type**
   ```javascript
   const tokenId = await erc1155rec.createCertificate(
     "REC US-ERCOT 2025-10",
     "ERCOT",
     "PV",
     "did:unykorn:ACME-PLANT01",
     202510, // Oct 2025
     1, // 1 MWh per token
     "ERCOT-2025-10-",
     complianceClass,
     metadataUri
   );
   ```

6. **Issue RECs** (when 1 MWh threshold met)
   ```javascript
   const serials = await erc1155rec.issue(
     holderAddress,
     tokenId,
     10 // 10 RECs = 10 MWh
   );
   // Returns: ["ERCOT-2025-10-000001", "ERCOT-2025-10-000002", ...]
   ```

### Workflow 3: Compliant Transfer

**Steps**:

1. **Buyer Presents UNY-ID**
   - Buyer has IdentityNFT with required VCs (KYC, sanctions, accreditation)

2. **Pre-Transfer Check**
   ```javascript
   const (allowed, reason) = await complianceRegistry.preTransferCheck(
     tokenClass,
     sellerAddress,
     buyerAddress,
     recContractAddress,
     tokenId
   );
   if (!allowed) revert(reason);
   ```

3. **Transfer**
   ```javascript
   await erc1155rec.safeTransferFrom(
     sellerAddress,
     buyerAddress,
     tokenId,
     amount,
     data
   );
   // Compliance check happens in _beforeTokenTransfer hook
   ```

### Workflow 4: Retirement

**Steps**:

1. **Retire on-chain**
   ```javascript
   const retirementId = await retirementLocker.retire(
     recContractAddress,
     tokenId,
     amount,
     beneficiaryAddress,
     serialNumbers, // ["ERCOT-2025-10-000001", ...]
     evidenceHash,  // IPFS hash of retirement cert
     "I-REC",       // external registry
     "Voluntary offset"
   );
   ```

2. **Bridge to Registry** (off-chain → on-chain callback)
   ```javascript
   // Oracle posts registry confirmation
   await retirementLocker.bridgeRetirement(
     retirementId,
     "I-REC-RET-2025-123456"
   );
   ```

3. **Issue Retirement VC**
   ```javascript
   const attestationId = await retirementLocker.issueRetirementAttestation(retirementId);
   ```

4. **Verify Anti-Double-Count**
   ```javascript
   const isRetired = await retirementLocker.isSerialRetired("I-REC", "ERCOT-2025-10-000001");
   // Returns: true
   ```

---

## Integration Guide

### For Energy Facilities

**Prerequisites**:
- Smart meter or SCADA system with ECDSA signing capability
- API integration to DeviceOracle

**Steps**:
1. Generate device keypair (secp256k1)
2. Register device with DeviceOracle
3. Sign meter readings with device private key
4. POST readings to oracle gateway (hourly/daily)
5. Automatic REC issuance when thresholds met

**Example Code** (Node.js):

```javascript
const ethers = require('ethers');

// Device private key (KEEP SECRET!)
const devicePK = process.env.DEVICE_PRIVATE_KEY;
const signer = new ethers.Wallet(devicePK);

// Meter reading data
const reading = {
  deviceDid: "did:unykorn:PLANT01:MTR01",
  timestamp: Math.floor(Date.now() / 1000),
  value: 1287400, // watt-hours
  valueType: 0,   // kWh
  dataHash: ethers.keccak256(ethers.toUtf8Bytes(JSON.stringify(fullData))),
  nonce: await getNextNonce(reading.deviceDid)
};

// Sign reading
const messageHash = ethers.solidityPackedKeccak256(
  ["string", "uint256", "uint256", "uint8", "bytes32", "uint256"],
  [reading.deviceDid, reading.timestamp, reading.value, reading.valueType, reading.dataHash, reading.nonce]
);
reading.signature = await signer.signMessage(ethers.getBytes(messageHash));

// POST to oracle
await oracleContract.postReading(reading);
```

### For Compliance Officers

**Prerequisites**:
- KYC/AML provider integration (Chainalysis, etc.)
- COMPLIANCE_OFFICER_ROLE on ComplianceRegistry

**Steps**:
1. Receive KYC documents from entity
2. Run background checks
3. Issue KYC VC via AttestationRegistry
4. Update ComplianceRegistry profile (jurisdiction, accreditation)
5. Add to whitelist if needed

**Example Code**:

```javascript
// Issue KYC VC
const kycHash = ethers.keccak256(ethers.toUtf8Bytes(JSON.stringify(kycData)));
const attestationId = await attestationRegistry.record(
  entityAddress,
  "SCHEMA/KYC_ORG_v1",
  kycHash,
  Math.floor(Date.now() / 1000) + 365 * 24 * 3600, // 1 year
  evidenceHash
);

// Update profile
await complianceRegistry.updateProfile(
  entityAddress,
  "US",  // ISO country code
  true   // accredited investor
);

// Update sanctions status
await complianceRegistry.updateSanctionsStatus(entityAddress, false);
```

### For Token Issuers

**Prerequisites**:
- ISSUER_ROLE on ERC1155REC or ERC1400Adapter
- Facility VCs and device credentials in place

**Steps**:
1. Create certificate type (vintage/region/tech)
2. Set compliance class requirements
3. Monitor DeviceOracle for energy data
4. Issue tokens when policy conditions met
5. Assign serials automatically

**Example Code**:

```javascript
// Create REC type
const complianceClass = ethers.keccak256(ethers.toUtf8Bytes("REC-ERCOT-PV"));
const tokenId = await erc1155rec.createCertificate(
  "REC US-ERCOT 2025-10 (PV)",
  "ERCOT",
  "PV",
  "did:unykorn:PLANT01",
  202510,
  1, // 1 MWh per token
  "ERCOT-2025-10-",
  complianceClass,
  "ipfs://Qm..."
);

// Set compliance rules
await complianceRegistry.setRules(
  complianceClass,
  ["SCHEMA/KYC_ORG_v1", "SCHEMA/SANCTIONS_SCREEN_v1"],
  90,    // freshness: 90 days
  false, // no accreditation required
  true,  // sanctions check required
  [],    // allowed jurisdictions (empty = all)
  ["CU", "IR", "KP", "SY"], // blocked jurisdictions
  0      // no min holding period
);

// Issue RECs (to compliant holder)
const serials = await erc1155rec.issue(holderAddress, tokenId, 100);
console.log("Issued 100 RECs with serials:", serials);
```

---

## Standards & Compliance

### Standards Implemented

| Standard | Purpose | Compliance |
|----------|---------|------------|
| **W3C DID** | Decentralized identifiers | ✅ did:unykorn method |
| **W3C VC** | Verifiable credentials | ✅ JSON-LD format |
| **ERC-721** | Non-fungible tokens | ✅ IdentityNFT |
| **ERC-1155** | Multi-token standard | ✅ ERC1155REC |
| **ERC-1400** | Security token | ✅ ERC1400Adapter |
| **ERC-6551** | Token-bound accounts | ✅ TBA support |
| **EIP-712** | Typed structured data | ✅ Device signatures |
| **I-REC** | Energy certificates | ✅ Serial format |
| **GHG Protocol** | Emissions accounting | ✅ Scope 1/2/3 mapping |
| **ISSB/SASB** | ESG disclosure | ✅ ESG_DISCLOSURE schema |

### Regulatory Frameworks

#### 1. **Securities (ERC1400Adapter)**

- **Reg D (US)** - Private placement exemption
  - Partition: `RegD-US`
  - Required VCs: KYC, Accredited Investor
  - Transfer restrictions: Lock-up periods, qualified purchasers

- **Reg S (Non-US)** - Offshore offering exemption
  - Partition: `RegS-EU`, `RegS-ASIA`
  - Required VCs: KYC, jurisdiction check
  - Transfer restrictions: No US persons

- **MiCA (EU)** - Markets in Crypto-Assets Regulation
  - Compliance class: `MiCA-EU`
  - Required VCs: KYC, FATF travel rule metadata
  - Restrictions: Stablecoin reserve proof, prospectus hash

#### 2. **Carbon Markets**

- **Verra (VCS)** - Voluntary Carbon Standard
  - Registry bridge: `Verra`
  - Serial format: `VCS-<project>-<vintage>-<serial>`
  - Anti-double-count: Nonce-based serial retirement

- **Gold Standard**
  - Registry bridge: `GoldStandard`
  - Serial format: `GS-<project>-<vintage>-<serial>`

- **ACR (American Carbon Registry)**
  - Registry bridge: `ACR`
  - Serial format: `ACR-<project>-<vintage>-<serial>`

#### 3. **Energy Certificates**

- **I-REC (International REC Standard)**
  - Device credential: Smart meter attestation
  - MRV: Hourly generation data
  - Serial format: `IREC-<country>-<facility>-<YYYYMM>-<serial>`

- **Guarantees of Origin (EU)**
  - Compliance with EECS (European Energy Certificate System)
  - Serial format: `GO-<country>-<facility>-<YYYYMM>-<serial>`

- **US RECs (Regional)**
  - ERCOT, PJM, MISO, CAISO, etc.
  - State-specific requirements (Massachusetts RPS, California RPS, etc.)
  - Serial format: `<region>-<YYYYMM>-<serial>`

---

## Deployment

### Prerequisites

```bash
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts
```

### Environment Setup

```bash
cp .env.example .env
# Edit .env:
# POLYGON_RPC=https://polygon-rpc.com
# DEPLOYER_PK=0xYOUR_PRIVATE_KEY
# POLYGONSCAN_API_KEY=YOUR_API_KEY
```

### Deploy to Polygon Mainnet

```bash
npx hardhat run scripts/deploy-uny-id.js --network polygon
```

**Output**:
```
🚀 UNY-ID SYSTEM DEPLOYMENT
═══════════════════════════════════════════════════

📝 Deploying from account: 0x...
💰 Account balance: 1.5 MATIC

⏳ Starting deployment...

1️⃣  Deploying AttestationRegistry...
   ✅ AttestationRegistry deployed at: 0x1234...

2️⃣  Deploying ComplianceRegistry...
   ✅ ComplianceRegistry deployed at: 0x5678...

...

🎉 UNY-ID SYSTEM DEPLOYMENT COMPLETE!
═══════════════════════════════════════════════════

💾 Deployment record saved to: uny-id-polygon-20251024.json

📋 CANONICAL ADDRESSES (UNY-ID System):

AttestationRegistry:  0x1234...
ComplianceRegistry:   0x5678...
IdentityNFT:          0xabcd...
DeviceOracle:         0xef01...
ERC1155REC:           0x2345...
ERC1400Adapter:       0x6789...
RetirementLocker:     0x0abc...

✅ Deployment successful!
⏱️  Total deployment time: 45.2s
```

### Verify Contracts

```bash
npx hardhat verify --network polygon 0x1234... # AttestationRegistry
npx hardhat verify --network polygon 0x5678... "0x1234..." # ComplianceRegistry
# ... etc
```

---

## API Reference

### Quick Reference

**Identities**:
```solidity
identityNFT.mint(to, did, shortId, entityType, expiresAt, metadataHash)
identityNFT.isValid(tokenId) → bool
```

**Credentials**:
```solidity
attestationRegistry.record(subject, schemaId, dataHash, validUntil, evidenceHash)
attestationRegistry.isValid(subject, schemaId) → bool
```

**Compliance**:
```solidity
complianceRegistry.setRules(tokenClass, requiredSchemas, freshnessDays, ...)
complianceRegistry.preTransferCheck(tokenClass, from, to, token, tokenId) → (bool, string)
```

**MRV**:
```solidity
deviceOracle.registerDevice(owner, deviceDid, facilityDid, ...)
deviceOracle.postReading(reading)
```

**RECs**:
```solidity
erc1155rec.createCertificate(name, region, technology, vintage, ...)
erc1155rec.issue(to, tokenId, amount) → string[] serials
erc1155rec.retire(tokenId, amount, evidenceHash, serials)
```

**Retirement**:
```solidity
retirementLocker.retire(token, tokenId, amount, beneficiary, serials, evidenceHash, registry, reason)
retirementLocker.bridgeRetirement(retirementId, registryRef)
```

---

## Support & Resources

- **Documentation**: https://docs.unykorn.org
- **GitHub**: https://github.com/unykorn/uny-id
- **Discord**: https://discord.gg/unykorn
- **Audits**: Coming Q1 2026

---

**Built for the future of energy markets. Deploy tonight. Scale forever.** 🚀
