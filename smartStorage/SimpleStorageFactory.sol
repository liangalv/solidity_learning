//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SimpleStorage} from "./SimpleStorage.sol";

contract SimpleStorageFactory {
    SimpleStorage[] public listOfSimpleStorageContracts;

    function createNewSimpleStorageContract() public {
        //this actually deploys a new contract, if you're using the new keyword
        listOfSimpleStorageContracts.push(new SimpleStorage());
    }

    function sfStore(
        uint256 _simpleStorageIndex,
        uint256 _newSimpleStorage
    ) public {
        SimpleStorage mySimpleStorage = listOfSimpleStorageContracts[
            _simpleStorageIndex
        ];
        mySimpleStorage.store(_newSimpleStorage);
    }

    function sfGet(uint256 _simpleStorageIndex) public view returns (uint256) {
        SimpleStorage mySimpleStorage = listOfSimpleStorageContracts[
            _simpleStorageIndex
        ];
        return mySimpleStorage.retrieve();
    }
}
