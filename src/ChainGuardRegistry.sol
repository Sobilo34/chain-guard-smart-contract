// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChainGuardRegistry
 * @notice On-chain registry for monitored contracts, alert email, and minimal alerts.
 * Backend writes via owner; full alert payloads and extended contract data are cached off-chain.
 */
contract ChainGuardRegistry {
    event ContractAdded(address indexed contractAddress, string name, string chainSelectorName);
    event ContractRemoved(address indexed contractAddress);
    event AlertEmailSet(string email);
    event AlertAdded(bytes32 indexed alertId, address indexed contractAddress, uint8 severity, uint256 timestamp);
    event AlertStatusUpdated(bytes32 indexed alertId, uint8 status);

    uint8 public constant SEVERITY_LOW = 0;
    uint8 public constant SEVERITY_MEDIUM = 1;
    uint8 public constant SEVERITY_HIGH = 2;

    uint8 public constant STATUS_ACTIVE = 0;
    uint8 public constant STATUS_ACKNOWLEDGED = 1;
    uint8 public constant STATUS_RESOLVED = 2;

    uint256 public constant MAX_CONTRACTS = 50;
    uint256 public constant MAX_ALERTS = 100;

    struct MonitoredContract {
        address contractAddress;
        string name;
        string chainSelectorName;
        string priceFeedsJson;
        string riskThresholdsJson;
        bool exists;
    }

    struct AlertEntry {
        bytes32 id;
        address contractAddress;
        uint8 severity;
        uint256 timestamp;
        uint8 status;
        bool exists;
    }

    address public owner;
    string public alertEmail;

    MonitoredContract[] private _contracts;
    mapping(address => uint256) private _contractIndex; // 1-based; 0 = not found

    AlertEntry[] private _alerts;
    mapping(bytes32 => uint256) private _alertIndex; // 1-based

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addOrUpdateContract(
        address contractAddress,
        string calldata name,
        string calldata chainSelectorName,
        string calldata priceFeedsJson,
        string calldata riskThresholdsJson
    ) external onlyOwner {
        require(contractAddress != address(0), "Invalid address");
        uint256 idx = _contractIndex[contractAddress];
        if (idx > 0) {
            uint256 i = idx - 1;
            _contracts[i].name = name;
            _contracts[i].chainSelectorName = chainSelectorName;
            _contracts[i].priceFeedsJson = priceFeedsJson;
            _contracts[i].riskThresholdsJson = riskThresholdsJson;
        } else {
            require(_contracts.length < MAX_CONTRACTS, "Max contracts reached");
            _contracts.push(MonitoredContract({
                contractAddress: contractAddress,
                name: name,
                chainSelectorName: chainSelectorName,
                priceFeedsJson: priceFeedsJson,
                riskThresholdsJson: riskThresholdsJson,
                exists: true
            }));
            _contractIndex[contractAddress] = _contracts.length;
            emit ContractAdded(contractAddress, name, chainSelectorName);
        }
    }

    function removeContract(address contractAddress) external onlyOwner {
        uint256 idx = _contractIndex[contractAddress];
        require(idx > 0, "Contract not found");
        uint256 i = idx - 1;
        // Swap with last and pop
        uint256 last = _contracts.length - 1;
        if (i != last) {
            address lastAddr = _contracts[last].contractAddress;
            _contracts[i] = _contracts[last];
            _contractIndex[lastAddr] = i + 1;
        }
        _contracts.pop();
        delete _contractIndex[contractAddress];
        emit ContractRemoved(contractAddress);
    }

    function getContracts() external view returns (
        address[] memory addresses,
        string[] memory names,
        string[] memory chainSelectorNames,
        string[] memory priceFeedsJsons,
        string[] memory riskThresholdsJsons
    ) {
        uint256 n = _contracts.length;
        addresses = new address[](n);
        names = new string[](n);
        chainSelectorNames = new string[](n);
        priceFeedsJsons = new string[](n);
        riskThresholdsJsons = new string[](n);
        for (uint256 i = 0; i < n; i++) {
            addresses[i] = _contracts[i].contractAddress;
            names[i] = _contracts[i].name;
            chainSelectorNames[i] = _contracts[i].chainSelectorName;
            priceFeedsJsons[i] = _contracts[i].priceFeedsJson;
            riskThresholdsJsons[i] = _contracts[i].riskThresholdsJson;
        }
    }

    function getContractCount() external view returns (uint256) {
        return _contracts.length;
    }

    function setAlertEmail(string calldata email) external onlyOwner {
        alertEmail = email;
        emit AlertEmailSet(email);
    }

    function addAlert(
        bytes32 alertId,
        address contractAddress,
        uint8 severity,
        uint256 timestamp
    ) external onlyOwner returns (bytes32) {
        require(_alertIndex[alertId] == 0, "Alert id exists");
        require(_alerts.length < MAX_ALERTS, "Max alerts reached");
        _alerts.push(AlertEntry({
            id: alertId,
            contractAddress: contractAddress,
            severity: severity,
            timestamp: timestamp,
            status: STATUS_ACTIVE,
            exists: true
        }));
        _alertIndex[alertId] = _alerts.length;
        emit AlertAdded(alertId, contractAddress, severity, timestamp);
        return alertId;
    }

    function updateAlertStatus(bytes32 alertId, uint8 status) external onlyOwner {
        uint256 idx = _alertIndex[alertId];
        require(idx > 0, "Alert not found");
        _alerts[idx - 1].status = status;
        emit AlertStatusUpdated(alertId, status);
    }

    function getAlerts(uint256 limit, uint256 offset) external view returns (
        bytes32[] memory ids,
        address[] memory contractAddresses,
        uint8[] memory severities,
        uint256[] memory timestamps,
        uint8[] memory statuses
    ) {
        uint256 n = _alerts.length;
        if (offset >= n) {
            return (new bytes32[](0), new address[](0), new uint8[](0), new uint256[](0), new uint8[](0));
        }
        uint256 end = offset + limit;
        if (end > n) end = n;
        uint256 size = end - offset;
        ids = new bytes32[](size);
        contractAddresses = new address[](size);
        severities = new uint8[](size);
        timestamps = new uint256[](size);
        statuses = new uint8[](size);
        for (uint256 i = 0; i < size; i++) {
            uint256 j = n - 1 - offset - i; // most recent first
            AlertEntry storage a = _alerts[j];
            ids[i] = a.id;
            contractAddresses[i] = a.contractAddress;
            severities[i] = a.severity;
            timestamps[i] = a.timestamp;
            statuses[i] = a.status;
        }
    }

    function getAlertCount() external view returns (uint256) {
        return _alerts.length;
    }
}
