#!/bin/bash
# Polygon-Edge bootstrap script - generates IBFT genesis + validator keys
# Run this inside polygon-edge container or with polygon-edge binary

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="${SCRIPT_DIR}/keys/edge"
GENESIS_OUTPUT="${KEYS_DIR}/genesis.json"

# Dev accounts to premine (from secrets/DEV_ONLY_accounts.json)
PREMINE_ADDR_1="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
PREMINE_ADDR_2="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
PREMINE_AMOUNT="1000000000000000000000"  # 1000 ETH in wei

echo "🔧 Polygon-Edge Bootstrap - Generating IBFT genesis and validator secrets..."

# Create keys directory
mkdir -p "${KEYS_DIR}"

# Check if polygon-edge is available
if ! command -v polygon-edge &> /dev/null; then
    echo "❌ polygon-edge binary not found. Run this inside the polygon-edge container or install locally."
    exit 1
fi

# Generate secrets for 3 validators
echo "🔑 Generating 3 validator secrets..."
for i in {1..3}; do
    VALIDATOR_DIR="${KEYS_DIR}/validator-${i}"
    
    if [ ! -d "${VALIDATOR_DIR}" ]; then
        polygon-edge secrets init --data-dir "${VALIDATOR_DIR}"
        echo "  ✓ Validator ${i} secrets generated"
    else
        echo "  ⏭  Validator ${i} secrets already exist"
    fi
done

# Extract validator addresses for genesis
VALIDATORS=""
for i in {1..3}; do
    VALIDATOR_DIR="${KEYS_DIR}/validator-${i}"
    if [ -d "${VALIDATOR_DIR}" ]; then
        ADDR=$(polygon-edge secrets output --data-dir "${VALIDATOR_DIR}" | grep "Public key (address)" | awk '{print $NF}')
        if [ -n "$VALIDATORS" ]; then
            VALIDATORS="${VALIDATORS},"
        fi
        VALIDATORS="${VALIDATORS}${ADDR}"
        echo "  Validator ${i}: ${ADDR}"
    fi
done

# Generate genesis with IBFT consensus and premine
echo "📝 Generating IBFT genesis with Chain ID 7777..."

polygon-edge genesis \
    --dir "${GENESIS_OUTPUT}" \
    --consensus ibft \
    --chain-id 7777 \
    --name "Unykorn-L1" \
    --block-gas-limit 20000000 \
    --epoch-size 100000 \
    --ibft-validators-prefix-path "${KEYS_DIR}/validator-" \
    --premine "${PREMINE_ADDR_1}:${PREMINE_AMOUNT}" \
    --premine "${PREMINE_ADDR_2}:${PREMINE_AMOUNT}" \
    --bootnode "/ip4/127.0.0.1/tcp/10001/p2p/$(polygon-edge secrets output --data-dir ${KEYS_DIR}/validator-1 | grep 'Node ID' | awk '{print $NF}')"

if [ -f "${GENESIS_OUTPUT}" ]; then
    echo "✅ Genesis created at ${GENESIS_OUTPUT}"
    echo "✅ Validator secrets in ${KEYS_DIR}/validator-*/"
else
    echo "❌ Genesis generation failed"
    exit 1
fi

# Display summary
echo ""
echo "🔐 Validator Addresses (for genesis):"
for i in {1..3}; do
    VALIDATOR_DIR="${KEYS_DIR}/validator-${i}"
    if [ -d "${VALIDATOR_DIR}" ]; then
        polygon-edge secrets output --data-dir "${VALIDATOR_DIR}" | grep "Public key (address)"
    fi
done

echo ""
echo "💰 Pre-funded Dev Accounts:"
echo "  ${PREMINE_ADDR_1} → ${PREMINE_AMOUNT} wei"
echo "  ${PREMINE_ADDR_2} → ${PREMINE_AMOUNT} wei"

echo ""
echo "🎉 Polygon-Edge bootstrap complete! Use 'make edge-up' to start the network."
