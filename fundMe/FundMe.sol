//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from './PriceConverter.sol';

error Unauthorized();

contract FundMe{
    //extension on uint256 functionality using a library
    using PriceConverter for uint256;

    //this constant specifier is when the value is set on declartion and never modified again 
    uint256 public constant MINIMUM_USD = 5e18;

    address[] public funders;
    //this immutable specifier is used when the value is NOT set on declaration but set only ONCE
    address public immutable i_owner;

    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    //How do you pass 
    constructor(){
        i_owner = msg.sender;

    }
    
    function fund()public payable{
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't send enough ETH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }
    function withdraw() public onlyOwner{
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++ ){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //generates a new array
        funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!callSuccess){revert Unauthorized();}
    }

    modifier onlyOwner{
        if(msg.sender != owner){revert Unauthorized();}
        _;
    }

    receive() public payable{
        fund();
    }

    fallback()public payable{
        fund();
    }
} 