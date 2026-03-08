# ChainGuard Smart Contracts

**On-chain registry and Chainlink CRE consumer for ChainGuard Sentinel.**

This repository contains the Solidity contracts that connect the ChainGuard frontend to the Chainlink Runtime Environment (CRE): users (or the app’s cron) request risk analysis by calling a consumer contract; CRE runs the workflow and delivers the report back on-chain. No custom backend is required.

---

## The problem we address

To run decentralized risk monitoring, the app must (1) **request** an analysis in a way CRE can observe, and (2) **receive** the result in a way the app can read trustlessly. A smart contract that emits an event and stores the report does both: the frontend sends one transaction, CRE reacts to the event, and the frontend reads the outcome from the same contract.

---

## How we use Chainlink (CRE)

- **ChainGuardCREConsumer** implements the request–report pattern used by Chainlink CRE:
  - **Request:** `requestRiskAnalysis(contractAddress, chainSelectorName)` – emits `RiskAnalysisRequested(requestId, contractAddress, chainSelectorName, requester)`. The CRE workflow (EVM log trigger) listens for this event.
  - **Report:** `onReport(metadata, report)` – called by the Chainlink Keystone forwarder when the CRE workflow submits the risk assessment. The contract stores the result and emits `RiskAssessmentReceived`.
  - **Read:** `getAssessment(requestId)` – returns the stored assessment (contractAddress, chainSelectorName, riskLevel, riskScore, summary, filled). The frontend polls this until `filled` is true.

- **ChainGuardRegistry** (if used) holds the list of monitored contracts and alerts; the app can sync with it for a single source of truth on-chain.

Together with the [chain-guard-cre](https://github.com/Sobilo34/chain-guard-cre) workflow, this satisfies the hackathon requirement: **build/simulate/deploy a CRE workflow** that integrates blockchain with external systems (e.g. Chainlink Data Feeds, LLM/AI), with the workflow triggered and its result stored on-chain.

---

## Link to all files that use Chainlink

| File                                                           | Purpose                                                                                                                     |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| [src/ChainGuardCREConsumer.sol](src/ChainGuardCREConsumer.sol) | CRE consumer: `requestRiskAnalysis`, `onReport`, `getAssessment`, `RiskAnalysisRequested` / `RiskAssessmentReceived` events |
| [src/IReceiver.sol](src/IReceiver.sol)                         | Interface for `onReport` (Chainlink forwarder)                                                                              |
| [script/Deploy.s.sol](script/Deploy.s.sol)                     | Deploy script (Registry + Consumer, set forwarder for CRE)                                                                  |

---

## Project structure

```
chain-guard-smart-contract/
├── src/
│   ├── ChainGuardCREConsumer.sol   # CRE consumer (request + store report)
│   ├── ChainGuardRegistry.sol     # (optional) Monitored contracts + alerts
│   └── IReceiver.sol              # onReport interface
├── script/
│   └── Deploy.s.sol               # Deploy and verify
├── .env.example
├── deploy.sh
└── README.md
```

---

## Build and test

```bash
forge build
forge test
```

---

## Deploy (Sepolia)

1. Copy `.env.example` to `.env` and set:
   - `CHAINGUARD_REGISTRY_PRIVATE_KEY` – deployer private key with Sepolia ETH
   - `SEPOLIA_RPC_URL` – e.g. `https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY`
   - `ETHERSCAN_API_KEY` (optional) – for verification after deploy

2. Run:

```bash
chmod +x deploy.sh && ./deploy.sh
```

Or manually:

```bash
source .env && forge script script/Deploy.s.sol --rpc-url "$SEPOLIA_RPC_URL" --broadcast
```

3. Configure the ChainGuard app (`chain-guard/.env.local`):
   - `CHAINGUARD_REGISTRY_ADDRESS` – from deploy (if using registry)
   - `NEXT_PUBLIC_CHAINGUARD_CRE_CONSUMER_ADDRESS` – consumer address from deploy
   - `NEXT_PUBLIC_CRE_CONSUMER_CHAIN_ID=11155111`
   - `SEPOLIA_RPC_URL` (or Alchemy) and, for automation, `CRE_AUTOMATION_PRIVATE_KEY`

4. Configure the CRE workflow in [chain-guard-cre](https://github.com/Sobilo34/chain-guard-cre): set `creConsumerAddress` and `chainSelectorName` (e.g. `ethereum-testnet-sepolia`) in the EVM-triggered config so the workflow listens for `RiskAnalysisRequested` and writes reports to this consumer.

---

## Flow summary

```
Frontend (or cron) → requestRiskAnalysis(contractAddress, chainSelectorName)
    → Consumer emits RiskAnalysisRequested
        → CRE workflow (chain-guard-cre) runs: EVM reads + feeds + AI
            → CRE calls consumer.onReport(report)
                → Consumer stores assessment, emits RiskAssessmentReceived
Frontend ← getAssessment(requestId) ← Consumer
```

---

## Related repositories

- **[chain-guard](https://github.com/Sobilo34/chain-guard)** – Frontend; calls `requestRiskAnalysis`, polls `getAssessment`, runs CRE listener for local simulate.
- **[chain-guard-cre](https://github.com/Sobilo34/chain-guard-cre)** – CRE workflow (EVM trigger, Chainlink feeds, AI, report write).

---

## License

MIT.
