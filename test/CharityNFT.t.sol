// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/CharityNFT.sol"; // Assuming the CharityNFT contract is located in the src folder

contract CharityNFTTest is Test {
    CharityNFT public charityNFT;
    address public owner = address(1);
    address public donor = address(2);
    address public nonOwner = address(3); // A non-owner account

    string public baseURI = "https://example.com/nft/";

    function setUp() public {
        // Deploy the CharityNFT contract with the base URI
        charityNFT = new CharityNFT(baseURI, owner);
    }

    /// @dev Test initial contract setup and ownership.
    function testContractSetup() public {
        // Check the owner is correctly set
        assertEq(charityNFT.owner(), owner);

        // Check the baseTokenURI is set correctly
        assertEq(charityNFT.baseTokenURI(), baseURI);

        // Check the nextTokenId is initialized to 0
        assertEq(charityNFT.nextTokenId(), 0);
    }

    /// @dev Test donation and NFT minting for the first donation.
    function testMintNFTForDonation() public {
        // Owner records a donation of 1 ether for the donor
        vm.prank(owner);
        charityNFT.recordDonation(donor, 1 ether);

        // Verify that the NFT is minted to the donor
        assertEq(charityNFT.ownerOf(0), donor);

        // Verify that the nextTokenId increments
        assertEq(charityNFT.nextTokenId(), 1);

        // Verify the token URI is generated correctly
        string memory expectedTokenURI = string(
            abi.encodePacked(baseURI, "0.json?donation=1000000000000000000")
        );
        assertEq(charityNFT.tokenURI(0), expectedTokenURI);

        // Check that the total donation amount is updated for the donor
        assertEq(charityNFT.getDonations(donor), 1 ether);
    }

    function testMultipleDonations() public {
        // First donation by donor
        vm.prank(owner);
        charityNFT.recordDonation(donor, 1 ether);

        // Verify that the first NFT is minted
        assertEq(charityNFT.ownerOf(0), donor);
        assertEq(charityNFT.getDonations(donor), 1 ether);

        // Second donation by donor
        vm.prank(owner);
        charityNFT.recordDonation(donor, 2 ether);

        // Verify that the second NFT is minted
        assertEq(charityNFT.ownerOf(1), donor);
        assertEq(charityNFT.getDonations(donor), 3 ether); // Total donations

        // Verify token URI of the second NFT
        string memory expectedTokenURI = string(
            abi.encodePacked(baseURI, "1.json?donation=2000000000000000000")
        );
        assertEq(charityNFT.tokenURI(1), expectedTokenURI);

        // Check nextTokenId increments correctly
        assertEq(charityNFT.nextTokenId(), 2);
    }


    function testSetBaseTokenURI() public {
        // New base URI
        string memory newBaseURI = "https://newexample.com/nft/";

        // Only owner should be able to update the base URI
        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(nonOwner)
            )
        );
        charityNFT.setBaseTokenURI(newBaseURI);

        vm.prank(owner);
        charityNFT.setBaseTokenURI(newBaseURI);

        // Verify that the base URI is updated
        assertEq(charityNFT.baseTokenURI(), newBaseURI);

        // Mint an NFT and check that the new base URI is used
        vm.prank(owner);
        charityNFT.recordDonation(donor, 1 ether);

        string memory expectedTokenURI = string(
            abi.encodePacked(newBaseURI, "0.json?donation=1000000000000000000")
        );
        assertEq(charityNFT.tokenURI(0), expectedTokenURI);
    }
}
