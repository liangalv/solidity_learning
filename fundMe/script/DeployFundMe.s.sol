// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    // Your contract code goes here

    function run() external returns (FundMe){
        HelperConfig helperConfig = new HelperConfig();

        vm.startBroadcast();
        FundMe fundMe  = new FundMe(helperConfig.getNetWorkConfig().priceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
