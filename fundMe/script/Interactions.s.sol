//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DevOpTools} from "foundry-devops/src/DevOpTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script{
    uint256 private constant SEND_VALUE = 0.01 ether;
    function fundFundMe (address mostRecentDeployment){
        vm.startBroadcast();
        FundMe(mostRecentDeployment).call{value:SEND_VALUE}();
        vm.stopBroadcast();
    }
    function run() external{
        address mostRecentDeployment = DevOpTools.get_most_recent_deployment("FundMe",block.chainid);
        FundFundMe(mostRecentDeployment);
    }
}

contract WithdrawFundMe is Script{}