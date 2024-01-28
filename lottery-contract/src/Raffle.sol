// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//Imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
//Errors

error Raffle__NotEnoughEth();
error Raffle__TransferFailed();
error Raffle___RaffleNotOpen();
error Raffle__UpkeepNotNeeded(uint256 balance, uint256 players, uint256 raffleState);

/// @title A simple Raffle Contract
/// @author Alvan
/// @notice ExplTHis contract is for creating sample Raffle Lottery
/// @dev Implements Chainlink VRFv2

contract Raffle is VRFConsumerBaseV2 {
    //////////////////////
    // Type Declarations//
    /////////////////////
    enum RAffleState {
        OPEN,
        CALCULATING
    }
    //////////////////////
    // State Variables  //
    /////////////////////

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    // Constants
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    RAffleState private s_raffleState;

    //////////////////////
    // Events           //
    /////////////////////
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    //////////////////////
    // Modifiers        //
    /////////////////////

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RAffleState.OPEN;
    }

    /**
     * @dev This is the function that the Chainlink Autmationation will call
     * to see if it's the time to peform an update.
     * The folleing should be true for this to returntrue:
     * 1. The time interval has passed between raffle runs
     * 2. The raffle is in the OPEN state
     * 3. The contract has ETH (aka, playeers)
     * 4. (Implicit) The subscription is funeded with LINK
     * @return upkeepNeeded for use by function call
     * @return performData or use by function call
     */
    function checkUpKeep(bytes memory /*checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData*/ )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RAffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }

        if (s_raffleState != RAffleState.OPEN) {
            revert Raffle___RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    function performUpkeep(bytes memory /*performData */ ) external {
        (bool upkeeepNeeded,) = checkUpKeep("");
        if (!upkeeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        s_raffleState = RAffleState.CALCULATING;
        i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATION, i_callbackGasLimit, NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256, /*requestId*/ uint256[] memory randonWords) internal override {
        uint256 indexOfWinner = randonWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RAffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit PickedWinner(winner);
    }

    //////////////////////
    // Getter Functions //
    /////////////////////

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
