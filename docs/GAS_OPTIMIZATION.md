# Gas Optimization Guide for Unykorn L1

While Unykorn L1 has significantly lower gas costs than Ethereum (~90% cheaper), optimizing your smart contracts is still important for best practices and scalability.

---

## 🎯 Why Optimize Gas?

**On Unykorn L1**:
- Gas costs are low (1 Gwei minimum)
- But optimization improves scalability
- Enables more complex operations
- Sets good development practices

**Comparison**:
- **Unykorn L1**: Token transfer = $0.0001
- **Ethereum**: Token transfer = $5-50
- **Savings**: 99.99%+

Despite low costs, following these guidelines ensures your contracts are production-ready.

---

## 💡 Quick Wins

### 1. Use `calldata` Instead of `memory` for Read-Only Function Arguments

**Gas Saved**: ~100 gas per parameter

```solidity
// ❌ BAD: Using memory (expensive)
function processData(uint256[] memory data) external {
    uint256 sum = 0;
    for (uint256 i = 0; i < data.length; i++) {
        sum += data[i];
    }
}

// ✅ GOOD: Using calldata (cheaper)
function processData(uint256[] calldata data) external {
    uint256 sum = 0;
    for (uint256 i = 0; i < data.length; i++) {
        sum += data[i];
    }
}
```

---

### 2. Cache Storage Variables in Memory

**Gas Saved**: ~100 gas per additional read

```solidity
// ❌ BAD: Reading from storage multiple times
function calculateTotal() external view returns (uint256) {
    return balance * rate / 100; // Each variable read = ~100 gas
}

// ✅ GOOD: Cache in memory
function calculateTotal() external view returns (uint256) {
    uint256 _balance = balance;  // Read once
    uint256 _rate = rate;         // Read once
    return _balance * _rate / 100;
}
```

---

### 3. Use `immutable` and `constant` for Fixed Values

**Gas Saved**: ~2000 gas per storage read

```solidity
// ❌ BAD: Storage variable
contract Token {
    address public owner; // SLOAD = 2100 gas
    
    function isOwner() external view returns (bool) {
        return msg.sender == owner; // Expensive SLOAD
    }
}

// ✅ GOOD: Immutable variable
contract Token {
    address public immutable owner; // Directly embedded in bytecode
    
    constructor() {
        owner = msg.sender;
    }
    
    function isOwner() external view returns (bool) {
        return msg.sender == owner; // Cheap memory access
    }
}

// ✅ BEST: Constant for compile-time values
contract Config {
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
}
```

---

### 4. Pack Storage Variables

**Gas Saved**: ~20000 gas per storage slot

```solidity
// ❌ BAD: Wastes 3 storage slots
contract Inefficient {
    uint128 a;      // Slot 0
    uint256 b;      // Slot 1 (wastes 128 bits)
    uint128 c;      // Slot 2 (wastes 128 bits)
}

// ✅ GOOD: Packs into 2 storage slots
contract Efficient {
    uint128 a;      // Slot 0 (first 128 bits)
    uint128 c;      // Slot 0 (last 128 bits)
    uint256 b;      // Slot 1
}
```

**Storage Packing Guide**:
- `bool` = 1 byte
- `uint8` = 1 byte
- `uint16` = 2 bytes
- `uint32` = 4 bytes
- `uint64` = 8 bytes
- `uint128` = 16 bytes
- `uint256` / `address` = 32 bytes (full slot)

---

### 5. Use Custom Errors Instead of `require` Strings

**Gas Saved**: ~50 gas per error

```solidity
// ❌ BAD: String errors are expensive
function withdraw(uint256 amount) external {
    require(balance[msg.sender] >= amount, "Insufficient balance");
    balance[msg.sender] -= amount;
}

// ✅ GOOD: Custom errors (cheaper)
error InsufficientBalance(uint256 requested, uint256 available);

function withdraw(uint256 amount) external {
    if (balance[msg.sender] < amount) {
        revert InsufficientBalance(amount, balance[msg.sender]);
    }
    balance[msg.sender] -= amount;
}
```

---

### 6. Use `++i` Instead of `i++` in Loops

**Gas Saved**: ~5 gas per iteration

```solidity
// ❌ BAD: Post-increment
for (uint256 i = 0; i < 10; i++) {
    // ...
}

// ✅ GOOD: Pre-increment
for (uint256 i = 0; i < 10; ++i) {
    // ...
}

// ✅ BETTER: Unchecked pre-increment (if overflow impossible)
for (uint256 i = 0; i < 10;) {
    // ...
    unchecked { ++i; }
}
```

---

### 7. Use `external` Instead of `public` for Functions

**Gas Saved**: ~200 gas when called externally

```solidity
// ❌ BAD: Public function (more expensive)
function getData() public view returns (uint256[] memory) {
    return data;
}

// ✅ GOOD: External function (cheaper for external calls)
function getData() external view returns (uint256[] memory) {
    return data;
}
```

**Rule**: Use `external` unless the function is called internally.

---

### 8. Use `unchecked` for Safe Math Operations

**Gas Saved**: ~20-50 gas per operation

```solidity
// ❌ BAD: Unnecessary overflow check
function incrementCounter() external {
    counter++; // Solidity 0.8+ adds overflow check
}

// ✅ GOOD: Skip check when overflow is impossible
function incrementCounter() external {
    unchecked {
        counter++; // Save gas if counter can't overflow
    }
}

// Example: Loop that can't overflow
function sum(uint256[] calldata values) external pure returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < values.length;) {
        total += values[i];
        unchecked { ++i; } // i < values.length, so can't overflow
    }
    return total;
}
```

---

### 9. Avoid Unnecessary Storage Writes

**Gas Saved**: ~20000 gas per avoided SSTORE

```solidity
// ❌ BAD: Writes even if value unchanged
function updateBalance(uint256 newBalance) external {
    balance[msg.sender] = newBalance; // SSTORE always executed
}

// ✅ GOOD: Only write if changed
function updateBalance(uint256 newBalance) external {
    if (balance[msg.sender] != newBalance) {
        balance[msg.sender] = newBalance;
    }
}
```

---

### 10. Use Mappings Instead of Arrays When Possible

**Gas Saved**: Thousands of gas for large datasets

```solidity
// ❌ BAD: Array iteration (expensive for large datasets)
contract UserRegistry {
    address[] public users;
    
    function isUser(address user) external view returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == user) return true;
        }
        return false;
    }
}

// ✅ GOOD: Mapping lookup (O(1) complexity)
contract UserRegistry {
    mapping(address => bool) public isUser;
    
    function addUser(address user) external {
        isUser[user] = true;
    }
}
```

---

## 🔧 Advanced Optimization Techniques

### 1. Bit Manipulation

Store multiple booleans in a single `uint256`:

```solidity
contract BitPacking {
    uint256 private flags;
    
    function setFlag(uint8 index, bool value) external {
        if (value) {
            flags |= (1 << index);  // Set bit
        } else {
            flags &= ~(1 << index); // Clear bit
        }
    }
    
    function getFlag(uint8 index) external view returns (bool) {
        return (flags & (1 << index)) != 0;
    }
}
```

**Benefit**: Store 256 booleans in 1 storage slot instead of 256 slots.

---

### 2. Assembly Optimization

For critical performance sections:

```solidity
// Standard Solidity
function getCodeSize(address addr) public view returns (uint256 size) {
    assembly {
        size := extcodesize(addr)
    }
}

// More complex: efficient memory copy
function memcpy(uint256 dest, uint256 src, uint256 len) internal pure {
    assembly {
        // Copy word-by-word (32 bytes at a time)
        for { let i := 0 } lt(i, len) { i := add(i, 32) } {
            mstore(add(dest, i), mload(add(src, i)))
        }
    }
}
```

**Warning**: Use assembly sparingly; it's error-prone and bypasses safety checks.

---

### 3. Function Dispatch Optimization

Order functions by call frequency:

```solidity
// Solidity compiles functions in order
// Put frequently called functions first
contract Optimized {
    function frequentlyCalledFunction() external { /* ... */ }
    function lessFrequentFunction() external { /* ... */ }
    function rarelyCalledFunction() external { /* ... */ }
}
```

---

### 4. Short-Circuiting

Use && and || for early exits:

```solidity
// ❌ BAD: Always checks both conditions
function isValid() external view returns (bool) {
    return checkCondition1() && checkCondition2(); 
    // Even if condition1 is false, condition2 is evaluated
}

// ✅ GOOD: Short-circuits
function isValid() external view returns (bool) {
    if (!checkCondition1()) return false; // Early exit
    return checkCondition2();
}
```

---

## 📊 Gas Benchmarking

### Testing Gas Costs

```javascript
// In Hardhat test file
const { expect } = require("chai");

describe("Gas Optimization Tests", function() {
    it("should measure gas usage", async function() {
        const [owner] = await ethers.getSigners();
        const Token = await ethers.getContractFactory("Token");
        const token = await Token.deploy();
        
        // Measure gas for function call
        const tx = await token.transfer(owner.address, 100);
        const receipt = await tx.wait();
        
        console.log("Gas used:", receipt.gasUsed.toString());
        expect(receipt.gasUsed).to.be.lt(50000); // Assert max gas
    });
});
```

### Gas Reporter

Enable in `hardhat.config.js`:

```javascript
module.exports = {
    gasReporter: {
        enabled: process.env.REPORT_GAS === "true",
        currency: "USD",
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
        outputFile: "gas-report.txt",
        noColors: true
    }
};
```

Run with:
```bash
REPORT_GAS=true npx hardhat test
```

---

## 🎯 Gas Optimization Checklist

Before deploying to mainnet:

### Storage Optimization
- [ ] Use `immutable` for deploy-time constants
- [ ] Use `constant` for compile-time constants
- [ ] Pack storage variables (uint128 + uint128 = 1 slot)
- [ ] Use mappings instead of arrays for lookups
- [ ] Avoid storing redundant data

### Function Optimization
- [ ] Use `external` instead of `public` when possible
- [ ] Use `calldata` for read-only array parameters
- [ ] Cache storage variables in memory
- [ ] Use custom errors instead of strings
- [ ] Avoid unnecessary storage writes

### Loop Optimization
- [ ] Use `++i` instead of `i++`
- [ ] Use `unchecked` for safe increments
- [ ] Cache array length outside loop
- [ ] Avoid unbounded loops (use pagination)

### Advanced Optimization
- [ ] Consider bit packing for multiple flags
- [ ] Use assembly for critical sections (carefully!)
- [ ] Profile gas usage with gas reporter
- [ ] Compare before/after optimization

---

## 📈 Optimization Impact on Unykorn L1

### Cost Comparison (Unykorn L1)

| Operation | Unoptimized | Optimized | Savings |
|-----------|-------------|-----------|---------|
| **Token Transfer** | 52,000 gas | 28,000 gas | 46% |
| **Contract Deploy** | 2,000,000 gas | 1,200,000 gas | 40% |
| **NFT Mint** | 150,000 gas | 90,000 gas | 40% |
| **Complex Swap** | 300,000 gas | 180,000 gas | 40% |

**Real Costs** (1 Gwei gas price):
- Unoptimized transfer: $0.000052
- Optimized transfer: $0.000028
- **You save**: $0.000024 per transaction

**At Scale** (1M transactions/year):
- Unoptimized: $52
- Optimized: $28
- **Annual savings**: $24

**Note**: While absolute savings are small on Unykorn L1, optimization demonstrates engineering excellence and prepares for multi-chain deployment.

---

## 🔗 Tools & Resources

### Gas Analysis Tools

1. **Hardhat Gas Reporter**
   ```bash
   npm install hardhat-gas-reporter --save-dev
   ```

2. **Solidity Visual Developer** (VS Code extension)
   - Visual gas estimates
   - Storage layout diagrams

3. **Foundry Gas Snapshots**
   ```bash
   forge snapshot
   forge snapshot --diff
   ```

4. **Tenderly** (Online debugger)
   - Step-by-step gas breakdown
   - Visual trace

### Learning Resources

- [Solidity Gas Optimization Tips](https://mudit.blog/solidity-gas-optimization-tips/)
- [EVM Opcodes Gas Costs](https://github.com/crytic/evm-opcodes)
- [Yul Documentation](https://docs.soliditylang.org/en/latest/yul.html)

---

## 📞 Get Help

- **GitHub Discussions**: Ask optimization questions
- **Discord**: #optimization channel
- **Docs**: [docs.unykorn.com](https://docs.unykorn.com)

---

**Remember**: "Premature optimization is the root of all evil." Optimize after you have working, secure code. 🚀
