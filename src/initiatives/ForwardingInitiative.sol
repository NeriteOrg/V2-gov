// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IGovernance, UNREGISTERED_INITIATIVE} from "./interfaces/IGovernance.sol";
import {IInitiative} from "./interfaces/IInitiative.sol";

import {DoubleLinkedList} from "./utils/DoubleLinkedList.sol";
import {_lqtyToVotes} from "./utils/VotingPower.sol";

/// @title ForwardingInitiative
/// @author MrDeadCe11
/// @notice Initiative that forwards all received token to a receiver address
contract ForwardingInitiative is IInitiative, Ownable {
    IGovernance public governance;
    IERC20 public revenueToken;
    address public receiver;

    constructor(address _owner, address _governance, address _revenueToken, address _receiver) {
        require(_revenueToken != address(0), "InitialInitiative: revenue-token-cannot-be-zero");
        
        governance = IGovernance(_governance);
        revenueToken = IERC20(_revenueToken);

        // assert valid governance contract
        uint256 _EPOCH_START = governance.EPOCH_START();
        require(_EPOCH_START != 0, "InitialInitiative: epoch-start-cannot-be-zero");

        // assert valid revenue token
        string memory symbol = revenueToken.symbol();
        require(bytes(symbol).length > 0, "InitialInitiative: revenue-token-symbol-cannot-be-empty");

        require(_receiver != address(0), "InitialInitiative: dao-treasury-cannot-be-zero");
        receiver = _receiver;
    }

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "BribeInitiative: invalid-sender");
        _;
    }

    /// @inheritdoc IInitiative
    function onRegisterInitiative(uint256 _atEpoch) external onlyGovernance {}

    /// @inheritdoc IInitiative
    function onUnregisterInitiative(uint256 _atEpoch) external onlyGovernance {}

    /// @inheritdoc IInitiative
    function onAfterAllocateLQTY(
        uint256 _currentEpoch,
        address _user,
        IGovernance.UserState calldata _userState,
        IGovernance.Allocation calldata _allocation,
        IGovernance.InitiativeState calldata _initiativeState
    ) external onlyGovernance {}

    /// @inheritdoc IInitiative
    function onClaimForInitiative(uint256 _claimEpoch, uint256 _revenue) external onlyGovernance {
        if (receiver == address(0)) {
            revert ("Receiver not set");
        }

        uint256 revenueToForward = revenueToken.balanceOf(address(this));
        if (revenueToForward > 0) {
            SafeERC20.safeTransfer(revenueToken, receiver, revenueToForward);
        }
    }
}
