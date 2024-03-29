//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();

        (,, address vrfCoordinator,,,,,uint256 deployerKey) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(address vrfCoordinator, uint256 deployerKey) public returns (uint64) {
        console.log("Creating subscription on chainId:", block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subId is:", subId);
        console.log("Pls add your subsciptionId to helperConfig");
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();

        (,, address vrfCoordinator,, uint64 subscriptionId,, address link,uint256 deployerKey) 
        = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);
    }


    function fundSubscription(
        address vrfCoordinator,
        uint64 subId,
        address link,
        uint256 deployerKey
    ) public {
        console.log("Funding subscription:", subId);
        console.log("Uing vrfCoordinator:", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);

        if(block.chainid == 31337){
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);

            vm.stopBroadcast();
        }else {
            vm.startBroadcast(deployerKey);
                LinkToken(link).transferAndCall(
                    vrfCoordinator,
                    FUND_AMOUNT,
                    abi.encode(subId)
                );
            vm.stopBroadcast();
        }
    }
    function run() external {
        fundSubscriptionUsingConfig();
    }
}
contract AddConsumer is Script {

    function addConsumer(address raffle, address vrfCoordinator, uint64 subId, uint256 deployerKey) public {
        console.log("Funding subscription:", subId);
        console.log("Uing vrfCoordinator:", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
            vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint64 subscriptionId,,,uint256 deployerKey) 
        = helperConfig.activeNetworkConfig();
        addConsumer(raffle,vrfCoordinator, subscriptionId, deployerKey);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}