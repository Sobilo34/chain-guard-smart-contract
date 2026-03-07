# ChainGuard Smart Contract

On-chain registry and **Chainlink CRE consumer** for ChainGuard Sentinel.

- **ChainGuardRegistry**: Monitored contracts and alerts (owner writes).
- **ChainGuardCREConsumer**: Receives risk assessments from Chainlink CRE. User calls `requestRiskAnalysis(contractAddress, chainSelectorName)` → contract emits `RiskAnalysisRequested` → CRE workflow (EVM log trigger) runs → CRE writes result via `onReport()`. No backend: frontend → contract → CRE (onchain).

Deployed on Sepolia; the app uses `CHAINGUARD_REGISTRY_ADDRESS` and `NEXT_PUBLIC_CHAINGUARD_CRE_CONSUMER_ADDRESS`.

## Build & Test

```bash
forge build
forge test
```

## Deploy

1. Copy `.env.example` to `.env` and set:
   - `CHAINGUARD_REGISTRY_PRIVATE_KEY` – deployer private key with Sepolia ETH
   - `SEPOLIA_RPC_URL` – e.g. `https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY`
   - `ETHERSCAN_API_KEY` (optional) – for automatic verification on Etherscan after deploy

2. Deploy (and verify, if `ETHERSCAN_API_KEY` is set):

```bash
chmod +x deploy.sh && ./deploy.sh
```

Or manually:
```bash
source .env && forge script script/Deploy.s.sol --rpc-url "$SEPOLIA_RPC_URL" --broadcast
```

3. Add the deployed addresses to the ChainGuard app `chain-guard/.env.local`:
   ```
   CHAINGUARD_REGISTRY_ADDRESS=0x...
   CHAINGUARD_REGISTRY_PRIVATE_KEY=0x...
   NEXT_PUBLIC_CHAINGUARD_CRE_CONSUMER_ADDRESS=0x...   # from deploy log
   NEXT_PUBLIC_CRE_CONSUMER_CHAIN_ID=11155111
   SEPOLIA_RPC_URL=...
   ```

4. **CRE workflow**: Deploy the EVM-triggered workflow in `chain-guard-cre/chainguard-sentinel` with `config.evm-triggered.json` setting `creConsumerAddress` to the deployed ChainGuardCREConsumer address and `chainSelectorName` to `ethereum-testnet-sepolia`. The workflow listens for `RiskAnalysisRequested` and writes reports onchain.
