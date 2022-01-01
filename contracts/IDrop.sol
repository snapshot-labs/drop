// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDrop {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external;
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(address account, uint256 amount);
}