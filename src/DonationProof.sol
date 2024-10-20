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
    string public constant providersHash = "0x16a7dd86fdd3d499d35ebbcf99bb70097840ffd0aa079d954a0985cd1abb5f67";

    IERC20 public constant usdc = IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e);

    uint256 public currentTransactionId = 0;

    // id product => price in USDC
    mapping(uint256 => uint256) public products;

    // transaction id => transaction
    mapping(uint256 => Transaction) public donations;

    mapping(uint256 => bool) public hasClaimed;

    // Events for better tracking
    event DonationProved(uint256 indexed transactionId, uint256 marketplaceId);
    event DonationMade(uint256 indexed transactionId, address donor, uint256 productId, uint256 amount);

    constructor() Ownable(msg.sender) {
        // add sample
        products[1] = 10;
    }

    function donate(uint256 productId) external {
        uint256 price = products[productId];
        require(price > 0, "Product does not exist");
        
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

        emit DonationMade(currentTransactionId, msg.sender, productId, price);
    }

    function proveDonation(uint256 transactionId, uint256 marketplaceId, Reclaim.Proof memory proof) external {
        // Input validation
        require(transactionId > 0 && transactionId <= currentTransactionId, "Invalid transaction ID");
        
        Transaction storage transaction = donations[transactionId];
        require(transaction.account != address(0), "Transaction not found");
        require(!transaction.proved, "Already proved");
        require(!hasClaimed[marketplaceId], "Marketplace Id already used");
        
        // Verify the proof and get the marketplace ID
        uint256 verifiedId = verifyProof(proof);
        require(verifiedId == marketplaceId, "Marketplace ID mismatch with proof");

        // Update state
        hasClaimed[marketplaceId] = true;
        transaction.marketplaceId = marketplaceId;
        transaction.proved = true;

        emit DonationProved(transactionId, marketplaceId);
    }

    function verifyProof(Reclaim.Proof memory proof) public view returns (uint256) {
        // Verify the proof with Reclaim contract
        try Reclaim(reclaimAddress).verifyProof(proof) {
            // Verify provider hash
            string memory submittedProviderHash = 
                Claims.extractFieldFromContext(proof.claimInfo.context, '"providerHash":"');
            
            require(
                keccak256(abi.encodePacked(submittedProviderHash)) == keccak256(abi.encodePacked(providersHash)),
                "Invalid provider hash"
            );

            // Extract and return the ID
            string memory id = Claims.extractFieldFromContext(proof.claimInfo.context, '"id":"');
            return stringToUint(id);
        } catch {
            revert("Proof verification failed");
        }
    }

    function setProduct(uint256 id, uint256 price) external onlyOwner {
        require(id > 0, "Invalid product ID");
        require(price > 0, "Invalid price");
        products[id] = price;
    }

    function removeProduct(uint256 id) external onlyOwner {
        require(products[id] > 0, "Product does not exist");
        delete products[id];
    }

    function withdrawDonation() external onlyOwner {
        uint256 balance = usdc.balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");
        usdc.transfer(owner(), balance);
    }

    function stringToUint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        require(b.length > 0, "Empty string");
        
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            require(b[i] >= 0x30 && b[i] <= 0x39, "Invalid character found");
            result = result * 10 + (uint256(uint8(b[i])) - 48);
        }
        return result;
    }
}