// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title CharityNFT
 * @dev NFT contract that mints tokens for users who donate to a charity platform.
 * Each donation mints a new NFT with metadata reflecting the donation amount.
 */
contract CharityNFT is ERC721URIStorage, Ownable {
    using Strings for uint256;

    uint256 public nextTokenId;
    string public baseTokenURI;

    mapping(uint256 => uint256) public donationToCharity;

    error DonationAmountMustBeGreaterThanZero();
    error TokenDoesNotExist();

    // Mapping to store the total donations made by an address
    mapping(address => uint256) private donations;

    // Mapping to store invoice NFTs
    mapping(address => uint256) public invoiceNFTs;

    /**
     * @dev Constructor initializes the contract with a base URI for the NFT metadata.
     * @param _baseTokenURI The base URI for token metadata.
     */
    constructor(
        string memory _baseTokenURI,
        address _initialOwner
    ) Ownable(_initialOwner) ERC721("CharityNFT", "CNFT") {
        baseTokenURI = _baseTokenURI;
    }
    /**
     * @dev Records a donation and mints an NFT for each donation made by the donor.
     * @param _donor The address of the donor.
     * @param _amount The amount of the donation (in wei).
     */

    function recordDonation(
        address _donor,
        uint256 _amount
    ) external returns (uint256) {
        if (_amount == 0) {
            revert DonationAmountMustBeGreaterThanZero();
        }

        // Record the donation
        donations[_donor] += _amount;

        // Mint an NFT reflecting the donation
        return mintNFT(_donor, _amount);
    }

    /**
     * @dev Mints an NFT to a donor.
     * @param _to The address to mint the NFT to.
     * @param _donationAmount The donation amount to include in the NFT metadata.
     */
    function mintNFT(
        address _to,
        uint256 _donationAmount
    ) private returns (uint256) {
        uint256 tokenId = nextTokenId;
        nextTokenId++;

        _safeMint(_to, tokenId);

        // Create dynamic token URI with metadata that includes donation amount
        string memory tokenURIwithMetadata = string(
            abi.encodePacked(
                baseTokenURI,
                tokenId.toString(),
                ".json?donation=",
                _donationAmount.toString()
            )
        );

        _setTokenURI(tokenId, tokenURIwithMetadata);

        return tokenId;
    }

    /**
     * @dev Mints an invoice NFT to the donor after zk-proof verification.
     * @param _to The address to mint the NFT to.
     * @param _invoiceId The invoice ID to include in the NFT metadata.
     * @return The token ID of the minted invoice NFT.
     */
    function mintInvoiceNFT(
        address _to,
        string calldata _invoiceId
    ) external returns (uint256) {
        uint256 tokenId = nextTokenId;
        nextTokenId++;

        _safeMint(_to, tokenId);

        // Create dynamic token URI with metadata that includes the invoice ID
        string memory invoiceTokenURI = string(
            abi.encodePacked(
                baseTokenURI,
                tokenId.toString(),
                ".json?invoiceId=",
                _invoiceId
            )
        );

        _setTokenURI(tokenId, invoiceTokenURI);

        // Store the token ID as the invoice NFT for the donor
        invoiceNFTs[_to] = tokenId;

        return tokenId;
    }

    /**
     * @dev Updates the base URI for all token metadata.
     * @param _newBaseTokenURI The new base URI for token metadata.
     */
    function setBaseTokenURI(
        string memory _newBaseTokenURI
    ) external onlyOwner {
        baseTokenURI = _newBaseTokenURI;
    }

    /**
     * @dev Retrieves the token URI for a given tokenId.
     * @param tokenId The ID of the token whose URI you want to fetch.
     * @return A string representing the full token URI.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert TokenDoesNotExist();
        }
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Retrieves the total donations made by an address.
     * @param _donor The address of the donor.
     * @return The total donation amount made by the donor.
     */

    function getDonations(address _donor) external view returns (uint256) {
        return donations[_donor];
    }


    function getInvoiceNFT(address _donor) external view returns (uint256) {
        return invoiceNFTs[_donor];
    }
}
