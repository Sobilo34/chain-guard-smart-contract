// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IReceiver.sol";
import "../lib/forge-std/src/interfaces/IERC165.sol";

/// @title ChainGuardCREConsumer
/// @notice Receives risk assessments from Chainlink CRE workflow and stores them onchain.
///         Users request analysis by calling requestRiskAnalysis(); CRE is triggered by the
///         RiskAnalysisRequested event, runs the workflow (EVM read + OpenRouter AI), then
///         delivers the result via KeystoneForwarder to onReport().
contract ChainGuardCREConsumer is IReceiver {
    // --- Events (EVM log trigger + frontend) ---
    /// @notice Emitted when a user requests risk analysis. CRE workflow listens for this.
    event RiskAnalysisRequested(
        bytes32 indexed requestId,
        address indexed contractAddress,
        string chainSelectorName,
        address indexed requester
    );

    /// @notice Emitted when CRE delivers an assessment. Frontend can listen for this.
    event RiskAssessmentReceived(
        bytes32 indexed requestId,
        address indexed contractAddress,
        uint8 riskLevel,
        uint256 riskScore,
        string summary
    );

    // --- State ---
    address public owner;
    address public forwarderAddress;

    uint256 private _nextRequestId;
    mapping(bytes32 => RiskAssessment) private _assessments;

    struct RiskAssessment {
        address contractAddress;
        string chainSelectorName;
        uint8 riskLevel;   // 0=LOW, 1=MEDIUM, 2=HIGH, 3=CRITICAL
        uint256 riskScore; // 0-100
        string summary;    // Short summary from CRE (e.g. first 200 chars of reasoning)
        bool filled;
    }

    error InvalidForwarder();
    error InvalidSender(address sender, address expected);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _forwarderAddress) {
        if (_forwarderAddress == address(0)) revert InvalidForwarder();
        owner = msg.sender;
        forwarderAddress = _forwarderAddress;
    }

    /// @notice Request risk analysis for a contract. Emits event that triggers CRE workflow.
    /// @param contractAddress The contract to analyze (e.g. vault, pool).
    /// @param chainSelectorName Chain identifier (e.g. "ethereum-mainnet", "arbitrum-mainnet").
    /// @return requestId Use getAssessment(requestId) or listen for RiskAssessmentReceived.
    function requestRiskAnalysis(
        address contractAddress,
        string calldata chainSelectorName
    ) external returns (bytes32 requestId) {
        require(contractAddress != address(0), "Invalid contract");
        requestId = bytes32(_nextRequestId);
        _nextRequestId += 1;
        emit RiskAnalysisRequested(requestId, contractAddress, chainSelectorName, msg.sender);
        return requestId;
    }

    /// @notice Called by Chainlink KeystoneForwarder when CRE workflow submits a report.
    function onReport(bytes calldata /* metadata */, bytes calldata report) external override {
        if (msg.sender != forwarderAddress) revert InvalidSender(msg.sender, forwarderAddress);
        (
            bytes32 requestId,
            address contractAddress,
            string memory chainSelectorName,
            uint8 riskLevel,
            uint256 riskScore,
            string memory summary
        ) = abi.decode(report, (bytes32, address, string, uint8, uint256, string));
        _assessments[requestId] = RiskAssessment({
            contractAddress: contractAddress,
            chainSelectorName: chainSelectorName,
            riskLevel: riskLevel,
            riskScore: riskScore,
            summary: summary,
            filled: true
        });
        emit RiskAssessmentReceived(requestId, contractAddress, riskLevel, riskScore, summary);
    }

    /// @notice Get stored assessment for a request. Returns filled=false until CRE delivers.
    function getAssessment(bytes32 requestId) external view returns (
        address contractAddress,
        string memory chainSelectorName,
        uint8 riskLevel,
        uint256 riskScore,
        string memory summary,
        bool filled
    ) {
        RiskAssessment storage a = _assessments[requestId];
        if (!a.filled) {
            return (address(0), "", 0, 0, "", false);
        }
        return (
            a.contractAddress,
            a.chainSelectorName,
            a.riskLevel,
            a.riskScore,
            a.summary,
            true
        );
    }

    function setForwarderAddress(address _forwarder) external onlyOwner {
        if (_forwarder == address(0)) revert InvalidForwarder();
        forwarderAddress = _forwarder;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
