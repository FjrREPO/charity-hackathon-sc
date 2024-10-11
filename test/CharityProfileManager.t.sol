// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/CharityNFT.sol";
import "../src/MockZKVerifier.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CharityProfileManager} from "../src/CharityProfileManager.sol";

// Mock USDC token to simulate token transactions
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract CharityProfileManagerTest is Test {
    CharityProfileManager public charityProfileManager;
    CharityNFT public charityNFT;
    MockUSDC public usdc;
    MockZKVerifier public zkVerifier;

    address public owner = address(0xABCD);
    address public donor1 = address(0x1234);
    address public donor2 = address(0x5678);
    uint256 public initialUSDCBalance = 1000 * 10 ** 18;

    function setUp() public {
        // Deploy mock USDC token
        usdc = new MockUSDC();
        usdc.mint(donor1, initialUSDCBalance);
        usdc.mint(donor2, initialUSDCBalance);

        // Deploy the CharityNFT contract
        charityNFT = new CharityNFT("https://example.com/nft/", owner);

        // Deploy MockZKVerifier
        zkVerifier = new MockZKVerifier();

        // Deploy CharityProfileManager contract
        charityProfileManager = new CharityProfileManager(
            address(usdc),
            address(charityNFT),
            owner
        );

        // Set approval for USDC transfers
        vm.prank(donor1);
        usdc.approve(address(charityProfileManager), initialUSDCBalance);

        vm.prank(donor2);
        usdc.approve(address(charityProfileManager), initialUSDCBalance);
    }

    function testCharityInfo() public {
        // Check charity information
        CharityProfileManager.CharityInfo
            memory charityInfo = charityProfileManager.getCharityInfo();

        assertEq(charityInfo.name, "Example Charity");
        assertEq(charityInfo.foundation, "Example Foundation");
        assertEq(charityInfo.source, "Example Source");
        assertEq(charityInfo.price, 5);
        assertEq(charityInfo.image, "https://examplecharity.org/logo.png");
    }

    function testDonateUSDC() public {
        uint256 donationAmount = 10 * 10 ** 18;

        // Simulate donor1 making a donation
        vm.prank(donor1);
        charityProfileManager.donate(donationAmount);

        // Check if the donation was recorded
        (uint256 amount, bool isVerified, ) = charityProfileManager.donations(
            donor1
        );
        assertEq(amount, donationAmount);
        assertFalse(isVerified);

        // Check if the donor was added to the donor list
        (address[] memory donorAddresses, , ) = charityProfileManager
            .getAllDonations();
        assertEq(donorAddresses[0], donor1);
    }

    function testMintDonationNFT() public {
        uint256 donationAmount = 50 * 10 ** 18;

        // Simulate donor1 making a donation
        vm.prank(donor1);
        charityProfileManager.donate(donationAmount);

        // Verify the NFT was minted
        uint256 tokenId = charityNFT.nextTokenId() - 1;
        assertEq(charityNFT.ownerOf(tokenId), donor1);

        // Verify the tokenURI includes the correct donation amount
        string memory tokenURI = charityNFT.tokenURI(tokenId);
        assertTrue(bytes(tokenURI).length > 0);
        assertTrue(
            keccak256(abi.encodePacked(tokenURI)) !=
                keccak256(abi.encodePacked(""))
        );
    }

    function testVerifyDonation() public {
        uint256 donationAmount = 200 * 10 ** 18;
        string memory invoiceId = "12345-INV";

        // Simulate donor2 making a donation
        vm.prank(donor2);
        charityProfileManager.donate(donationAmount);

        // Check if the donation was recorded
        (uint256 amount, bool isVerifiedBefore, ) = charityProfileManager
            .donations(donor2);
        assertEq(amount, donationAmount);
        assertFalse(isVerifiedBefore);

        vm.prank(donor2);
        charityProfileManager.verifyDonation(invoiceId);

        // (
        //     uint256 amountAfter,
        //     bool isVerifiedAfter,
        //     string memory recordedInvoiceId
        // ) = charityProfileManager.donations(donor2);
        // assertTrue(isVerifiedAfter);
        // assertEq(recordedInvoiceId, invoiceId);

        // uint256 invoiceTokenId = charityNFT.getInvoiceNFT(donor2);
        // assertEq(charityNFT.ownerOf(invoiceTokenId), donor2);

        // string memory tokenURI = charityNFT.tokenURI(invoiceTokenId);
        // assertTrue(bytes(tokenURI).length > 0);
        // assertEq(amountAfter, donationAmount);
    }

    function testGetAllDonations() public {
        uint256 donationAmount1 = 100 * 10 ** 18;
        uint256 donationAmount2 = 150 * 10 ** 18;

        // Simulate donor1 and donor2 making donations
        vm.prank(donor1);
        charityProfileManager.donate(donationAmount1);

        vm.prank(donor2);
        charityProfileManager.donate(donationAmount2);

        // Retrieve all donations
        (
            address[] memory donorAddresses,
            uint256[] memory donationAmounts,
            bool[] memory isVerifiedStatuses
        ) = charityProfileManager.getAllDonations();

        // Check if the donations are correctly recorded
        assertEq(donorAddresses.length, 2);
        assertEq(donorAddresses[0], donor1);
        assertEq(donorAddresses[1], donor2);

        assertEq(donationAmounts[0], donationAmount1);
        assertEq(donationAmounts[1], donationAmount2);

        assertFalse(isVerifiedStatuses[0]);
        assertFalse(isVerifiedStatuses[1]);
    }
}
