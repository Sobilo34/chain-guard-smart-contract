// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/interfaces/IERC165.sol";

/// @title IReceiver - receives Chainlink CRE keystone reports
/// @notice Implementations must support the IReceiver interface through ERC165.
/// @dev Used by Chainlink KeystoneForwarder to deliver workflow reports onchain.
interface IReceiver is IERC165 {
    /// @notice Handles incoming keystone reports from the Chainlink Forwarder.
    /// @param metadata Report metadata (workflowId, workflowName, workflowOwner).
    /// @param report ABI-encoded workflow report payload.
    function onReport(bytes calldata metadata, bytes calldata report) external;
}
