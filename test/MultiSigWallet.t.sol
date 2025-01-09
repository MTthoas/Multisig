// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {Test} from "forge-std/Test.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multiSigWallet;
    address public constant USER1 = address(0x4);
    address public constant USER2 = address(0x5);
    address public constant USER3 = address(0x6);
    address public constant USER4 = address(0x7);

    function setUp() public {
        address[] memory addresses = new address[](4);
        addresses[0] = USER1;
        addresses[1] = USER2;
        addresses[2] = USER3;
        addresses[3] = USER4;

        multiSigWallet = new MultiSigWallet(addresses);
    }

    function testConstructor() public view {
        assertTrue(multiSigWallet.isOwner(USER1));
        assertTrue(multiSigWallet.isOwner(USER2));
        assertTrue(multiSigWallet.isOwner(USER3));
        assertTrue(multiSigWallet.isOwner(USER4));

        // Vérifier le nombre minimum de confirmations
        assertEq(multiSigWallet.minNumberConfirmationsRequired(), 2);
    }

    function testSubmitTransaction() public {
        vm.prank(USER1);

        // Soumettre une transaction
        multiSigWallet.submitTransaction(USER2, 100);

        // Vérifier que la transaction a été enregistrée
        (address from, address to, uint256 amount) = multiSigWallet.transactions(0);
        assertEq(from, USER1);
        assertEq(to, USER2);
        assertEq(amount, 100);
    }

    function testOnlyOwnerCanSubmitTransaction() public {
        address nonOwner = address(0x8);
        vm.prank(nonOwner);

        // S'assurer que la transaction échoue
        vm.expectRevert("not owner");
        multiSigWallet.submitTransaction(USER2, 100);
    }

    function testEmitEventOnSubmitTransaction() public {
        vm.prank(USER1);

        // Vérifier que l'événement a été émis
        vm.expectEmit(true, true, true, true);
        emit MultiSigWallet.SubmitTransaction(USER1, 0, 100, address(multiSigWallet).balance);

        // Soumettre une transaction
        multiSigWallet.submitTransaction(USER2, 100);

    }


}