# ChainGuard Smart Contract

On-chain registry contract for ChainGuard Sentinel. Deployed on Sepolia, the app uses `CHAINGUARD_REGISTRY_ADDRESS` to read/write contracts and alerts.

## Build & Test

```bash
forge build
forge test
```

## Deploy

1. Copy `.env.example` to `.env` and set:
   - `CHAINGUARD_REGISTRY_PRIVATE_KEY` – deployer private key with Sepolia ETH
   - `SEPOLIA_RPC_URL` – e.g. `https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY`

2. Deploy:

```bash
chmod +x deploy.sh && ./deploy.sh
```

Or manually:
```bash
source .env && forge script script/Deploy.s.sol --rpc-url "$SEPOLIA_RPC_URL" --broadcast
```

3. Add the deployed address to the ChainGuard app `chain-guard/.env.local`:
   ```
   CHAINGUARD_REGISTRY_ADDRESS=0x...
   CHAINGUARD_REGISTRY_PRIVATE_KEY=0x...
   SEPOLIA_RPC_URL=...
   ```
