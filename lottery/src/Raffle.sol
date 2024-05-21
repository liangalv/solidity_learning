//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title A Sample Raffle contract
 * @author liangalv
 * @notice This contract is for creating a sample raffle
 * @dev Implements ChainLink VRFv2
 */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );
    /**Type Declarations */

    //In Solidity, enums can be explicitly converted to integer values
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }

    /**State Variables  */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_entranceFee;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    //@dev Duration of lottery in seconds
    uint256 private immutable i_interval;
    //We're going to use a dynamic array because we can loop through and append whereas a mapping can't be looped through
    //Because we're going to need to eventually pay out these players they gotta be payable
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_callbackGasLimit = callbackGasLimit;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    //We want this to be external as it's both more gas efficient and prevents internal calls
    function enterRaffle() external payable {
        if (msg.value != i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        //As rule of thumb everytime a storage var state changes we should emit an event
        //1. Makes contract migration (update) easier
        //2. Makes front end "indexing" easier
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is a function that the chainlink automation nodes call in
     * order to see if it's time to perform an upkeep
     * The following should be true for this to return true
     * 1. The interval has passed between raffle runs
     * 2. The raffle is in the OPEN state
     * 3. The contract has ETH (aka Players)
     * 4. (Implicit) The subscription is funded with LINK
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        bool enoughTimePassed = (block.timestamp - s_lastTimestamp) >=
            i_interval;
        bool raffleOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded =
            enoughTimePassed &&
            raffleOpen &&
            hasBalance &&
            hasPlayers;
        //Better to be explicit to return upkeepNeeded and a blank bytes object even if not required
        return (upkeepNeeded, bytes(""));
    }

    /**
     * 1. Get a random number
     * 2. Use the random number to pick a playe
     * 3. Be automatically called
     */
    //calldata refers to a memory location specific to external function calls, which
    //cannot be modified
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        if (block.timestamp - s_lastTimestamp <= i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        //This is redundant because the VRF coordinator already emits an event that chainlink nodes pick up
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        //Modulo gives us the remainder value which is always in the range of 0 -> len(s_players)
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        emit PickedWinner(winner);
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**Getter functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(
        uint256 indexOfPlayer
    ) external view returns (address payable) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimestamp;
    }
}
