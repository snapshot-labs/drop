// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./TokenInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleDrop {
    bytes32 private merkleRoot;
    TokenInterface public dropToken;
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
        TokenInterface _dropToken,
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
        require(_verify(_leaf(account, value), proof), "Invalid merkle proof");
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
        address payable addressOfOwner = payable(owner);
        addressOfOwner.transfer(remainingValue);
        console.log(address(this).balance);
    }

    function _leaf(address account, uint256 value)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, value));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function disable() external {
        isEnabled = false;
    }
}
