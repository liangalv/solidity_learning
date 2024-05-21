//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";

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

    modifier enterRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        _;
    }
    modifier advanceTime() {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
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

    /////////////////
    // checkUpKeep //
    /////////////////

    function test_checkUpKeepReturnsFalseIfIthasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function test_checkUpKeepReturnsFalseIfRaffleNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function test_checkUpkeepReturnsFalseIfNotEnoughTimeHasPassed()
        public
        enterRaffle
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function test_checkUpkeepReturnsTrueWhenParametersAreValid()
        public
        enterRaffle
        advanceTime
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    ///////////////////
    // performUpKeep //
    ///////////////////

    function test_PerformUpkeepCanOnlyRunIfPerformUpkeepIsTrue()
        public
        enterRaffle
        advanceTime
    {
        raffle.performUpkeep("");
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    function test_PerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function test_PerformUpkeepUpdatesRaffleStateandEmitsEvent()
        public
        enterRaffle
        advanceTime
    {
        //soldity contracts don't have access to emitted events and their topics
        //vm.recordLogs records all emitted events
        vm.recordLogs();
        raffle.performUpkeep(""); //going to emit the requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();

        //In the topics array the event itself is the event itself
        bytes32 requestId = entries[1].topics[1];

        console.log("RequestId: ", uint256(requestId));
        assert(uint256(requestId) > 0);
    }

    /////////////////////////
    // fullfillRandomWords //
    /////////////////////////

    //FuzzTesting
    //Forge will run any test that takes at least one paramter as a property based test
    //Property based testing is a way of testing general behaviours as opposed to isolated scenarios

    function testFuzz_FullFillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public enterRaffle advanceTime {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function test_FullfillsRandomWordPicksWinnerResetsAndSendsMoney()
        public
        advanceTime
        enterRaffle
    {
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;

        for (uint256 i = startingIndex; i < additionalEntrants + 1; i++) {
            //An Address has 20 bytes in Eth 160 bits -> 20bytes
            address player = address(uint160(i));
            //This both pranks and deals (ensures next call made by player, and funds)
            hoax(player, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        vm.recordLogs();
        raffle.performUpkeep(""); //going to emit the requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();

        uint256 requestId = uint256(entries[1].topics[1]);

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );

        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayers() == 0);
        assert(raffle.getLastTimeStamp() > previousTimeStamp);
    }
}
