// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/ChainGuardRegistry.sol";

contract ChainGuardRegistryTest is Test {
    ChainGuardRegistry public registry;

    function setUp() public {
        registry = new ChainGuardRegistry();
    }

    function testAddContract() public {
        registry.addOrUpdateContract(
            address(0x1),
            "USDT",
            "ethereum-mainnet",
            "[{\"pairName\":\"USDT/USD\",\"feedAddress\":\"0x123\"}]",
            "{\"depegTolerance\":0.02}"
        );
        (address[] memory addrs, string[] memory names,,,) = registry.getContracts();
        assertEq(addrs.length, 1);
        assertEq(addrs[0], address(0x1));
        assertEq(names[0], "USDT");
    }

    function testSetAlertEmail() public {
        registry.setAlertEmail("alerts@example.com");
        assertEq(registry.alertEmail(), "alerts@example.com");
    }

    function testAddAlert() public {
        bytes32 id = keccak256("alert_1");
        registry.addAlert(id, address(0x1), 2 /* SEVERITY_HIGH */, block.timestamp);
        (bytes32[] memory ids,,,,) = registry.getAlerts(10, 0);
        assertEq(ids.length, 1);
        assertEq(ids[0], id);
    }

    function testRemoveContract() public {
        registry.addOrUpdateContract(address(0x1), "Test", "ethereum-mainnet", "", "");
        assertEq(registry.getContractCount(), 1);
        registry.removeContract(address(0x1));
        assertEq(registry.getContractCount(), 0);
    }
}
