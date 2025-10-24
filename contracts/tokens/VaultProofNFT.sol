// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title VaultProofNFT
 * @notice Soulbound NFT proving participation in Unykorn LaunchVault
 * @dev Non-transferable by default (only owner can override)
 */
contract VaultProofNFT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    uint256 private _nextTokenId;
    string private _baseTokenURI;
    
    mapping(uint256 => uint256) public mintedAt;      // tokenId => block number
    mapping(uint256 => uint256) public contributionAmount; // tokenId => MATIC contributed
    
    event Minted(address indexed to, uint256 indexed tokenId, uint256 contributionAmount);
    event BaseURIUpdated(string newBaseURI);
    
    constructor() ERC721("Unykorn VaultProof", "VPROOF") Ownable(msg.sender) {
        _nextTokenId = 1;
    }
    
    /**
     * @notice Mint a new VaultProof NFT
     * @param to Recipient address
     * @param amount MATIC contribution amount
     * @return tokenId The newly minted token ID
     */
    function mint(address to, uint256 amount) external onlyOwner returns (uint256) {
        return _mintVaultProof(to, amount);
    }
    
    /**
     * @notice Batch mint VaultProof NFTs
     * @param recipients Array of recipient addresses
     * @param amounts Array of contribution amounts
     */
    function batchMint(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _mintVaultProof(recipients[i], amounts[i]);
        }
    }
    
    /**
     * @notice Internal mint helper
     */
    function _mintVaultProof(address to, uint256 contributionAmt) private returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        mintedAt[tokenId] = block.number;
        contributionAmount[tokenId] = contributionAmt;
        emit Minted(to, tokenId, contributionAmt);
        return tokenId;
    }
    
    /**
     * @notice Set base URI for token metadata
     * @param baseURI IPFS or HTTP base URI
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }
    
    /**
     * @notice Get token URI for metadata
     * @param tokenId Token ID
     * @return Token metadata URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
            : "";
    }
    
    /**
     * @notice Get total number of NFTs minted
     * @return Total supply
     */
    function totalSupply() public view override returns (uint256) {
        return _nextTokenId - 1;
    }
    
    /**
     * @dev Soulbound: Prevent transfers except from minting or owner-initiated
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        address from = _ownerOf(tokenId);
        
        // Allow minting (from == address(0))
        if (from == address(0)) {
            return super._update(to, tokenId, auth);
        }
        
        // Allow owner to force transfer (e.g., recovery, burning)
        if (msg.sender == owner()) {
            return super._update(to, tokenId, auth);
        }
        
        // Block all other transfers (soulbound)
        revert("VaultProofNFT: Soulbound");
    }
    
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
