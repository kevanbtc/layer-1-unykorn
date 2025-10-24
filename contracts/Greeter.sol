// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Greeter
 * @dev Simple contract to verify Unykorn L1 deployment
 */
contract Greeter {
    string private greeting;
    address public owner;
    uint256 public greetingCount;
    
    event GreetingChanged(string oldGreeting, string newGreeting, address changedBy);
    
    constructor(string memory _greeting) {
        greeting = _greeting;
        owner = msg.sender;
        greetingCount = 0;
    }
    
    /**
     * @dev Get the current greeting
     */
    function greet() public view returns (string memory) {
        return greeting;
    }
    
    /**
     * @dev Update the greeting (anyone can call)
     */
    function setGreeting(string memory _greeting) public {
        string memory oldGreeting = greeting;
        greeting = _greeting;
        greetingCount++;
        emit GreetingChanged(oldGreeting, _greeting, msg.sender);
    }
    
    /**
     * @dev Get contract info
     */
    function getInfo() public view returns (string memory, address, uint256) {
        return (greeting, owner, greetingCount);
    }
}
