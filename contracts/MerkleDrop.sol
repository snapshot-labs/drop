// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IDrop.sol";
import "./MerkleProof.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MerkleDrop is IDrop, Ownable {
    using SafeERC20 for IERC20;
    using BitMaps for BitMaps.BitMap;

    address public override token;
    bytes32 public override merkleRoot;
    bool public initialized;
    uint256 public expireTimestamp;

    BitMaps.BitMap private claimed;

    function init(
        address _owner,
        address _token,
        bytes32 _merkleRoot,
        uint256 _expireTimestamp
    ) external {
        require(!initialized, "MerkleDrop: Already initialized.");
        initialized = true;
        token = _token;
        merkleRoot = _merkleRoot;
        expireTimestamp = _expireTimestamp;
        _transferOwnership(_owner);
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param index The index into the merkle tree.
     */
    function isClaimed(uint256 index) public view returns (bool) {
        return claimed.get(index);
    }

    /**
     * @dev Implementation to claim token.
     * @param _amount Amount of tokens allotcated based on voting power.
     * @param _merkleProof Proof of merkle root generated from recipient address and value
     *
     * This implementation is the way to claim tokens, that were allocated to accounts. This means
     * that the recipient and the value to claim data is converted to merkle root and given to this contract
     * at the time of deployment.
     *
     * To claim caller should pass amount and proof, after verifying the
     * proof, recipient and its value were right, we transfer the tokens and mark it as claimed.
     */
    function claim(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        override
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        (bool valid, uint256 index) = MerkleProof.verify(
            _merkleProof,
            merkleRoot,
            leaf
        );
        require(valid, "MerkleDrop: Invalid proof.");
        require(!isClaimed(index), "MerkleDrop: Tokens already claimed.");
        claimed.set(index);
        IERC20(token).safeTransfer(msg.sender, _amount);
        emit Claimed(msg.sender, _amount);
    }

    /**
     * @dev Implementation to sweep out remaining tokens back.
     * @param _token Address of the drop token
     *
     * Owner can claim remaining tokens from contract after the expiry time.
     */
    function sweepOut(address _token) external onlyOwner {
        require(
            block.timestamp >= expireTimestamp || _token != token,
            "MerkleDrop: Drop not ended."
        );
        IERC20 tokenContract = IERC20(_token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.safeTransfer(msg.sender, balance);
    }
}
