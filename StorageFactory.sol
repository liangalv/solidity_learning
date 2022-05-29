//SPDX-License-Identifier: MIT 
pragma solidity ^0.6.0;

import "./SimpleStorage.sol"; 
// to deploy a contract, we need all the functionality of the contract imported
// to interact with a contract, you don't need to import everything you can just use an interface 
// importing this into the file, is essentially the equivalent of importing the entire contract into the code

contract StorageFactory is SimpleStorage{
    //this will make it inherit all of the functions and variables of SimpleStorage 
    SimpleStorage[] public simpleStorageArray;
    // here we are deploying a contract from another contract! 
    function createSimpleStorageContract() public{
        SimpleStorage simpleStorage = new SimpleStorage();
        simpleStorageArray.push(simpleStorage);

    }
    // we can actually do more than that, and call functions from the other contract 
    function sfStore(uint256 _simpleStorageIndex, uint256 _simpleStorageNumber) public {
        // Any time you want to interact with a contract, you need 
        //Address
        //ABI: Application binary interface
        SimpleStorage(address(simpleStorageArray[_simpleStorageIndex])).store(_simpleStorageNumber);
    }

    function sfGet(uint256 _simpleStorageIndex) public view returns(uint256){
        return SimpleStorage(address(simpleStorageArray[_simpleStorageIndex])).retrieve();
    }


}