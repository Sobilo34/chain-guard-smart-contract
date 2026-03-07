// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/ChainGuardRegistry.sol";
import "../src/ChainGuardCREConsumer.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("CHAINGUARD_REGISTRY_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ChainGuardRegistry registry = new ChainGuardRegistry();
        // Chainlink KeystoneForwarder (or MockForwarder for simulation). Set CRE_FORWARDER_ADDRESS in .env.
        address forwarder = vm.envOr("CRE_FORWARDER_ADDRESS", address(0));
        if (forwarder == address(0)) {
            // Ethereum Sepolia MockForwarder for CRE simulation (see Chainlink CRE forwarder directory)
            forwarder = 0x15fC6ae953E024d975e77382eEeC56A9101f9F88;
        }
        ChainGuardCREConsumer creConsumer = new ChainGuardCREConsumer(forwarder);
        vm.stopBroadcast();
        console.log("ChainGuardRegistry deployed at:", address(registry));
        console.log("ChainGuardCREConsumer deployed at:", address(creConsumer));
        console.log("Set CHAINGUARD_REGISTRY_ADDRESS=", address(registry));
        console.log("Set CHAINGUARD_CRE_CONSUMER_ADDRESS=", address(creConsumer));
    }
}
