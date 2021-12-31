// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./IDrop.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleDrop is IDrop, Ownable {
    using SafeERC20 for IERC20;

    address public override token;
    bytes32 public override merkleRoot;
    bool public initialized;
    uint256 public expireTimestamp;

    mapping(address => bool) public claimed;

    function init(
        address owner_,
        address token_,
        bytes32 merkleRoot_,
        uint256 expireTimestamp_
    ) external {
        require(!initialized, "Drop already Initialized");
        initialized = true;
        token = token_;
        merkleRoot = merkleRoot_;
        expireTimestamp = expireTimestamp_;
        _transferOwnership(owner_);
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!claimed[account], "Drop already claimed.");
        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );
        claimed[account] = true;
        IERC20(token).safeTransfer(account, amount);
        emit Claimed(account, amount);
    }

    function sweepOut(address token_) external onlyOwner {
        require(
            block.timestamp >= expireTimestamp || token_ != token,
            "Drop not ended"
        );
        IERC20 tokenContract = IERC20(token_);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.safeTransfer(msg.sender, balance);
    }
}
