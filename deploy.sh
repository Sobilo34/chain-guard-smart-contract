#!/bin/bash
# Deploy ChainGuardRegistry to Sepolia
# Requires: .env with CHAINGUARD_REGISTRY_PRIVATE_KEY and SEPOLIA_RPC_URL

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

if [ -z "$SEPOLIA_RPC_URL" ]; then
  echo "Error: SEPOLIA_RPC_URL not set. Add it to .env or export it."
  exit 1
fi

echo "Deploying ChainGuardRegistry to Sepolia..."
forge script script/Deploy.s.sol --rpc-url "$SEPOLIA_RPC_URL" --broadcast

echo ""
echo "Done! Add the deployed address to chain-guard/.env.local:"
echo "  CHAINGUARD_REGISTRY_ADDRESS=<address from output above>"
echo "  CHAINGUARD_REGISTRY_PRIVATE_KEY=0x..."
echo "  SEPOLIA_RPC_URL=$SEPOLIA_RPC_URL"
