// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MockZKVerifier {
    address public reclaimAddress;
    string[] public providersHashes;

    // Event to mock proof verification result
    event ProofVerified(bool success);

    // Constructor to initialize provider hashes and reclaim address
    constructor() // string[] memory _providersHashes
    {
        //   providersHashes = _providersHashes;
        reclaimAddress = 0xF90085f5Fd1a3bEb8678623409b3811eCeC5f6A5;
    }

    // Struct to mock a proof (you can adapt fields as needed for the mock)
    struct MockProof {
        bytes32 proofData; // Mock proof data
        address userAddress; // Mock user data for verification
    }

    // Mock verifyProof function
    function verifyProof(MockProof memory proof) public pure returns (bool) {
        if (proof.proofData == bytes32(0) || proof.userAddress == address(0)) {
            return false;
        }
        return true;
    }

    // Public function to imitate proof verification and emit event
    function verifyProofAndEmit(MockProof memory proof) public {
        bool result = verifyProof(proof);
        emit ProofVerified(result);
    }
}
