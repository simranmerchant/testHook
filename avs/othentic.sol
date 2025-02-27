    // SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.19;

interface IOthentic {
    function submitTask(bytes32 taskId, bytes calldata data) external;
    function getAttestation(bytes32 taskId) external view returns (bool success, bytes memory result);
}

contract PayoutVerifier {
    IOthentic public othentic;
    address public payoutManager; // Address managing payouts (e.g., your contract)

    mapping(address => uint256) public expectedPayouts; // Expected rewards per LP
    mapping(address => bool) public verifiedPayouts; // Whether payout was verified

    event PayoutSubmitted(address indexed lp, uint256 amount, bytes32 taskId);
    event PayoutVerified(address indexed lp, uint256 amount, bool success);

    constructor(address _othentic, address _payoutManager) {
        othentic = IOthentic(_othentic);
        payoutManager = _payoutManager;
    }

    modifier onlyPayoutManager() {
        require(msg.sender == payoutManager, "Not authorized");
        _;
    }

    function submitPayoutForVerification(address lp, uint256 amount) external onlyPayoutManager {
        bytes32 taskId = keccak256(abi.encodePacked(lp, amount, block.timestamp));

        expectedPayouts[lp] = amount; // Store expected payout
        othentic.submitTask(taskId, abi.encode(lp, amount));

        emit PayoutSubmitted(lp, amount, taskId);
    }

    function verifyPayout(bytes32 taskId, address lp) external {
        (bool success, bytes memory result) = othentic.getAttestation(taskId);

        require(success, "Othentic verification failed");
        (uint256 verifiedAmount) = abi.decode(result, (uint256));

        require(verifiedAmount == expectedPayouts[lp], "Payout mismatch");
        verifiedPayouts[lp] = true;

        emit PayoutVerified(lp, verifiedAmount, success);
    }

    function isPayoutVerified(address lp) external view returns (bool) {
        return verifiedPayouts[lp];
    }
}
