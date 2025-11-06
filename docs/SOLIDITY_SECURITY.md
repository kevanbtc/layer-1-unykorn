# Solidity Security Best Practices for Unykorn L1

This guide provides security best practices for developing smart contracts on Unykorn L1. While the network uses the same EVM as Ethereum, following these guidelines ensures your contracts are secure and production-ready.

---

## 🔒 Critical Security Patterns

### 1. Reentrancy Protection

**Problem**: External calls can call back into your contract before state updates.

**Solution**: Use OpenZeppelin's `ReentrancyGuard` or Checks-Effects-Interactions pattern.

```solidity
// ✅ GOOD: Using ReentrancyGuard
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SecureVault is ReentrancyGuard {
    mapping(address => uint256) public balances;
    
    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}

// ✅ GOOD: Checks-Effects-Interactions
function withdraw(uint256 amount) external {
    // Checks
    require(balances[msg.sender] >= amount, "Insufficient balance");
    
    // Effects (update state BEFORE external call)
    balances[msg.sender] -= amount;
    
    // Interactions
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}

// ❌ BAD: Vulnerable to reentrancy
function withdrawBad(uint256 amount) external {
    require(balances[msg.sender] >= amount);
    
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
    
    balances[msg.sender] -= amount; // Too late!
}
```

### 2. Access Control

**Problem**: Unauthorized users calling privileged functions.

**Solution**: Use OpenZeppelin's `Ownable` or `AccessControl`.

```solidity
// ✅ GOOD: Role-based access control
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SecureRegistry is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    function criticalOperation() external onlyRole(ADMIN_ROLE) {
        // Only admins can call this
    }
    
    function normalOperation() external onlyRole(OPERATOR_ROLE) {
        // Only operators can call this
    }
}

// ❌ BAD: Simple owner check (limited flexibility)
contract InsecureRegistry {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // What if you need multiple admins? Or different roles?
}
```

### 3. Integer Overflow/Underflow

**Problem**: Integer operations exceeding max/min values (pre-Solidity 0.8.0).

**Solution**: Solidity 0.8+ has built-in overflow checks. For older versions, use SafeMath.

```solidity
// ✅ GOOD: Solidity 0.8+ (automatic checks)
pragma solidity ^0.8.24;

contract SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b; // Reverts on overflow
    }
    
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b; // Reverts on underflow
    }
}

// ⚠️ For unchecked operations (gas optimization), be careful
function uncheckedAdd(uint256 a, uint256 b) public pure returns (uint256) {
    unchecked {
        return a + b; // No overflow check - use only if you're sure!
    }
}
```

### 4. External Call Safety

**Problem**: External calls to untrusted contracts can fail or behave maliciously.

**Solution**: Always check return values and use low-level calls carefully.

```solidity
// ✅ GOOD: Check return value
function transferToken(address token, address to, uint256 amount) external {
    (bool success, ) = token.call(
        abi.encodeWithSignature("transfer(address,uint256)", to, amount)
    );
    require(success, "Transfer failed");
}

// ✅ BETTER: Use interface with error handling
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

function transferTokenSafe(address token, address to, uint256 amount) external {
    require(IERC20(token).transfer(to, amount), "Transfer failed");
}

// ❌ BAD: Ignoring return value
function transferTokenBad(address token, address to, uint256 amount) external {
    token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
    // What if it failed?
}
```

### 5. Proper Use of tx.origin

**Problem**: `tx.origin` can enable phishing attacks.

**Solution**: Always use `msg.sender` for authorization.

```solidity
// ❌ BAD: Using tx.origin
contract Vulnerable {
    address public owner;
    
    function withdraw() external {
        require(tx.origin == owner, "Not owner"); // Phishing attack vector!
        payable(msg.sender).transfer(address(this).balance);
    }
}

// ✅ GOOD: Using msg.sender
contract Secure {
    address public owner;
    
    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        payable(msg.sender).transfer(address(this).balance);
    }
}
```

---

## 🛡️ Common Vulnerabilities

### 1. Front-Running

**Issue**: Transactions can be seen in mempool before inclusion.

**Mitigation**:
- Use commit-reveal schemes
- Implement batch processing
- Add slippage protection for DEX trades

```solidity
// ✅ GOOD: Slippage protection
function swap(uint256 amountIn, uint256 minAmountOut) external {
    uint256 amountOut = calculateSwap(amountIn);
    require(amountOut >= minAmountOut, "Slippage too high");
    // Proceed with swap
}
```

### 2. Gas Limit DoS

**Issue**: Unbounded loops can exceed gas limit.

**Mitigation**: Implement pagination or use pull-over-push pattern.

```solidity
// ❌ BAD: Unbounded loop
function distributeRewards() external {
    for (uint256 i = 0; i < users.length; i++) {
        users[i].transfer(rewards[i]); // Fails if users.length is large
    }
}

// ✅ GOOD: Pull-over-push pattern
mapping(address => uint256) public rewards;

function claimReward() external {
    uint256 reward = rewards[msg.sender];
    require(reward > 0, "No reward");
    rewards[msg.sender] = 0;
    payable(msg.sender).transfer(reward);
}
```

### 3. Timestamp Dependence

**Issue**: Miners can manipulate block.timestamp slightly.

**Mitigation**: Use block.number for critical logic or tolerate ~15 second variance.

```solidity
// ⚠️ CAUTION: Timestamp can be manipulated
function isExpired(uint256 deadline) public view returns (bool) {
    return block.timestamp > deadline; // Miner can manipulate by ~15 seconds
}

// ✅ BETTER: Use block.number if precision matters
function isExpiredBlocks(uint256 deadlineBlock) public view returns (bool) {
    return block.number > deadlineBlock; // More predictable (2 sec blocks on Unykorn L1)
}
```

### 4. Delegatecall Danger

**Issue**: Delegatecall executes code in caller's context.

**Mitigation**: Only use with trusted contracts, never with user input.

```solidity
// ❌ DANGEROUS: User-controlled delegatecall
function executeBad(address target) external {
    target.delegatecall(msg.data); // User can hijack contract storage!
}

// ✅ GOOD: Restricted delegatecall
address immutable trustedImplementation;

function executeGood(bytes memory data) external onlyOwner {
    trustedImplementation.delegatecall(data); // Only owner, trusted address
}
```

---

## 🔍 Testing & Auditing

### Security Testing Checklist

- [ ] **Unit Tests**: >95% code coverage
- [ ] **Integration Tests**: Test contract interactions
- [ ] **Fuzz Testing**: Use Echidna or Foundry
- [ ] **Static Analysis**: Run Slither on all contracts
- [ ] **Manual Review**: At least 2 developers review code
- [ ] **External Audit**: Hire professional auditors (Trail of Bits, Consensys)

### Testing Tools

```bash
# Static analysis with Slither
pip3 install slither-analyzer
slither contracts/

# Fuzz testing with Echidna
echidna-test contracts/MyContract.sol --contract MyContract

# Coverage report
npx hardhat coverage

# Gas optimization
REPORT_GAS=true npx hardhat test
```

---

## 📚 Security Resources

### Essential Reading

1. [Consensys Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)
2. [SWC Registry](https://swcregistry.io/) - Smart Contract Weakness Classification
3. [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
4. [Trail of Bits Security Guide](https://github.com/crytic/building-secure-contracts)

### Security Tools

- **Slither**: Static analysis tool
- **Mythril**: Security analysis framework
- **Echidna**: Property-based fuzzer
- **Manticore**: Symbolic execution tool
- **Securify**: Automated security scanner
- **MythX**: Paid comprehensive security service

### Unykorn L1 Specific

- Low gas costs enable more thorough validation logic
- 2-second block time allows faster testing cycles
- Use [SECURITY.md](../SECURITY.md) for vulnerability reporting
- Check [CI/CD pipelines](.github/workflows/) for automated security scans

---

## ✅ Pre-Deployment Checklist

Before deploying to Unykorn L1 mainnet:

### Smart Contract
- [ ] All functions have proper access control
- [ ] External calls checked for return values
- [ ] No reentrancy vulnerabilities
- [ ] Integer operations safe (0.8+ or SafeMath)
- [ ] Events emitted for important state changes
- [ ] Gas optimization completed
- [ ] NatSpec comments for all public functions

### Testing
- [ ] Unit tests pass (>95% coverage)
- [ ] Integration tests pass
- [ ] Fuzz testing completed
- [ ] Slither scan clean (no critical/high)
- [ ] Manual code review completed

### Deployment
- [ ] Verified on block explorer (if public)
- [ ] Ownership/admin transferred to multisig
- [ ] Emergency pause mechanism tested
- [ ] Upgrade path documented (if upgradeable)
- [ ] Monitoring and alerts configured

### Documentation
- [ ] README with usage instructions
- [ ] Architecture documentation
- [ ] Known limitations documented
- [ ] Emergency procedures documented

---

## 🚨 Emergency Response

If you discover a vulnerability in deployed contracts:

1. **Do NOT** publicly disclose
2. Follow [SECURITY.md](../SECURITY.md) responsible disclosure process
3. Contact security team immediately
4. If critical: Use emergency pause function
5. Prepare and test patch
6. Deploy fix and verify
7. Post-mortem analysis

---

## 📞 Security Support

- **Security Email**: [See SECURITY.md]
- **Bug Bounty**: Up to $50K for critical vulnerabilities
- **Audit Partners**: Trail of Bits, Consensys Diligence, OpenZeppelin
- **Community**: GitHub Discussions for non-critical security questions

---

**Remember**: Security is not a feature, it's a process. Stay vigilant! 🛡️
