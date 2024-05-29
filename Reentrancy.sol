// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {IFP_Shop_reentrancy} from "./interfaces/IFP_Shop_reentrancy.sol";

//based on https://solidity-by-example.org/hacks/re-entrancy/

contract Reentrancy {
    IFP_Shop_reentrancy public shop;
    //address shopAddress;
    uint256 public constant AMOUNT = 1 ether;

    constructor(address _shopAddress) {
        shop = IFP_Shop_reentrancy(_shopAddress);
        //shopAddress = _shopAddress; (?)
    }

    /** (?)
    // Fallback is called when EtherStore sends Ether to this contract.
    fallback() external payable {
        if (address(etherStore).balance >= AMOUNT) {
            etherStore.withdraw();
        }
    }
    */

    function attack() external payable {
        //require(msg.value >= AMOUNT); (?)
        //etherStore.deposit{value: AMOUNT}();
        //etherStore.withdraw();
        //shop.closeSale(shopAddress.offerIndex-1, false, true, true);
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        if(address(tx.origin).balance >= 1 ether) {
            //shop.closeSale(shopAddress.offerIndex-1, false, true, true);
        }
    }
}