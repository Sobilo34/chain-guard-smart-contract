// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/ChainGuardRegistry.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("CHAINGUARD_REGISTRY_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ChainGuardRegistry registry = new ChainGuardRegistry();
        vm.stopBroadcast();
        console.log("ChainGuardRegistry deployed at:", address(registry));
        console.log("Set CHAINGUARD_REGISTRY_ADDRESS=", address(registry));
    }
}
