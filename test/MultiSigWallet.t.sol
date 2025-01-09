pragma solidity ^0.8.25;

import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import { Test } from "forge-std/Test.sol";

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

        assertEq(multiSigWallet.minNumberConfirmationsRequired(), 2);
    }

    function testConstructorAssignsAddresses() public {
        address[] memory addresses = new address[](4);
        addresses[0] = USER1;
        addresses[1] = USER2;
        addresses[2] = USER3;
        addresses[3] = USER4;

        multiSigWallet = new MultiSigWallet(addresses);

        for (uint i = 0; i < addresses.length; i++) {
            assertTrue(multiSigWallet.isOwner(addresses[i]));
        }

        address[] memory owners = multiSigWallet.getOwners();
        for (uint i = 0; i < owners.length; i++) {
            assertEq(owners[i], addresses[i]);
        }
    }

    function testConstructorFailsWithEmptyAddresses() public {
        address[] memory addresses = new address[](0);

        vm.expectRevert("3 address required");
        new MultiSigWallet(addresses);
    }


    function testOnlyOwnerCannotSubmitTransaction() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);
        address nonOwner = address(0x0);

        vm.prank(nonOwner);
        vm.expectRevert("not owner");
        multiSigWallet.submitTransaction(USER2, 100);
    }

    function testOnlyOwnerCannotExecuteTransaction() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER3);
        multiSigWallet.confirmTransaction(0);

        address nonOwner = address(0xdead);
        vm.prank(nonOwner);
        vm.expectRevert("not owner");
        multiSigWallet.executeTransaction(0);
    }

    function testConfirmTransactionFailsNonExistentTx() public {
        vm.prank(USER1);
        vm.expectRevert("tx does not exist");
        multiSigWallet.confirmTransaction(999);
    }

    function testConstructorAssignsAddresses2() public {
        address[] memory addresses = new address[](4);
        addresses[0] = USER1;
        addresses[1] = USER2;
        addresses[2] = USER3;
        addresses[3] = USER4;

        MultiSigWallet wallet = new MultiSigWallet(addresses);

        assertTrue(wallet.isOwner(USER1));
        assertTrue(wallet.isOwner(USER2));
        assertTrue(wallet.isOwner(USER3));
        assertTrue(wallet.isOwner(USER4));
    }

    function testConstructorFailsWithDuplicateOwners() public {
        address[] memory addresses = new address[](4);
        addresses[0] = USER1;
        addresses[1] = USER2;
        addresses[2] = USER1;
        addresses[3] = USER4;

        vm.expectRevert("owner not unique");
        new MultiSigWallet(addresses);
    }


    function testConstructorFail() public {
        address[] memory addresses = new address[](3);
        addresses[0] = USER1;
        addresses[1] = USER2;
        addresses[2] = USER3;

        vm.expectRevert("3 address required");
        new MultiSigWallet(addresses);
    }

    function testSubmitTransaction() public {
        vm.prank(USER1);

        multiSigWallet.submitTransaction(USER2, 100);

        (address from, address to, uint256 amount, bool executed, uint256 numConfirmations) = multiSigWallet.transactions(0);
        assertEq(from, USER1);
        assertEq(to, USER2);
        assertEq(amount, 100);
        assertFalse(executed);
        assertEq(numConfirmations, 2);
    }

    function testOnlyOwnerCanSubmitTransaction() public {
        address nonOwner = address(0x8);
        vm.prank(nonOwner);

        vm.expectRevert("not owner");
        multiSigWallet.submitTransaction(USER2, 100);
    }

    function testEmitEventOnSubmitTransaction() public {
        vm.prank(USER1);

        vm.expectEmit(true, true, true, true);
        emit MultiSigWallet.SubmitTransaction(USER1, 0, 100, address(multiSigWallet).balance);

        multiSigWallet.submitTransaction(USER2, 100);
    }

    function testConfirmTransaction() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);


        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        (, , , , uint256 numConfirmations) = multiSigWallet.transactions(0);
        assertEq(numConfirmations, 3);
        assertTrue(multiSigWallet.isConfirmed(0, USER2));
    }

    function testCannotConfirmTransactionTwice() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        vm.expectRevert();
        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);
    }

    function testOnlyOwnerCanConfirmTransaction() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        address nonOwner = address(0x8);
        vm.prank(nonOwner);

        vm.expectRevert("not owner");
        multiSigWallet.confirmTransaction(0);
    }

    function testTxExistsModifier() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER1);
        vm.expectRevert("tx does not exist");
        multiSigWallet.confirmTransaction(1);
    }

    function testCannotExecuteWithoutEnoughConfirmations() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        (, , , bool executed, ) = multiSigWallet.transactions(0);
        assertFalse(executed);
    }

    function testExecuteTransactionFailsTxCallDead() public {
        address nonPayableAddress = address(0xdead);

        vm.prank(USER1);
        multiSigWallet.submitTransaction(nonPayableAddress, 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER3);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER1);
        vm.expectRevert("tx failed");
        multiSigWallet.executeTransaction(0);
    }

    function testRevokeTransactionSuccess() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER2);
        multiSigWallet.revokeTransaction(0);

        (, , , , uint256 numConfirmations) = multiSigWallet.transactions(0);
        assertEq(numConfirmations, 2);
        assertFalse(multiSigWallet.isConfirmed(0, USER2));
    }

    function testRevokeTransactionFailsIfNotConfirmed() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER2);
        vm.expectRevert("tx not confirmed");
        multiSigWallet.revokeTransaction(0);
    }

    function testEmitEventOnRevokeTransaction() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER2);
        vm.expectEmit(true, true, false, false);
        emit MultiSigWallet.RevokeTransaction(USER2, 0);
        multiSigWallet.revokeTransaction(0);
    }

    function testGetTransactionsCount() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        assertEq(multiSigWallet.getTransactionsCount(), 1);
    }


    function testGetTransaction() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        (address from, address to, uint256 amount, bool executed, uint256 numConfirmations) = multiSigWallet.getTransaction(0);
        assertEq(from, USER1);
        assertEq(to, USER2);
        assertEq(amount, 100);
        assertFalse(executed);
        assertEq(numConfirmations, 2);
    }

    function testTransactionConfirmationStates() public {
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);
        assertTrue(multiSigWallet.isConfirmed(0, USER2));

        vm.expectRevert("tx already confirmed");
        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER3);
        multiSigWallet.confirmTransaction(0);
        assertTrue(multiSigWallet.isConfirmed(0, USER3));

        assertFalse(multiSigWallet.isConfirmed(0, USER4));
    }

    function testConfirmNonExistentTransaction() public {
        vm.expectRevert("tx does not exist");
        vm.prank(USER1);
        multiSigWallet.confirmTransaction(999);
    }

    function testExecuteTransactionFailsTxCall() public {

        vm.prank(USER1);
        multiSigWallet.submitTransaction(address(0x0), 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER3);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER1);
        vm.expectRevert("tx failed");
        multiSigWallet.executeTransaction(0);
    }

    function testTxNotExecuted() public {
        vm.deal(address(multiSigWallet), 200);
        vm.prank(USER1);
        multiSigWallet.submitTransaction(USER2, 100);

        vm.prank(USER2);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER3);
        multiSigWallet.confirmTransaction(0);

        vm.prank(USER1);
        multiSigWallet.executeTransaction(0);

        vm.prank(USER1);
        vm.expectRevert("tx already executed");
        multiSigWallet.executeTransaction(0);
    }
}