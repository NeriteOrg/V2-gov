// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IGovernance} from "../src/interfaces/IGovernance.sol";
import {IInitiative} from "../src/interfaces/IInitiative.sol";
import {Governance} from "../src/Governance.sol";
import {MockERC20Tester} from "./mocks/MockERC20Tester.sol";
import {MockStakingV1} from "./mocks/MockStakingV1.sol";
import {MockStakingV1Deployer} from "./mocks/MockStakingV1Deployer.sol";
import {ForwardingInitiative} from "../src/initiatives/ForwardingInitiative.sol";

contract ForwardingInitiativeTest is MockStakingV1Deployer {

    uint32 constant START_TIME = 1732873631;
    uint32 constant EPOCH_DURATION = 7 days;
    uint32 constant EPOCH_VOTING_CUTOFF = 6 days;

    IGovernance.Configuration config = IGovernance.Configuration({
        registrationFee: 0,
        registrationThresholdFactor: 0,
        unregistrationThresholdFactor: 4 ether,
        unregistrationAfterEpochs: 4,
        votingThresholdFactor: 0,
        minClaim: 0,
        minAccrual: 0,
        epochStart: START_TIME - EPOCH_DURATION,
        epochDuration: EPOCH_DURATION,
        epochVotingCutoff: EPOCH_VOTING_CUTOFF
    });

    MockStakingV1 stakingV1;
    MockERC20Tester lqty;
    MockERC20Tester lusd;
    MockERC20Tester bold;
    Governance governance;
    ForwardingInitiative public forwardingInitiative;

    address[] noInitiatives; // left empty
    address[] initiatives;
    int256[] votes;
    int256[] vetos;
    address voter;

    address voterProxy;

    function setUp() public {
        vm.warp(START_TIME);

        (stakingV1, lqty, lusd) = deployMockStakingV1();

        bold = new MockERC20Tester("BOLD Stablecoin", "BOLD");
        vm.label(address(bold), "BOLD");

        governance = new Governance({
            _lqty: address(lqty),
            _lusd: address(lusd),
            _stakingV1: address(stakingV1),
            _bold: address(bold),
            _config: config,
            _owner: address(this),
            _initiatives: new address[](0)
        });

        forwardingInitiative = new ForwardingInitiative(address(governance), address(bold), address(this));
        initiatives.push(address(forwardingInitiative));
        governance.registerInitialInitiatives(initiatives);

        voter = makeAddr("voter");
        lqty.mint(voter, 1 ether);

        vm.startPrank(voter);
        voterProxy = governance.deployUserProxy();
        lqty.approve(governance.deriveUserProxyAddress(voter), type(uint256).max);
        governance.depositLQTY(1 ether);
        vm.stopPrank();

        votes.push();
        vetos.push();
    }

    function test_ForwardingInitiative_Deploy() public {
        assertEq(forwardingInitiative.receiver(), address(this));
        assertEq(forwardingInitiative.revenueToken(), address(bold));
        assertEq(forwardingInitiative.governance(), address(governance));
    }

    function test_ForwardingInitiative_Claim() public {
        uint256 voteAmount = 1 ether;

        bold.mint(address(governance), voteAmount);
        lqty.mint(address(voter), voteAmount);
        vm.startPrank(voter);
        votes[0] = 1 ether;
        bold.approve(address(voterProxy), voteAmount);
        // deposit voting token
        governance.depositLQTY(voteAmount);
        // vote on initiative
        governance.allocateLQTY(noInitiatives, initiatives, votes, vetos);
        vm.stopPrank();

        // One epoch later
        vm.warp(block.timestamp + EPOCH_DURATION);
        governance.claimForInitiative(address(forwardingInitiative));
        assertEq(bold.balanceOf(address(this)), 1 ether, "should have received rewards");
    }
}
