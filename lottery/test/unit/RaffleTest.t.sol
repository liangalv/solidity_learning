//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkTokenContract;

    //This is one of the standard cheats
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            linkTokenContract
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function test_RaffleIntializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testFail_NotEnoughPaid() public {
        vm.startPrank(PLAYER);
        //Don't send any value
        raffle.enterRaffle();
        vm.stopPrank();
    }

    //Alternatively, instead of denoting with a testFail prefix, you can use vm.expectRevert cheatcodes
    function test_NotEnoughtPaid() public {
        vm.prank(PLAYER);
        //It gives you more granular control as you can specify what error you expect to see
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function test_RecordsPlayerWhenTheyEnterLottery() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);

        assert(playerRecorded == PLAYER);
    }

    //Use expectEmit if you expect the test to emit an event
    function test_EmitsEventOnEntrance() public {
        vm.startPrank(PLAYER);
        //Setup by defining the indexed params, calldata and expected emitter
        vm.expectEmit(true, false, false, false, address(raffle));
        //Emit what we expect to be emitted
        emit Raffle.EnteredRaffle(PLAYER);
        //Finally make the call to function that we expect to emit the event
        raffle.enterRaffle{value: entranceFee}();
    }

    function test_CantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
}
