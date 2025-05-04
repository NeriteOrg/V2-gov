// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForwardingInitiative} from "../src/initiatives/ForwardingInitiative.sol";

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploy a ForwardingInitiative

// forge script DeployForwardingInitiative.s.sol --rpc-url ${rpc} --account ${deployerAccountName} --sender ${deployerAccountAddress} --broadcast --etherscan-api-key ${etherscanApiKey} --verify

contract DeployForwardingInitiativeScript is Script {

    address forwardingInitiative;

    // governance contract
    address governance = 0x0000000000000000000000000000000000000000;
    // bold
    address revenueToken = 0x0000000000000000000000000000000000000000;
    // receives funds
    address receiver = 0x0000000000000000000000000000000000000000;

    function run() external {
        console.log("Deploying ForwardingInitiative");

        vm.broadcast();

        forwardingInitiative = address(new ForwardingInitiative(governance, revenueToken, receiver));
        vm.stopBroadcast();

        console.log("ForwardingInitiative deployed at: ", forwardingInitiative);
    }
}
