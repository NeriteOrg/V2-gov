// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {IGovernance} from "../interfaces/IGovernance.sol";
import {IInitiative} from "../interfaces/IInitiative.sol";


/// @title ForwardingInitiative
/// @author MrDeadCe11
/// @notice Initiative that forwards all received token to a receiver address
contract ForwardingInitiative is Ownable, IInitiative {
    IGovernance private _governance;
    IERC20 private _revenueToken;
    address private _receiver;

    constructor(address governance, address revenueToken, address receiver) Ownable(msg.sender) {
        require(revenueToken != address(0), "ForwardingInitiative: revenue token cannot be zero");
        
        _governance = IGovernance(governance);
        _revenueToken = IERC20(revenueToken);

        // assert valid revenue token
        (bool success, ) = address(_revenueToken).call(abi.encodeWithSelector(IERC20.totalSupply.selector));
        require(success, "ForwardingInitiative: revenue token total supply call must succeed");

        require(receiver != address(0), "ForwardingInitiative: receiver cannot be zero");
        _receiver = receiver;
    }

    modifier onlyGovernance() {
        require(msg.sender == address(_governance), "ForwardingInitiative: invalid sender");
        _;
    }

    function revenueToken() public view returns (address) {
        return address(_revenueToken);
    }

    function governance() public view returns (address) {
        return address(_governance);
    }

    function receiver() public view returns (address) {
        return _receiver;
    }

    function updateGovernance(address newGovernance) external onlyOwner {
        _governance = IGovernance(newGovernance);
    }

    function updateReceiver(address newReceiver) external onlyOwner {
        _receiver = newReceiver;
    }

    function updateRevenueToken(address newRevenueToken) external onlyOwner {
        _revenueToken = IERC20(newRevenueToken);
    }

    /// @inheritdoc IInitiative
    function onRegisterInitiative(uint256 _atEpoch) external onlyGovernance {
        // assert valid revenue token
        (bool success, ) = address(_revenueToken).call(abi.encodeWithSelector(IERC20.totalSupply.selector));
        require(success, "ForwardingInitiative: revenue token total supply call must succeed");

        // assert valid governance contract
        uint256 EPOCH_START = _governance.EPOCH_START();
        require(EPOCH_START != 0, "ForwardingInitiative: epoch start cannot be zero");
    }

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
        if (address(_receiver) == address(0)) {
            revert ("Receiver not set");
        }

        // forward all revenue to receiver
        uint256 revenueToForward = _revenueToken.balanceOf(address(this));
        if (revenueToForward > 0) {
            SafeERC20.safeTransfer(_revenueToken, _receiver, revenueToForward);
        }
    }
}
