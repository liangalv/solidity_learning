//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{
    //If we're on a local Anvil, we deploy mocks
    //Otherwise grab existing address from live network 

    NetworkConfig private activeNetworkConfig;

    uint8 private constant DECIMALS = 8;
    int256 private constant INITIAL_ANSWER = 2000e8;

    struct NetworkConfig{
        address priceFeed;
    }
    constructor() {
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        }else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }                                
    }
    function getNetWorkConfig() public view returns (NetworkConfig memory){
        return activeNetworkConfig;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
                priceFeed: 0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910
            });
    }
    
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) return activeNetworkConfig;
        //Deploy Mocks
        //Return NetworkConfig
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_ANSWER);
        vm.stopBroadcast();
        return NetworkConfig({
                priceFeed: address(mockPriceFeed)
            });
    }
}