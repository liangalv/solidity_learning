//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 SEND_VALUE = 0.01 ether; //10000000000000000 wei
    uint256 USER_BALANCE = 10 ether;


    //setUp is special and always runs first and prior to every test execution
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, USER_BALANCE);
    }
    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }
    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public{
        //This cheatcode will is saying that it expects the next line to revert 
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded(){
        //prank makes it so that the next call will always be called from the user arg you provide
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }
    function testAddsFunderToFundersArray() public funded{
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }
    function testOwnerWithdrawlSingleFunder() public funded{
        uint256 oldBalance = msg.sender.balance;
        
        //withdraw to this to ownerAccount 
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        assertEq(msg.sender.balance - oldBalance, SEND_VALUE);
    }

    function testOwnerWithdrawlMultipleFunders() public funded{
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 funderIndex = 1; //we're starting with 1 cause 0 can cause a revert
        for (uint160 i = funderIndex; i < numberOfFunders; i++){
            //Because we're hoaxing it, we're also pranking and dealing
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        //Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance); 
    }
    
}
