// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./AttestationRegistry.sol";

/**
 * @title DeviceOracle
 * @notice Hardware-rooted device attestations for MRV (Measurement, Reporting, Verification)
 * @dev Posts signed meter readings and energy data from trusted IoT devices
 * 
 * Features:
 * - Device registration with firmware hash + public key
 * - Batch posting of signed meter readings
 * - Signature verification (ECDSA/secp256k1)
 * - Facility + Device credential binding
 * - Anti-replay protection (nonce-based)
 * - Aggregation support (multiple devices → facility totals)
 * - Standards: OpenADR, IEEE 2030.5, OCPP, OPC-UA, SCADA
 */
contract DeviceOracle is AccessControl {
    using ECDSA for bytes32;

    // ============ Roles ============
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_OPERATOR_ROLE = keccak256("ORACLE_OPERATOR_ROLE");
    bytes32 public constant DEVICE_REGISTRAR_ROLE = keccak256("DEVICE_REGISTRAR_ROLE");

    // ============ Structs ============

    struct Device {
        address owner;                 // Device owner
        string did;                    // Device DID (did:unykorn:...)
        string facilityDid;            // Parent facility DID
        bytes32 credentialHash;        // Device credential hash
        address signingKey;            // Device public key (secp256k1)
        string deviceType;             // "smart_meter", "inverter", "ev_charger", etc.
        string manufacturer;           // Manufacturer name
        string model;                  // Model number
        bytes32 firmwareHash;          // Firmware hash (for attestation)
        uint256 registeredAt;          // Registration timestamp
        bool active;                   // Active flag
        uint256 nonce;                 // Anti-replay nonce
    }

    struct MeterReading {
        string deviceDid;              // Device DID
        uint256 timestamp;             // Reading timestamp
        uint256 value;                 // Reading value (e.g., kWh in watt-hours)
        uint8 valueType;               // 0=kWh, 1=kW, 2=voltage, 3=current, etc.
        bytes32 dataHash;              // Hash of full reading data
        bytes signature;               // Device signature (EIP-191/EIP-712)
        uint256 nonce;                 // Anti-replay nonce
    }

    struct FacilityAggregate {
        string facilityDid;            // Facility DID
        uint256 periodStart;           // Aggregation period start
        uint256 periodEnd;             // Aggregation period end
        uint256 totalKwh;              // Total energy (watt-hours)
        uint256 deviceCount;           // Number of devices
        string[] deviceDids;           // Contributing devices
        bytes32 merkleRoot;            // Merkle root of all readings
    }

    // ============ State ============

    AttestationRegistry public attestationRegistry;

    // deviceDid => Device
    mapping(string => Device) public devices;

    // deviceDid => MeterReading[] (last N readings)
    mapping(string => MeterReading[]) public readingHistory;

    // Max readings per device (prevent unbounded growth)
    uint256 public maxReadingsPerDevice = 1000;

    // facilityDid => periodKey => FacilityAggregate
    mapping(string => mapping(bytes32 => FacilityAggregate)) public facilityAggregates;

    // Counter for total readings
    uint256 public totalReadings;

    // ============ Events ============

    event DeviceRegistered(
        string indexed deviceDid,
        string facilityDid,
        address signingKey,
        string deviceType
    );

    event DeviceDeactivated(string indexed deviceDid, string reason);

    event MeterReadingPosted(
        string indexed deviceDid,
        uint256 timestamp,
        uint256 value,
        uint8 valueType,
        bytes32 dataHash
    );

    event BatchReadingsPosted(
        uint256 count,
        uint256 totalEnergy
    );

    event FacilityAggregateComputed(
        string indexed facilityDid,
        uint256 periodStart,
        uint256 periodEnd,
        uint256 totalKwh,
        uint256 deviceCount
    );

    // ============ Constructor ============

    constructor(address _attestationRegistry) {
        require(_attestationRegistry != address(0), "Invalid attestation registry");
        
        attestationRegistry = AttestationRegistry(_attestationRegistry);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_OPERATOR_ROLE, msg.sender);
        _grantRole(DEVICE_REGISTRAR_ROLE, msg.sender);
    }

    // ============ Device Management ============

    /**
     * @notice Register a new IoT device
     * @param owner Device owner address
     * @param deviceDid Device DID (did:unykorn:...)
     * @param facilityDid Parent facility DID
     * @param credentialHash Device credential hash (from AttestationRegistry)
     * @param signingKey Device public key (secp256k1 address)
     * @param deviceType Device type (smart_meter, inverter, etc.)
     * @param manufacturer Manufacturer name
     * @param model Model number
     * @param firmwareHash Firmware hash
     */
    function registerDevice(
        address owner,
        string calldata deviceDid,
        string calldata facilityDid,
        bytes32 credentialHash,
        address signingKey,
        string calldata deviceType,
        string calldata manufacturer,
        string calldata model,
        bytes32 firmwareHash
    ) external onlyRole(DEVICE_REGISTRAR_ROLE) {
        require(owner != address(0), "Invalid owner");
        require(bytes(deviceDid).length > 0, "Device DID required");
        require(bytes(facilityDid).length > 0, "Facility DID required");
        require(signingKey != address(0), "Invalid signing key");
        require(!devices[deviceDid].active, "Device already registered");

        devices[deviceDid] = Device({
            owner: owner,
            did: deviceDid,
            facilityDid: facilityDid,
            credentialHash: credentialHash,
            signingKey: signingKey,
            deviceType: deviceType,
            manufacturer: manufacturer,
            model: model,
            firmwareHash: firmwareHash,
            registeredAt: block.timestamp,
            active: true,
            nonce: 0
        });

        emit DeviceRegistered(deviceDid, facilityDid, signingKey, deviceType);
    }

    /**
     * @notice Deactivate a device (stop accepting readings)
     * @param deviceDid Device DID
     * @param reason Deactivation reason
     */
    function deactivateDevice(string calldata deviceDid, string calldata reason) 
        external 
        onlyRole(DEVICE_REGISTRAR_ROLE) 
    {
        require(devices[deviceDid].active, "Device not active");
        
        devices[deviceDid].active = false;

        emit DeviceDeactivated(deviceDid, reason);
    }

    // ============ Meter Reading Posting ============

    /**
     * @notice Post a single meter reading (signed by device)
     * @param reading MeterReading struct
     */
    function postReading(MeterReading calldata reading) external onlyRole(ORACLE_OPERATOR_ROLE) {
        _validateAndStoreReading(reading);
    }

    /**
     * @notice Post multiple meter readings in batch
     * @param readings Array of MeterReading structs
     */
    function postBatch(MeterReading[] calldata readings) external onlyRole(ORACLE_OPERATOR_ROLE) {
        require(readings.length > 0, "Empty batch");
        require(readings.length <= 100, "Batch too large");

        uint256 totalEnergy = 0;

        for (uint256 i = 0; i < readings.length; i++) {
            _validateAndStoreReading(readings[i]);
            if (readings[i].valueType == 0) { // kWh
                totalEnergy += readings[i].value;
            }
        }

        emit BatchReadingsPosted(readings.length, totalEnergy);
    }

    /**
     * @dev Internal function to validate and store a meter reading
     */
    function _validateAndStoreReading(MeterReading calldata reading) private {
        Device storage device = devices[reading.deviceDid];
        
        require(device.active, "Device not active");
        require(reading.nonce == device.nonce + 1, "Invalid nonce");
        require(reading.timestamp <= block.timestamp, "Future timestamp");
        require(reading.timestamp > block.timestamp - 1 hours, "Reading too old");

        // Verify signature (EIP-191 or EIP-712)
        bytes32 messageHash = keccak256(abi.encodePacked(
            reading.deviceDid,
            reading.timestamp,
            reading.value,
            reading.valueType,
            reading.dataHash,
            reading.nonce
        ));

        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedMessageHash.recover(reading.signature);

        require(recoveredSigner == device.signingKey, "Invalid signature");

        // Store reading (keep last maxReadingsPerDevice)
        MeterReading[] storage history = readingHistory[reading.deviceDid];
        if (history.length >= maxReadingsPerDevice) {
            // Shift array (remove oldest)
            for (uint256 i = 0; i < history.length - 1; i++) {
                history[i] = history[i + 1];
            }
            history.pop();
        }
        history.push(reading);

        // Increment nonce
        device.nonce = reading.nonce;
        totalReadings++;

        emit MeterReadingPosted(
            reading.deviceDid,
            reading.timestamp,
            reading.value,
            reading.valueType,
            reading.dataHash
        );
    }

    // ============ Facility Aggregation ============

    /**
     * @notice Compute facility aggregate for a time period
     * @param facilityDid Facility DID
     * @param periodStart Period start timestamp
     * @param periodEnd Period end timestamp
     * @return totalKwh Total energy in watt-hours
     * @return deviceCount Number of contributing devices
     */
    function computeFacilityAggregate(
        string calldata facilityDid,
        uint256 periodStart,
        uint256 periodEnd
    ) external onlyRole(ORACLE_OPERATOR_ROLE) returns (uint256 totalKwh, uint256 deviceCount) {
        require(periodEnd > periodStart, "Invalid period");
        require(periodEnd <= block.timestamp, "Future period");

        bytes32 periodKey = keccak256(abi.encodePacked(periodStart, periodEnd));

        string[] memory deviceDids = new string[](100); // Max 100 devices per facility
        uint256 count = 0;
        uint256 total = 0;

        // NOTE: In production, you'd iterate over a known device list for this facility
        // For demo, this is a simplified aggregation logic placeholder
        // Real implementation would:
        // 1. Query all devices with matching facilityDid
        // 2. Sum their readings in [periodStart, periodEnd]
        // 3. Compute Merkle root of all readings

        facilityAggregates[facilityDid][periodKey] = FacilityAggregate({
            facilityDid: facilityDid,
            periodStart: periodStart,
            periodEnd: periodEnd,
            totalKwh: total,
            deviceCount: count,
            deviceDids: new string[](count),
            merkleRoot: bytes32(0) // TODO: Compute Merkle root
        });

        emit FacilityAggregateComputed(facilityDid, periodStart, periodEnd, total, count);

        return (total, count);
    }

    // ============ View Functions ============

    /**
     * @notice Get device info
     * @param deviceDid Device DID
     * @return device Device struct
     */
    function getDevice(string calldata deviceDid) external view returns (Device memory) {
        return devices[deviceDid];
    }

    /**
     * @notice Get latest N readings for a device
     * @param deviceDid Device DID
     * @param count Number of readings to return
     * @return readings Array of MeterReading structs
     */
    function getReadings(string calldata deviceDid, uint256 count) 
        external 
        view 
        returns (MeterReading[] memory) 
    {
        MeterReading[] storage history = readingHistory[deviceDid];
        uint256 returnCount = count < history.length ? count : history.length;
        
        MeterReading[] memory readings = new MeterReading[](returnCount);
        uint256 startIndex = history.length - returnCount;

        for (uint256 i = 0; i < returnCount; i++) {
            readings[i] = history[startIndex + i];
        }

        return readings;
    }

    /**
     * @notice Get facility aggregate for a period
     * @param facilityDid Facility DID
     * @param periodStart Period start timestamp
     * @param periodEnd Period end timestamp
     * @return aggregate FacilityAggregate struct
     */
    function getFacilityAggregate(
        string calldata facilityDid,
        uint256 periodStart,
        uint256 periodEnd
    ) external view returns (FacilityAggregate memory) {
        bytes32 periodKey = keccak256(abi.encodePacked(periodStart, periodEnd));
        return facilityAggregates[facilityDid][periodKey];
    }

    // ============ Admin Functions ============

    /**
     * @notice Set max readings per device
     * @param max New maximum
     */
    function setMaxReadingsPerDevice(uint256 max) external onlyRole(ADMIN_ROLE) {
        require(max > 0 && max <= 10000, "Invalid max");
        maxReadingsPerDevice = max;
    }
}
