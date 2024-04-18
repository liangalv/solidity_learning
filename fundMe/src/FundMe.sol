// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    //Immutable variables are not stored in storage
    //They are computed and set at deployment time which hardcodes their value into the bytecode of a contract
    address private immutable i_owner; //Immutable variables can only be declared during contract deployment
    //constants are actually deprecated, they too are hardcoded into bytecode, but can only encompass primitives
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;

    AggregatorV3Interface private s_priceFeed;
    
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }
    function getVersion() public view returns (uint256){
        return s_priceFeed.version();
    }
    
    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    function cheaperWithdrawl() public onlyOwner{
        uint256 len = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < len; funderIndex++) {
            s_addressToAmountFunded[s_funders[funderIndex]] = 0;
        }
        //The 0 specifies the length of the array
        s_funders = new address[](0);
        (bool succ, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(succ, "call failed");
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
    /**
     *View Functions
     */
    function getAddressToAmountFunded(address _address) external view returns (uint256){
        return s_addressToAmountFunded[_address];
    }
    function getFunder(uint256 _funderIndex) external view returns(address){
        return s_funders[_funderIndex];
    }
    function getOwner() external view returns(address){
        return i_owner;
    }

}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly