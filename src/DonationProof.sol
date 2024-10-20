// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Reclaim} from "./reclaim/Reclaim.sol";
import {Claims} from "./reclaim/Claims.sol";

contract DonationProof is Ownable {
    using SafeERC20 for IERC20;

    struct Transaction {
        address account;
        uint256 productId;
        uint256 timestamp;
        uint256 marketplaceId;
        bool proved;
        string link;
    }

    // reclaim
    address public constant reclaimAddress = 0x8CDc031d5B7F148ab0435028B16c682c469CEfC3;
    string public constant providersHash = "0xe65e58b4dc46bef908b71f131bf92daf5afe0ee5e5f6e81dc73473063f1a6551";

    IERC20 public constant usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

    uint256 public currentTransactionId = 0;

    // id product => price in USDC
    mapping(uint256 => uint256) public products;

    // transaction id => transaction
    mapping(uint256 => Transaction) public donations;

    mapping(uint256 => bool) public hasClaimed;

    constructor() Ownable(msg.sender) {
        // add sample
        products[1] = 10;
    }

    function donate(uint256 productId) external {
        uint256 price = products[productId];
        usdc.safeTransferFrom(msg.sender, address(this), price);

        currentTransactionId += 1;

        donations[currentTransactionId] = Transaction({
            account: msg.sender,
            productId: productId,
            timestamp: block.timestamp,
            marketplaceId: 0,
            proved: false,
            link: ""
        });
    }

    function proveDonation(uint256 transactionId, uint256 marketplaceId, Reclaim.Proof memory proof) external {
        Transaction storage transaction = donations[transactionId];
        require(transaction.account != address(0), "Transaction not found");
        require(transaction.proved == false, "Already proved");
        require(!hasClaimed[marketplaceId], "Marketplace Id already used");
        verifyProof(proof);

        hasClaimed[marketplaceId] = true;
        transaction.marketplaceId = marketplaceId;
        transaction.proved = true;
    }

    function verifyProof(Reclaim.Proof memory proof) public view returns (uint256) {
        Reclaim(reclaimAddress).verifyProof(proof);

        // // check if providerHash is valid
        // string memory submittedProviderHash =
        //     Claims.extractFieldFromContext(proof.claimInfo.context, '"providerHash":"');

        // // compare two strings
        // require(
        //     keccak256(abi.encodePacked(submittedProviderHash)) == keccak256(abi.encodePacked(providersHash)),
        //     "Invalid ProviderHash"
        // );

        string memory id = Claims.extractFieldFromContext(proof.claimInfo.context, '"id":"');

        return stringToUint((id));
    }

    function setProduct(uint256 id, uint256 price) external onlyOwner {
        products[id] = price;
    }

    function removeProduct(uint256 id) external onlyOwner {
        delete products[id];
    }

    function withdrawDonation() external onlyOwner {
        usdc.transfer(owner(), usdc.balanceOf(address(this)));
    }

    function stringToUint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            // Check that each character is a valid digit between 0 and 9
            require(b[i] >= 0x30 && b[i] <= 0x39, "Invalid character found.");
            result = result * 10 + (uint256(uint8(b[i])) - 48); // ASCII '0' is 48
        }
        return result;
    }
}