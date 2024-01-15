//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    function getPrice() internal view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);

    }

    function getConversionRate(uint256 ethAmount) internal view returns(uint256){
        uint256 ethPrice = getPrice();
        //You always want to multiple before you divide because everything in solidity operates in whole numbers
        //both the values here have 18 decimal places so if you multiple them you'll get a massive number so you have to divide by 10000000000000000000
        return (ethAmount * ethPrice) / 1e18;

    }
    function getVersion() internal view returns(uint256) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }
}