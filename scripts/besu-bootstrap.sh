#!/bin/bash
# Besu bootstrap script - generates validator keys + QBFT genesis
# Run this inside the Besu operator container or locally with Besu binaries

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="${SCRIPT_DIR}/keys/besu"
CONFIG_FILE="${SCRIPT_DIR}/../configs/ibftConfigFile.json"
GENESIS_OUTPUT="${KEYS_DIR}/genesis.json"

echo "🔧 Besu Bootstrap - Generating QBFT genesis and validator keys..."

# Create keys directory
mkdir -p "${KEYS_DIR}"

# Check if besu operator is available
if ! command -v besu &> /dev/null; then
    echo "❌ Besu binary not found. Run this inside the besu/besu Docker image or install Besu locally."
    exit 1
fi

# Generate validator keys (4 validators)
echo "🔑 Generating 4 validator key pairs..."
for i in {0..3}; do
    VALIDATOR_DIR="${KEYS_DIR}/validator-${i}"
    mkdir -p "${VALIDATOR_DIR}"
    
    if [ ! -f "${VALIDATOR_DIR}/key" ]; then
        besu --data-path="${VALIDATOR_DIR}" public-key export --to="${VALIDATOR_DIR}/key.pub" 2>/dev/null || true
        echo "  ✓ Validator ${i} keys generated"
    else
        echo "  ⏭  Validator ${i} keys already exist"
    fi
done

# Generate genesis using operator subcommands
echo "📝 Generating QBFT genesis from ${CONFIG_FILE}..."

if [ -f "${CONFIG_FILE}" ]; then
    besu operator generate-blockchain-config \
        --config-file="${CONFIG_FILE}" \
        --to="${KEYS_DIR}" \
        --private-key-file-name=key
    
    echo "✅ Genesis created at ${GENESIS_OUTPUT}"
    echo "✅ Validator keys in ${KEYS_DIR}/validator-*/"
else
    echo "❌ Config file not found: ${CONFIG_FILE}"
    exit 1
fi

# Display validator addresses
echo ""
echo "🔐 Validator Public Keys:"
for i in {0..3}; do
    if [ -f "${KEYS_DIR}/validator-${i}/key.pub" ]; then
        echo "  Validator ${i}: $(cat ${KEYS_DIR}/validator-${i}/key.pub)"
    fi
done

echo ""
echo "🎉 Besu bootstrap complete! Use 'make besu-up' to start the network."
