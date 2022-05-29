//SPDX-License-Identifier: MIT 
pragma solidity >=0.6.0 < 0.9.0;
//Injected Web3 means that we're taking the source code and injecting it into the source code that sits on our browswer 
//Web3 provider is if we want to use our own blockchain node or Web3 Provider 


contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber; 
        string Name; 

    }

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber; 
     function store(uint256 _favoriteNumber) public{
        favoriteNumber = _favoriteNumber;
    }
    function retrieve() public view returns(uint256){
        return favoriteNumber;

    }
    // Memory Keyword 
    //There are two ways in solidity to store information 
        //either you store it in memory, which means that data will only be stored during the execution of the function 
        //Storage: it means that that data will persist after the function call 
        //Strings in solidity are actually an array of bytes, because they aren't a value type, we need to define where we want to store it 
    function addPerson(string memory _name, uint256 _favoriteNumber) public{
        people.push(People({favoriteNumber: _favoriteNumber, Name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
        
    }


}

