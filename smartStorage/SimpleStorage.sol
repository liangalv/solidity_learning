//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleStorage {
    uint256 myFavoriteNumber;

    struct Person {
        string name;
        uint256 favoriteNumber;
    }
    Person[] public personList; 

    mapping(string =>uint256) public nameToNumber;


    function store(uint256 _newNumber) public virtual{
        myFavoriteNumber = _newNumber;
    }

    function addNewPerson(string memory _name, uint256 _newNumber) public{
        personList.push(Person(_name, _newNumber));
        nameToNumber[_name] = _newNumber;
    }
    function retrieve() view public returns(uint256){
        return myFavoriteNumber;
    }
}