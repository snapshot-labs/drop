// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDrop {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Claim the given amount of the token. Reverts if the inputs are invalid.
    function claim(uint256 amount, bytes32[] calldata merkleProof) external;
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(address recipient, uint256 amount);
}