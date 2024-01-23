// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SimpleStorage {
uint256 public personCount;
    uint256 favoriteNumber;
    Person[] public person;

    struct Person {
        string name;
        uint256 age;
    }

    mapping(string => uint256) public nameToAge;

    function createPerson(string memory _name, uint256 _age) public {
        personCount += 1;
        person.push(Person(_name, _age));
    }

    function getPersonCount() public view returns (uint256) {
        return personCount;
    }

    function store(uint256 _favoriteNUmber) public virtual {
        favoriteNumber = _favoriteNUmber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}
