# DonationProof Smart Contract

A Solidity smart contract that enables verifiable donations using USDC with marketplace proof verification through Reclaim Protocol.

## Overview

DonationProof is a smart contract that allows users to make donations in USDC for specific products while providing a mechanism to verify these donations through marketplace proofs. The contract integrates with the Reclaim Protocol for proof verification and maintains a record of all donations and their verification status.

## Features

- Make donations in USDC for predefined products
- Verify donations using Reclaim Protocol proofs
- Track donation transactions with marketplace IDs
- Admin controls for product management
- Secure withdrawal mechanism for collected donations

## Contract Details

- License: UNLICENSED
- Solidity Version: ^0.8.20
- USDC Contract (Mainnet): `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
- Reclaim Address: `0x8CDc031d5B7F148ab0435028B16c682c469CEfC3`

## Key Structures

### Transaction
```solidity
struct Transaction {
    address account;        // Donor's address
    uint256 productId;      // ID of the donated product
    uint256 timestamp;      // Timestamp of the donation
    uint256 marketplaceId;  // Associated marketplace ID
    bool proved;            // Verification status
    string link;           // Additional reference link
}
```

## Main Functions

### donate
```solidity
function donate(uint256 productId) external
```
Makes a donation for a specific product by transferring USDC from the sender.

### proveDonation
```solidity
function proveDonation(uint256 transactionId, uint256 marketplaceId, Reclaim.Proof memory proof) external
```
Verifies a donation using Reclaim Protocol proof and marketplace ID.

### Administrative Functions

- `setProduct(uint256 id, uint256 price)`: Set product price (owner only)
- `removeProduct(uint256 id)`: Remove a product (owner only)
- `withdrawDonation()`: Withdraw collected USDC (owner only)

## Usage

1. **Making a Donation**
```solidity
// Approve USDC spending first
usdc.approve(contractAddress, amount);

// Make donation
donationProof.donate(productId);
```

2. **Proving a Donation**
```solidity
// Verify donation with Reclaim proof
donationProof.proveDonation(transactionId, marketplaceId, proof);
```

## Security Features

- Uses OpenZeppelin's SafeERC20 for secure token transfers
- Implements Ownable pattern for access control
- Prevents double-claiming with marketplace IDs
- Input validation for proof verification

## Dependencies

- OpenZeppelin Contracts
  - `@openzeppelin/contracts/access/Ownable.sol`
  - `@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol`
  - `@openzeppelin/contracts/token/ERC20/IERC20.sol`
- Reclaim Protocol Integration
  - `./reclaim/Reclaim.sol`
  - `./reclaim/Claims.sol`

## Development and Testing

1. Clone the repository
2. Install dependencies:
```bash
npm install
```
3. Run tests:
```bash
npx hardhat test
```

## License

UNLICENSED

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Disclaimer

This smart contract is provided as-is. Users should perform their own security audits before deployment.