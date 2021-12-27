// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MerkleDrop {
    bytes32 private merkleRoot;
    ERC20 public dropToken;
    uint256 private initialBalance;
    uint256 private remainingValue;
    uint256 private spentTokens;
    uint256 private expiresInSeconds;

    uint256 public index;
    bool public isEnabled;
    address private owner;

    mapping(address => bool) public claimed;

    event Claimed(address recipient, uint256 value);

    function init(
        ERC20 _dropToken,
        uint256 _initialBalance,
        bytes32 _merkleRoot,
        uint256 _index,
        uint256 _timeDurationInSeconds,
        address _owner
    ) external {
        owner = _owner;
        dropToken = _dropToken;
        initialBalance = _initialBalance;
        remainingValue = _initialBalance;
        merkleRoot = _merkleRoot;
        index = _index;
        isEnabled = true;
        expiresInSeconds = block.timestamp + _timeDurationInSeconds;
    }

    function claim(
        address account,
        uint256 value,
        bytes32[] memory proof
    ) public {
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(account, value))
            ),
            "Invalid merkle proof"
        );
        require(!claimed[account], "Already claimed.");
        require(isEnabled, "Contract disabled.");
        require(block.timestamp <= expiresInSeconds, "Times up!");
        console.log(dropToken.balanceOf(address(this)));
        require(
            dropToken.balanceOf(address(this)) >= value,
            "No tokens to drop."
        );
        claimed[account] = true;
        remainingValue -= value;
        spentTokens += value;
        dropToken.transfer(account, value);
        emit Claimed(account, value);
    }

    function claimTokensBack(address _msgSender) external {
        require(_msgSender == owner, "Not a owner");
        require(block.timestamp >= expiresInSeconds, "Drop not ended yet!");
        dropToken.transfer(owner, remainingValue);
    }

    function disable() external {
        isEnabled = false;
    }
}
