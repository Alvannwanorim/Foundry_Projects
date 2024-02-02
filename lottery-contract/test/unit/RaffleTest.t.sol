//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
contract RaffleTest is Test {
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant START_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        (entranceFee, interval, vrfCoordinator, gasLane, subscriptionId, callbackGasLimit, link, ) =
            helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, START_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        //Arrange
        vm.prank(PLAYER);

        //Act /Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEth.selector);
        raffle.enterRaffle();
    }

    function testRaflleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle___RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseItHasNoBalance() public{
        //Arrange 
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);

        //Act 
        (bool upkeepNeeded, ) = raffle.checkUpKeep(""); 

        //Assert 
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act 
        (bool upkeepNeeded, ) = raffle.checkUpKeep(""); 

        //Assert 
        assert(upkeepNeeded == false);
    }
    function testCheckUpKeepReturnsFalseIfEnoughTimeHasNotPassed() public {
        //Arrange 
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.roll(block.number + 1);
        raffle.checkUpKeep("");
        //Act 
       (bool upkeepNeeded,) = raffle.checkUpKeep(""); 

        //Assert 
        assert(upkeepNeeded == false);
    }
     function testCheckUpKeepReturnsTrueIfParameterAreGood() public {
        //Arrange 
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);
        raffle.checkUpKeep("");
        //Act 
       (bool upkeepNeeded,) = raffle.checkUpKeep(""); 

        //Assert 
        assert(upkeepNeeded == true);
    }

    function testPerformUpkeepOnlyRunsIfCheckUpISTrue() public {
        //Arrange 
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);
        //Act/ Assert
       raffle.performUpkeep("");

    }

    function testPerformUpkeepRevertsIfUpkeepNotNeeded() public {
        //Arrange 
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;
        //Act/ Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector, 
                currentBalance,
                numPlayers,
                raffleState)
        );
       raffle.performUpkeep("");

    }

    modifier raffleEnteredAndTimePassed(){
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatedRaffleStateAndEmitsRequestId() public raffleEnteredAndTimePassed {
        // Act  
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        assert(uint256(requestId) > 0);

    }

    modifier skipFork() {
        if(block.chainid != 31337){
            return;
        }
        _;
    }

    function testfulfillRandomWordsCanOnlyBeCalledAfterPerfromUpkeep(
        uint256 randomRequestId
    ) public  skipFork raffleEnteredAndTimePassed {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }


    function testFulfillRandomeWordsPicksAWinnerResetsAndSendMoney() public skipFork raffleEnteredAndTimePassed {
        uint256 addiontionalEntrants = 5;
        uint256 startingIndex =1 ;
        for(uint256 i= startingIndex; i < startingIndex + addiontionalEntrants; i++){
            address player = address(uint160(i));
            hoax(player, START_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee  * (addiontionalEntrants + 1);
        
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 prevousTimeStamp = raffle.getLastTimeStamp();


         VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

         // Assert 
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayers() == 0 );
        assert(raffle.getLastTimeStamp() > prevousTimeStamp );
        assert(raffle.getRecentWinner().balance == START_USER_BALANCE + prize - entranceFee) ;
        
    }
}
