// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./DecentralizedShipCharter.sol";

contract DecentralizedShipCharterTest is Test {
    DecentralizedShipCharter charter;
    address owner;
    address charterer;
    uint256 shipId = 1;
    uint256 price = 1 ether;

    function setUp() public {
        charter = new DecentralizedShipCharter();
        owner = address(30);
        charterer = address(40);

        // Label the addresses for easier debugging
        vm.label(owner, "Owner");
        vm.label(charterer, "Charterer");

        // Fund the charter contract with sufficient Ether
        vm.deal(address(charter), 100 ether);

        // Fund owner and charterer with some Ether
        vm.deal(owner, 20 ether);
        vm.deal(charterer, 20 ether);

        // Owner lists a ship
        vm.prank(owner);
        charter.listShip{value: price}(shipId, price);
        
        // Charterer charters the ship
        vm.prank(charterer);
        charter.charterShip{value: price}(shipId);
    }

    function testCloseCharter_ReimburseCharterer_PayOwner_ReleaseStake() public {
        // Capture initial balances
        uint256 initialContractBalance = address(charter).balance;
        uint256 initialChartererBalance = charterer.balance;
        uint256 initialOwnerBalance = owner.balance;

        console.log("Initial contract balance:", initialContractBalance);
        console.log("Initial charterer balance:", initialChartererBalance);
        console.log("Initial owner balance:", initialOwnerBalance);

        // Close the charter
        vm.prank(owner);
        charter.closeCharter(shipId, true, true, true);

        // Check final balances
        uint256 finalContractBalance = address(charter).balance;
        uint256 finalChartererBalance = charterer.balance;
        uint256 finalOwnerBalance = owner.balance;

        console.log("Final contract balance:", finalContractBalance);
        console.log("Final charterer balance:", finalChartererBalance);
        console.log("Final owner balance:", finalOwnerBalance);

        // Assertions
        assertEq(finalChartererBalance, initialChartererBalance + price, "Charterer should be reimbursed");
        assertEq(finalOwnerBalance, initialOwnerBalance + price, "Owner should be paid twice the price");
        assertEq(finalContractBalance, initialContractBalance - price * 2, "Contract balance should decrease by twice the price");
    }

    function testCloseCharter_ReimburseChartererOnly() public {
        uint256 chartererBalanceBefore = charterer.balance;

        vm.prank(address(this));
        charter.closeCharter(shipId, true, false, false);

        uint256 chartererBalanceAfter = charterer.balance;

        assertEq(chartererBalanceAfter, chartererBalanceBefore + price, "Charterer should be reimbursed");
    }

    function testCloseCharter_PayOwnerOnly() public {
        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(address(this));
        charter.closeCharter(shipId, false, true, false);

        uint256 ownerBalanceAfter = owner.balance;

        assertEq(ownerBalanceAfter, ownerBalanceBefore + price, "Owner should be paid");
    }

    function testCloseCharter_ReleaseStakeOnly() public {
        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(address(this));
        charter.closeCharter(shipId, false, false, true);

        uint256 ownerBalanceAfter = owner.balance;

        assertEq(ownerBalanceAfter, ownerBalanceBefore + price, "Owner's stake should be released");
    }
}
