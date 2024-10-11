// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {CharityProfileManager} from "../src/CharityProfileManager.sol";
import "../src/CharityNFT.sol";
import "../src/MockZkVerifier.sol";

contract DeployCharityManager is Script {
    function run() external {
        // Start broadcasting the transaction
        vm.startBroadcast();

        // Deploy the CharityNFT contract
        string
            memory baseURI = "https://ipfs.io/ipfs/Qmb17fWh3y7gQN9Rxy8M6MG2T9C8Y5Dfvzzinjdx6c8jne";
        CharityNFT charityNFT = new CharityNFT(baseURI, address(this));
        // sepolia usdc

        // Deploy the CharityProfileManager contract with the CharityNFT address
        new CharityProfileManager(
            address(0x5dEaC602762362FE5f135FA5904351916053cF70),
            address(charityNFT),
            address(this)
        );

        // Stop broadcasting the transaction
        vm.stopBroadcast();
    }
}
