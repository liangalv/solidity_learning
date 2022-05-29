// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 < 0.9.0;
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//when we're importing @chainlink/contracts, we're actually importing from this npm package 
//which means we're importing the chainlink contracts price interface
//Solidity does not know natively how to interact with another contract, we have to tell solidity what functions
//can be called on another contract 
// These interfaces compile down to an ABI: Application binary interface 
//ABI tells solidity and other progrmaming languges how it can interact with another contract 
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
//prevents integer overflow with solidity versions 8 >

contract FundMe{


    mapping(address => uint256) public addressToAmountFunded;
    address public owner; 
    
    constructor() public {
        owner = msg.sender;
        // i.e the person that deploys this smart contract  

    }
    // constructor functions immediately get executed prior to contract execution 

    
    function fund() public payable{
        // this function can be used to pay for this 
        // one wei represents the smallest denomination of ether 
        // you cannot break up Eth to anything smaller than 1 wei
        uint256 minimumUSD = 50 * 10** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!"); 
        addressToAmountFunded[msg.sender] += msg.value;
        // msg.sender and msg.value are keywords in every contract call/transaction 
        // msg. sender is the sender of the function call 
        //msg.value is how much they sent  

    }
    function getVersion() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // it's saying that we have a contract, with the interface functions at that particular address 
        return priceFeed.version();
    }
    function getPrice() public view returns(uint256){
        (, int256 price,,,) = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e).latestRoundData();
        return uint256(price * 10000000000);
        //A Tuple is a list of objects of potentially different types whose number is a constant at compile-time
        //1,785.48789241 there are 8 decimal places 
    }
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1000000000000000000;
        return ethAmountInUsd;

    }
    modifier onlyOwner{
        
    }

    function withdraw() payable public{
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
        //this is a keyword in solidity, when ever you type "this", it refers to the 
        // current contract that you are on in solidity 
        //whoever calls the contract will be msg.sender 

    }
}