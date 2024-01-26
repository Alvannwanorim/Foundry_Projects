// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 5 ether;
    uint256 STARTING_BALANCE = 50 ether;
    uint256 constant GAS_PRICE = 1;
    function setUp() external {
        // fundMe= new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    
    function testMinimumUSD() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    //What can we do to work with our addresses outside our system?
    // 1. Unit
    //  - Testing a specific part of our code
    // 2. Integration
    //  - Test how our code works with other parts of our code
    // 3. Forked
    // - Testing out code on a simulated real environment
    // 4. Staging
    // - Testing our code in a real enviornment that is not prod
    // function testPriceFeedVersion() public {
    //     uint256 version = fundMe.getVersion();
    //     assertEq(version, 4);
    // }

    function testFundFailWithoutEnoughWTH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructue() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFounded = fundMe.getAddressToAmountFunded(USER);
        console.log(amountFounded);
        assertEq(amountFounded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(USER, funder);
    }

    modifier funded () {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded(){
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act 
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert 
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMebalance = address(fundMe).balance;
        assertEq(endingFundMebalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange 

        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i< numberOfFunders; i++){
            //vm.prank new address 
            //vm.deal new address 
            // address()
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

    
        //Act 
        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        // vm.stopPrank();
        // uint256 gasEnd = gasleft();
        
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        // Assert 
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, fundMe.getOwner().balance);
    }


        function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange 

        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i< numberOfFunders; i++){
            //vm.prank new address 
            //vm.deal new address 
            // address()
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

    
        //Act 
        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        // vm.stopPrank();
        // uint256 gasEnd = gasleft();
        
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        // Assert 
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, fundMe.getOwner().balance);
    }

    
}
