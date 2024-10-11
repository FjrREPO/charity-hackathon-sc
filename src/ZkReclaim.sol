// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "lib/reclaim-solidity-sdk/contracts/Reclaim.sol";

contract Attestor {
    address public reclaimAddress;

    constructor() {
        // TODO: Replace with network you are deploying on
        reclaimAddress = 0xF90085f5Fd1a3bEb8678623409b3811eCeC5f6A5;
    }

    function verifyProof(Reclaim.Proof memory proof) public returns (bool) {
        Reclaim(reclaimAddress).verifyProof(proof);

        return true;
    }
}
