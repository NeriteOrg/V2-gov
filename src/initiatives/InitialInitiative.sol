// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IGovernance, UNREGISTERED_INITIATIVE} from "./interfaces/IGovernance.sol";
import {IInitiative} from "./interfaces/IInitiative.sol";

import {DoubleLinkedList} from "./utils/DoubleLinkedList.sol";
import {_lqtyToVotes} from "./utils/VotingPower.sol";

/// @title InitialInitiative
/// @author MrDeadCe11
/// @notice Initial initiative that is registered by default and receives 100% of the revenue and forwards it to the dao treasury
contract InitialInitiative is IInitiative {
    IGovernance public governance;
    IERC20 public revenueToken;
    address public daoTreasury;

    uint256 public EPOCH_START;
    uint256 public EPOCH_DURATION;

    constructor(address _governance, address _revenueToken, address _daoTreasury) {
        require(_revenueToken != address(0), "InitialInitiative: revenue-token-cannot-be-zero");

        governance = IGovernance(_governance);
        revenueToken = IERC20(_revenueToken);

        EPOCH_START = governance.EPOCH_START();
        EPOCH_DURATION = governance.EPOCH_DURATION();
        daoTreasury = _daoTreasury;
    }

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "BribeInitiative: invalid-sender");
        _;
    }

    function updateDaoTreasury(address _daoTreasury) external onlyGovernance {
        daoTreasury = _daoTreasury;
    }

    /// @inheritdoc IInitiative
    function onRegisterInitiative(uint256 _atEpoch) external onlyGovernance {
        // TODO: Implement if needed
    }

    /// @inheritdoc IInitiative
    function onUnregisterInitiative(uint256 _atEpoch) external {
        // TODO: Implement if needed
    }

    /// @inheritdoc IInitiative
    function onAfterAllocateLQTY(
        uint256 _currentEpoch,
        address _user,
        IGovernance.UserState calldata _userState,
        IGovernance.Allocation calldata _allocation,
        IGovernance.InitiativeState calldata _initiativeState
    ) external onlyGovernance {
        // TODO: Implement if needed
    }

    /// @inheritdoc IInitiative
    function onClaimForInitiative(uint256 _claimEpoch, uint256 _revenue) external {
        if (daoTreasury == address(0)) {
            revert ("Dao treasury not set");
        }

        uint256 revenueToForward = revenueToken.balanceOf(address(this));
        if (revenueToForward > 0) {
            revenueToken.safeTransfer(daoTreasury, revenueToForward);
        }
    }
}
