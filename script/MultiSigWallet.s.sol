// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract MultiSigWalletScript is Script {

    function testA() public {}

    function run() external {
        // Définir les propriétaires
        // Démarrer le broadcast
        vm.startBroadcast();

        address[] memory owners = new address[](4);
        owners[0] = address(0x4);
        owners[1] = address(0x5);
        owners[2] = address(0x6);
        owners[3] = address(0x7);

        // Déployer le contrat
        MultiSigWallet wallet = new MultiSigWallet(owners);

        vm.stopBroadcast();

        // Log l'adresse du contrat déployé
        console.log("MultiSigWallet deployed at:", address(wallet));
    }
}