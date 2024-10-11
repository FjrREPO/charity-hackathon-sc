// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/MockZKVerifier.sol"; // Path to your contract file

contract MockZKVerifierTest is Test {
    MockZKVerifier public mockZKVerifier;

    event ProofVerified(bool success);

    // Setup the environment and deploy the contract before running tests
    function setUp() public {
        mockZKVerifier = new MockZKVerifier();
    }

    // Test 3: Verify the mock proof (basic success check)
    function testVerifyProof() public view {
        MockZKVerifier.MockProof memory proof = MockZKVerifier.MockProof({
            proofData: "0x1234",
            userAddress: address(0x1234)
        });

        bool result = mockZKVerifier.verifyProof(proof);
        assertTrue(result);
    }
}
