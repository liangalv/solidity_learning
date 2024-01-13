//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from './PriceConverter.sol';

contract FundMe{

    uint256 public minimumUsd = 5e18;

    address[] public funders;

    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    function fund()public payable{
        require(getConversionRate(msg.value) >= mimimumdUsd, didn't send enough ETH);
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
        
    }

    
} 