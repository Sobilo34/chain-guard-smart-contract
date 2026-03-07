#!/bin/bash
# Deploy ChainGuardRegistry to Sepolia
# Requires: .env with CHAINGUARD_REGISTRY_PRIVATE_KEY and SEPOLIA_RPC_URL.
# Optional: ETHERSCAN_API_KEY for automatic verification after deploy.

set -e
cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

if [ -z "$CHAINGUARD_REGISTRY_PRIVATE_KEY" ]; then
  echo "Error: CHAINGUARD_REGISTRY_PRIVATE_KEY not set. Add it to .env or export it."
  exit 1
fi

# Forge vm.envUint() requires hex prefix
if [ "${CHAINGUARD_REGISTRY_PRIVATE_KEY#0x}" = "$CHAINGUARD_REGISTRY_PRIVATE_KEY" ]; then
  export CHAINGUARD_REGISTRY_PRIVATE_KEY=0x$CHAINGUARD_REGISTRY_PRIVATE_KEY
fi

if [ -z "$SEPOLIA_RPC_URL" ]; then
  echo "Error: SEPOLIA_RPC_URL not set. Add it to .env or export it."
  exit 1
fi

SEPOLIA_CHAIN_ID=11155111
BROADCAST_DIR="broadcast/Deploy.s.sol/$SEPOLIA_CHAIN_ID"
CONTRACT_ADDRESS=""

echo "Deploying ChainGuardRegistry to Sepolia..."
forge script script/Deploy.s.sol --rpc-url "$SEPOLIA_RPC_URL" --broadcast

# Get deployed contract address from broadcast artifact
RUN_FILE="$BROADCAST_DIR/run-latest.json"
if [ ! -f "$RUN_FILE" ]; then
  RUN_FILE=$(ls -t "$BROADCAST_DIR"/run-*.json 2>/dev/null | head -1)
fi
if [ -z "$RUN_FILE" ] || [ ! -f "$RUN_FILE" ]; then
  echo "Warning: Could not find broadcast artifact at $BROADCAST_DIR. Skipping verification."
else
  if command -v jq &>/dev/null; then
    CONTRACT_ADDRESS=$(jq -r '.receipts[0].contractAddress // .transactions[0].contractAddress // empty' "$RUN_FILE")
  else
    CONTRACT_ADDRESS=$(grep -o '"contractAddress": "[^"]*"' "$RUN_FILE" | head -1 | sed 's/.*: "\(.*\)"/\1/')
  fi
  if [ -z "$CONTRACT_ADDRESS" ] || [ "$CONTRACT_ADDRESS" = "null" ]; then
    echo "Warning: Could not read contract address from $RUN_FILE. Skipping verification."
  else
    echo ""
    echo "Verifying ChainGuardRegistry at $CONTRACT_ADDRESS..."
    if [ -n "$ETHERSCAN_API_KEY" ]; then
      if forge verify-contract --chain sepolia "$CONTRACT_ADDRESS" src/ChainGuardRegistry.sol:ChainGuardRegistry --etherscan-api-key "$ETHERSCAN_API_KEY" --watch; then
        echo "Verification succeeded."
      else
        echo "Warning: Verification failed (contract may already be verified or API issue)."
      fi
    else
      echo "Skipping verification: ETHERSCAN_API_KEY not set. Add it to .env to verify on Etherscan."
    fi
  fi
fi

echo ""
echo "Done! Add the deployed address to chain-guard/.env.local:"
echo "  CHAINGUARD_REGISTRY_ADDRESS=${CONTRACT_ADDRESS:-<see deploy output above>}"
echo "  CHAINGUARD_REGISTRY_PRIVATE_KEY=0x..."
echo "  SEPOLIA_RPC_URL=$SEPOLIA_RPC_URL"
