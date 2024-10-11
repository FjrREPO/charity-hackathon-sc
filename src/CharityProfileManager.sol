// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CharityNFT} from "./CharityNFT.sol";
import {MockZKVerifier} from "./MockZKVerifier.sol";
import "forge-std/Console.sol";

/**
 * @title CharityProfileManager
 * @dev A contract that allows donations using USDC, with NFT rewards for donation and proof verification.
 * This version uses a hardcoded charity with CharityInfo structure.
 */
contract CharityProfileManager is Ownable {
    /// @notice Charity information structure
    struct CharityInfo {
        string link; // Charity website or info link
        uint256 date; // Registration date or relevant date
        string name; // List of name/services offered by the charity
        string foundation; // Name of the foundation or charity organization
        string source; // Additional source or metadata for validation
        uint256 price; // Price or cost associated with the charity's cause
        string image; // Image link associated with the charity (e.g., logo)
    }

    /// @notice Donation information structure
    struct Donation {
        uint256 amount;
        bool isVerified;
        string invoiceId;
    }

    /// @notice USDC token contract
    IERC20 public immutable usdc;

    /// @notice NFT contract to issue NFTs upon donation and proof verification
    CharityNFT public donationNFT;

    /// @notice zkVerifier contract for proof verification
    MockZKVerifier public zkVerifier;

    /// @notice Charity information for the hardcoded charity
    CharityInfo public charityInfo;

    /// @notice Mapping from (donor address => donation)
    mapping(address => Donation) public donations;

    /// @notice List of donors for the charity
    address[] public charityDonors;

    /// @notice Event emitted when a donation is made
    event DonationMade(address indexed donor, uint256 amount, uint256 tokenId);

    /// @notice Event emitted when a donation is verified
    event DonationVerified(
        address indexed donor,
        string invoiceId,
        uint256 tokenId
    );

    /**
     * @dev Constructor to initialize the contract with USDC token, CharityNFT contract, and charity info.
     * @param _usdc Address of the USDC token contract.
     * @param _donationNFT Address of the deployed CharityNFT contract.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(
        address _usdc,
        address _donationNFT,
        address _initialOwner
    ) Ownable(_initialOwner) {
        usdc = IERC20(_usdc);
        donationNFT = CharityNFT(_donationNFT);
        zkVerifier = new MockZKVerifier(); // Assuming you have zkVerifier already implemented

        // Initialize the charity information (hardcoded to charityId = 1)
        charityInfo = CharityInfo({
            link: "https://examplecharity.org",
            date: block.timestamp,
            name: "Example Charity",
            foundation: "Example Foundation",
            source: "Example Source",
            price: 5,
            image: "https://examplecharity.org/logo.png"
        });
    }

    /**
     * @notice Donate USDC to the hardcoded charity.
     * @dev Donors must approve the contract to transfer USDC before calling this function.
     * @param amount The amount of USDC to donate.
     */
    function donate(uint256 amount) external {
        require(amount > 0, "Donation amount must be greater than zero.");

        // Transfer USDC from the donor to the contract owner
        bool success = usdc.transferFrom(msg.sender, owner(), amount);
        require(success, "USDC transfer failed.");

        // Record the donation
        donations[msg.sender] = Donation({
            amount: amount,
            isVerified: false,
            invoiceId: ""
        });

        // Add the donor to the list of donors (if not already added)
        if (_isNewDonor(msg.sender)) {
            charityDonors.push(msg.sender);
        }

        // Mint NFT for the donor
        uint256 tokenId = donationNFT.recordDonation(msg.sender, amount);

        emit DonationMade(msg.sender, amount, tokenId);
    }

    /**
     * @notice Verifies the donation using zk-proof and issues an NFT invoice.
     * @dev zkVerifier contract is used to verify the proof of the invoice.
     * @param invoiceId The invoice ID for the donation proof.
     */
    function verifyDonation(string calldata invoiceId) external {
        Donation storage donation = donations[msg.sender];

        // Simulate zk-proof verification (could be a real zk-SNARK integration)
        bool proofVerified = zkVerifier.verifyProof(
            MockZKVerifier.MockProof({
                proofData: "0x1234", // Mock proof data
                userAddress: msg.sender // Mock user data for verification
            })
        );
        console.log("Proof verified: %s", proofVerified);
        require(proofVerified, "Proof verification failed.");

        // Update the donation to mark it as verified
        donation.isVerified = true;
        donation.invoiceId = invoiceId;

        // Mint an NFT invoice for the donor
        uint256 tokenId = donationNFT.mintInvoiceNFT(msg.sender, invoiceId);

        emit DonationVerified(msg.sender, invoiceId, tokenId);
    }

    /**
     * @notice Retrieve all donations for the charity.
     * @return donorAddresses List of donor addresses.
     * @return donationAmounts List of donation amounts.
     * @return isVerifiedStatus List of verification statuses.
     */
    function getAllDonations()
        external
        view
        returns (
            address[] memory donorAddresses,
            uint256[] memory donationAmounts,
            bool[] memory isVerifiedStatus
        )
    {
        uint256 donorCount = charityDonors.length;
        donorAddresses = new address[](donorCount);
        donationAmounts = new uint256[](donorCount);
        isVerifiedStatus = new bool[](donorCount);

        for (uint256 i = 0; i < donorCount; i++) {
            address donor = charityDonors[i];
            donorAddresses[i] = donor;
            donationAmounts[i] = donations[donor].amount;
            isVerifiedStatus[i] = donations[donor].isVerified;
        }

        return (donorAddresses, donationAmounts, isVerifiedStatus);
    }

    /**
     * @notice Get the charity information.
     * @return The CharityInfo struct containing charity details.
     */
    function getCharityInfo() external view returns (CharityInfo memory) {
        return charityInfo;
    }

    /**
     * @notice Checks if an address is a new donor for the charity.
     * @param donor The address of the donor.
     * @return True if the donor is new.
     */
    function _isNewDonor(address donor) internal view returns (bool) {
        for (uint256 i = 0; i < charityDonors.length; i++) {
            if (charityDonors[i] == donor) {
                return false;
            }
        }
        return true;
    }
}
