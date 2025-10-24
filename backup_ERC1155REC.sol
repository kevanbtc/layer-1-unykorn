// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../compliance/ComplianceRegistry.sol";

/**
 * @title ERC1155REC
 * @notice Renewable Energy Certificates (RECs) / Energy Attribute Certificates (EACs) as ERC-1155 tokens
 * @dev Compliance-gated energy certificates with vintage tracking and registry integration
 * 
 * Features:
 * - Multi-vintage support (one tokenId per vintage/facility/technology)
 * - Serial number assignment (for registry bridge)
 * - Compliance-gated transfers (via ComplianceRegistry)
 * - Metadata: region, technology, facility, vintage, MWh amount
 * - Retirement/redemption tracking
 * - Standards: I-REC, GOs (Guarantees of Origin), US RECs (ERCOT/PJM/MISO/CAISO)
 */
contract ERC1155REC is ERC1155, AccessControl {
    using Counters for Counters.Counter;

    // ============ Roles ============
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant RETIREMENT_ROLE = keccak256("RETIREMENT_ROLE");

    // ============ Structs ============

    struct Certificate {
        string name;                   // Certificate name
        string region;                 // Grid region (ERCOT, PJM, MISO, etc.)
        string technology;             // PV, wind, hydro, biomass, etc.
        string facilityDid;            // Facility DID
        uint256 vintage;               // YYYYMM (e.g., 202510 = Oct 2025)
        uint256 mwhPerToken;           // MWh represented per token (e.g., 1 = 1 MWh)
        string serialPrefix;           // Serial prefix (e.g., "ERCOT-2025-10-")
        uint256 nextSerial;            // Next serial number
        bytes32 complianceClass;       // Token class for ComplianceRegistry
        bool active;                   // Active flag
        string metadataUri;            // IPFS/HTTP metadata URI
    }

    struct Serial {
        uint256 tokenId;               // Certificate token ID
        uint256 serialNumber;          // Sequential serial
        string serialString;           // Full serial (e.g., "ERCOT-2025-10-000001")
        address issuedTo;              // Original issuance address
        uint256 issuedAt;              // Issuance timestamp
        bool retired;                  // Retirement flag
        uint256 retiredAt;             // Retirement timestamp
        address retiredBy;             // Who retired it
        bytes32 retirementEvidence;    // IPFS hash of retirement evidence
    }

    // ============ State ============

    ComplianceRegistry public complianceRegistry;

    Counters.Counter private _tokenIdCounter;

    // tokenId => Certificate
    mapping(uint256 => Certificate) public certificates;

    // serialString => Serial
    mapping(string => Serial) public serials;

    // tokenId => totalIssued
    mapping(uint256 => uint256) public totalIssued;

    // tokenId => totalRetired
    mapping(uint256 => uint256) public totalRetired;

    // ============ Events ============

    event CertificateCreated(
        uint256 indexed tokenId,
        string name,
        string region,
        string technology,
        uint256 vintage
    );

    event CertificateIssued(
        uint256 indexed tokenId,
        address indexed to,
        uint256 amount,
        string[] serials
    );

    event CertificateRetired(
        uint256 indexed tokenId,
        address indexed by,
        uint256 amount,
        string[] serials,
        bytes32 evidenceHash
    );

    // ============ Constructor ============

    constructor(address _complianceRegistry) 
        ERC1155("https://unykorn.org/api/rec/{id}.json") 
    {
        require(_complianceRegistry != address(0), "Invalid compliance registry");
        
        complianceRegistry = ComplianceRegistry(_complianceRegistry);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
        _grantRole(RETIREMENT_ROLE, msg.sender);
    }

    // ============ Certificate Management ============

    /**
     * @notice Create a new certificate type (vintage/region/technology)
     * @param name Certificate name
     * @param region Grid region
     * @param technology Technology type
     * @param facilityDid Facility DID
     * @param vintage Vintage (YYYYMM)
     * @param mwhPerToken MWh per token
     * @param serialPrefix Serial prefix
     * @param complianceClass Token class for compliance checks
     * @param metadataUri Metadata URI
     * @return tokenId Certificate token ID
     */
    function createCertificate(
        string calldata name,
        string calldata region,
        string calldata technology,
        string calldata facilityDid,
        uint256 vintage,
        uint256 mwhPerToken,
        string calldata serialPrefix,
        bytes32 complianceClass,
        string calldata metadataUri
    ) external onlyRole(ISSUER_ROLE) returns (uint256) {
        require(bytes(name).length > 0, "Name required");
        require(bytes(region).length > 0, "Region required");
        require(vintage >= 202501 && vintage <= 209912, "Invalid vintage");
        require(mwhPerToken > 0, "Invalid MWh per token");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        certificates[tokenId] = Certificate({
            name: name,
            region: region,
            technology: technology,
            facilityDid: facilityDid,
            vintage: vintage,
            mwhPerToken: mwhPerToken,
            serialPrefix: serialPrefix,
            nextSerial: 1,
            complianceClass: complianceClass,
            active: true,
            metadataUri: metadataUri
        });

        emit CertificateCreated(tokenId, name, region, technology, vintage);

        return tokenId;
    }

    /**
     * @notice Issue (mint) certificates with serial assignment
     * @param to Recipient address
     * @param tokenId Certificate token ID
     * @param amount Number of certificates to issue
     * @return serialNumbers Array of assigned serial strings
     */
    function issue(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(ISSUER_ROLE) returns (string[] memory) {
        require(to != address(0), "Invalid recipient");
        require(certificates[tokenId].active, "Certificate not active");
        require(amount > 0 && amount <= 1000, "Invalid amount");

        // Compliance check
        require(
            complianceRegistry.isCompliant(to, certificates[tokenId].complianceClass),
            "Recipient not compliant"
        );

        Certificate storage cert = certificates[tokenId];
        string[] memory serialNumbers = new string[](amount);

        // Assign serials
        for (uint256 i = 0; i < amount; i++) {
            string memory serialString = string(abi.encodePacked(
                cert.serialPrefix,
                _padNumber(cert.nextSerial, 6)
            ));

            serials[serialString] = Serial({
                tokenId: tokenId,
                serialNumber: cert.nextSerial,
                serialString: serialString,
                issuedTo: to,
                issuedAt: block.timestamp,
                retired: false,
                retiredAt: 0,
                retiredBy: address(0),
                retirementEvidence: bytes32(0)
            });

            serialNumbers[i] = serialString;
            cert.nextSerial++;
        }

        // Mint tokens
        _mint(to, tokenId, amount, "");
        totalIssued[tokenId] += amount;

        emit CertificateIssued(tokenId, to, amount, serialNumbers);

        return serialNumbers;
    }

    // ============ Retirement (Redemption) ============

    /**
     * @notice Retire (burn) certificates with evidence anchoring
     * @param tokenId Certificate token ID
     * @param amount Number of certificates to retire
     * @param evidenceHash IPFS hash of retirement evidence
     * @param serialStrings Array of serial numbers to retire
     */
    function retire(
        uint256 tokenId,
        uint256 amount,
        bytes32 evidenceHash,
        string[] calldata serialStrings
    ) external {
        require(amount > 0, "Invalid amount");
        require(serialStrings.length == amount, "Serial count mismatch");
        require(balanceOf(msg.sender, tokenId) >= amount, "Insufficient balance");

        // Mark serials as retired
        for (uint256 i = 0; i < serialStrings.length; i++) {
            Serial storage serial = serials[serialStrings[i]];
            require(serial.tokenId == tokenId, "Serial mismatch");
            require(!serial.retired, "Serial already retired");

            serial.retired = true;
            serial.retiredAt = block.timestamp;
            serial.retiredBy = msg.sender;
            serial.retirementEvidence = evidenceHash;
        }

        // Burn tokens
        _burn(msg.sender, tokenId, amount);
        totalRetired[tokenId] += amount;

        emit CertificateRetired(tokenId, msg.sender, amount, serialStrings, evidenceHash);
    }

    // ============ Transfer Override (Compliance) ============

    /**
     * @dev Override to add compliance checks
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Skip checks for mint/burn
        if (from == address(0) || to == address(0)) {
            return;
        }

        // Compliance check for each token
        for (uint256 i = 0; i < ids.length; i++) {
            Certificate memory cert = certificates[ids[i]];
            
            (bool allowed, string memory reason) = complianceRegistry.preTransferCheck(
                cert.complianceClass,
                from,
                to,
                address(this),
                ids[i]
            );

            require(allowed, string(abi.encodePacked("Transfer blocked: ", reason)));
        }
    }

    // ============ View Functions ============

    /**
     * @notice Get certificate details
     * @param tokenId Certificate token ID
     * @return cert Certificate struct
     */
    function getCertificate(uint256 tokenId) external view returns (Certificate memory) {
        return certificates[tokenId];
    }

    /**
     * @notice Get serial details
     * @param serialString Serial number string
     * @return serial Serial struct
     */
    function getSerial(string calldata serialString) external view returns (Serial memory) {
        return serials[serialString];
    }

    /**
     * @notice Check if serial is retired
     * @param serialString Serial number string
     * @return retired Retirement flag
     */
    function isRetired(string calldata serialString) external view returns (bool) {
        return serials[serialString].retired;
    }

    /**
     * @notice Get certificate statistics
     * @param tokenId Certificate token ID
     * @return issued Total issued
     * @return retired Total retired
     * @return outstanding Total outstanding (issued - retired)
     */
    function getStats(uint256 tokenId) external view returns (
        uint256 issued,
        uint256 retired,
        uint256 outstanding
    ) {
        issued = totalIssued[tokenId];
        retired = totalRetired[tokenId];
        outstanding = issued - retired;
    }

    // ============ Metadata URI ============

    /**
     * @dev Override to return certificate-specific metadata
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        Certificate memory cert = certificates[tokenId];
        if (bytes(cert.metadataUri).length > 0) {
            return cert.metadataUri;
        }
        return super.uri(tokenId);
    }

    // ============ Helper Functions ============

    /**
     * @dev Pad number with leading zeros
     */
    function _padNumber(uint256 number, uint256 length) private pure returns (string memory) {
        bytes memory buffer = new bytes(length);
        for (uint256 i = length; i > 0; i--) {
            buffer[i - 1] = bytes1(uint8(48 + (number % 10)));
            number /= 10;
        }
        return string(buffer);
    }

    // ============ Interface Support ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
